import Foundation

struct RenderTask {
    let itemID: UUID
    let videoURL: URL
    let subtitleURL: URL
    let outputURL: URL
    let expectedDurationSeconds: Double
    let appearance: SubtitleAppearance
    let options: VideoRenderOptions
}

actor FFmpegService {
    private var process: Process?
    private static let processLock = NSLock()
    nonisolated(unsafe) private static var activeRenderProcess: Process?

    private final class CaptureBox: @unchecked Sendable {
        var lines: [String] = []
    }

    func cancelCurrentTask() {
        process?.terminate()
        process = nil
        Self.terminateActiveRenderProcess()
    }

    nonisolated static func terminateActiveRenderProcess() {
        processLock.lock()
        let process = activeRenderProcess
        activeRenderProcess = nil
        processLock.unlock()

        if process?.isRunning == true {
            process?.terminate()
        }
    }

    private nonisolated static func setActiveRenderProcess(_ process: Process?) {
        processLock.lock()
        activeRenderProcess = process
        processLock.unlock()
    }

    func renderPreviewFrame(
        videoURL: URL,
        subtitleURL: URL,
        appearance: SubtitleAppearance,
        options: VideoRenderOptions,
        seconds: Double
    ) async throws -> Data {
        let ffmpegURL = try resolveFFmpegURL()
        let assURL = try makeTemporaryASS(from: subtitleURL, appearance: appearance)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: assURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        let requestedTime = max(seconds, 0)
        let filters = makeVideoFilters(
            subtitleURL: assURL,
            options: options,
            timelineOffset: requestedTime
        )

        return try await runImageRender(
            ffmpegURL: ffmpegURL,
            arguments: [
                "-y",
                "-ss", String(format: "%.3f", requestedTime),
                "-i", videoURL.path,
                "-vf", filters,
                "-frames:v", "1",
                outputURL.path
            ],
            outputURL: outputURL,
            errorTitle: "FFmpeg 预览帧生成失败"
        )
    }

    func renderStylePreviewFrame(
        appearance: SubtitleAppearance,
        options: VideoRenderOptions,
        text: String
    ) async throws -> Data {
        let ffmpegURL = try resolveFFmpegURL()
        let assURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("ass")
        let backgroundURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("ppm")
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: assURL)
            try? FileManager.default.removeItem(at: backgroundURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        try SRTConverter.makeSampleASS(assURL: assURL, appearance: appearance, text: text)
        try writeGradientPreviewBackground(to: backgroundURL, width: 1920, height: 1080)

        let filters = makeVideoFilters(
            subtitleURL: assURL,
            options: options,
            timelineOffset: 2
        )

        return try await runImageRender(
            ffmpegURL: ffmpegURL,
            arguments: [
                "-y",
                "-i", backgroundURL.path,
                "-vf", filters,
                "-frames:v", "1",
                outputURL.path
            ],
            outputURL: outputURL,
            errorTitle: "FFmpeg 样式预览生成失败"
        )
    }

    func render(
        task: RenderTask,
        onProgress: @escaping @MainActor (Double) -> Void
    ) async throws {
        let ffmpegURL = try resolveFFmpegURL()
        let preparedSubtitleURL = try prepareSubtitleFile(for: task)
        defer { try? FileManager.default.removeItem(at: preparedSubtitleURL) }

        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = makeArguments(task: task, subtitleURL: preparedSubtitleURL)
        process.environment = mergedEnvironment()

        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = Pipe()
        self.process = process
        Self.setActiveRenderProcess(process)
        defer {
            self.process = nil
            Self.setActiveRenderProcess(nil)
        }

        try ensureOutputDirectoryExists(task.outputURL.deletingLastPathComponent())
        try? FileManager.default.removeItem(at: task.outputURL)
        do {
            try process.run()
        } catch {
            throw NSError(domain: "SubMergePro", code: 405, userInfo: [
                NSLocalizedDescriptionKey: "FFmpeg 启动失败：\(ffmpegURL.path)\n\(error.localizedDescription)"
            ])
        }

        let handle = stderr.fileHandleForReading
        let captureBox = CaptureBox()
        let progressTask = Task {
            for try await line in handle.bytes.lines {
                captureBox.lines.append(line)
                if captureBox.lines.count > 14 {
                    captureBox.lines.removeFirst(captureBox.lines.count - 14)
                }
                if let progress = ProgressParser.parse(line: line, totalDuration: task.expectedDurationSeconds) {
                    await onProgress(progress)
                }
            }
        }

        process.waitUntilExit()
        progressTask.cancel()

        guard process.terminationStatus == 0 else {
            let detail = captureBox.lines
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .suffix(3)
                .joined(separator: "\n")
            throw NSError(domain: "SubMergePro", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: detail.isEmpty
                    ? "FFmpeg 导出失败，请确认视频、字幕和编码参数是否正确。"
                    : "FFmpeg 导出失败：\n\(detail)"
            ])
        }

        await onProgress(1)
    }

    private func prepareSubtitleFile(for task: RenderTask) throws -> URL {
        try makeTemporaryASS(from: task.subtitleURL, appearance: task.appearance)
    }

    private func makeTemporaryASS(from subtitleURL: URL, appearance: SubtitleAppearance) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("ass")
        try SRTConverter.convertToASS(subtitleURL: subtitleURL, assURL: tempURL, appearance: appearance)
        return tempURL
    }

    private func resolveFFmpegURL() throws -> URL {
        let bundled = Bundle.main.url(forResource: "ffmpeg", withExtension: nil)
        if let bundled { return bundled }

        let envCandidates = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map { String($0) + "/ffmpeg" }

        let candidates = envCandidates + [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]

        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        throw NSError(domain: "SubMergePro", code: 404, userInfo: [
            NSLocalizedDescriptionKey: "没有找到 ffmpeg。已检查路径：\n\(candidates.joined(separator: "\n"))"
        ])
    }

    private func mergedEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let extraPaths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
        let currentPath = env["PATH"] ?? ""
        let merged = (currentPath.split(separator: ":").map(String.init) + extraPaths)
        var unique: [String] = []
        for path in merged where !unique.contains(path) {
            unique.append(path)
        }
        env["PATH"] = unique.joined(separator: ":")
        return env
    }

    private func makeArguments(task: RenderTask, subtitleURL: URL) -> [String] {
        var arguments: [String] = [
            "-y",
            "-i", task.videoURL.path
        ]

        arguments += ["-vf", makeVideoFilters(subtitleURL: subtitleURL, options: task.options)]

        if task.options.bitrate != "原始" {
            arguments += ["-b:v", task.options.bitrate]
        }

        if task.options.frameRate != "原始" {
            arguments += ["-r", task.options.frameRate]
        }

        let codec = task.options.codec == "H.265" ? "libx265" : "libx264"
        arguments += ["-c:v", codec, "-c:a", "copy", task.outputURL.path]
        return arguments
    }

    private func ensureOutputDirectoryExists(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func makeVideoFilters(
        subtitleURL: URL,
        options: VideoRenderOptions,
        timelineOffset: Double? = nil
    ) -> String {
        var filters: [String] = []

        if let timelineOffset {
            filters.append("setpts=PTS+\(String(format: "%.3f", timelineOffset))/TB")
        }

        filters.append("ass=\(escapeFilterPath(subtitleURL.path))")

        if options.resolution != "原始" {
            let parts = options.resolution.split(separator: "x")
            if parts.count == 2 {
                filters.append("scale=\(parts[0]):\(parts[1])")
            }
        }

        return filters.joined(separator: ",")
    }

    private func runImageRender(
        ffmpegURL: URL,
        arguments: [String],
        outputURL: URL,
        errorTitle: String
    ) async throws -> Data {
        let process = Process()
        process.executableURL = ffmpegURL
        process.environment = mergedEnvironment()
        process.arguments = arguments

        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = Pipe()

        do {
            try process.run()
        } catch {
            throw NSError(domain: "SubMergePro", code: 406, userInfo: [
                NSLocalizedDescriptionKey: "FFmpeg 预览启动失败：\(ffmpegURL.path)\n\(error.localizedDescription)"
            ])
        }

        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0, FileManager.default.fileExists(atPath: outputURL.path) else {
            let detail = String(data: errorData, encoding: .utf8) ?? ""
            throw NSError(domain: "SubMergePro", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: detail.isEmpty ? "\(errorTitle)。" : "\(errorTitle)：\n\(detail)"
            ])
        }

        return try Data(contentsOf: outputURL)
    }

    private func writeGradientPreviewBackground(to url: URL, width: Int, height: Int) throws {
        var data = Data()
        data.append("P6\n\(width) \(height)\n255\n".data(using: .ascii) ?? Data())

        var pixels: [UInt8] = []
        pixels.reserveCapacity(width * height * 3)

        for y in 0..<height {
            let fy = Double(y) / Double(max(height - 1, 1))
            for x in 0..<width {
                let fx = Double(x) / Double(max(width - 1, 1))
                let top = mixColor((247, 250, 255), (154, 204, 241), fx)
                let bottom = mixColor((255, 210, 172), (184, 228, 212), fx)
                let base = mixColor(top, bottom, fy)
                let wave = 1.0 + 0.035 * sin((fx * 3.2 + fy * 2.4) * Double.pi)
                let vignette = 0.94 + 0.06 * (1 - min(1, hypot(fx - 0.5, fy - 0.5)))
                let lift = wave * vignette
                pixels.append(UInt8(max(0, min(255, Double(base.0) * lift))))
                pixels.append(UInt8(max(0, min(255, Double(base.1) * lift))))
                pixels.append(UInt8(max(0, min(255, Double(base.2) * lift))))
            }
        }

        data.append(contentsOf: pixels)
        try data.write(to: url)
    }

    private func mixColor(
        _ start: (Int, Int, Int),
        _ end: (Int, Int, Int),
        _ amount: Double
    ) -> (Int, Int, Int) {
        let clamped = max(0, min(1, amount))
        return (
            Int(Double(start.0) + (Double(end.0) - Double(start.0)) * clamped),
            Int(Double(start.1) + (Double(end.1) - Double(start.1)) * clamped),
            Int(Double(start.2) + (Double(end.2) - Double(start.2)) * clamped)
        )
    }

    private func escapeFilterPath(_ path: String) -> String {
        path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ":", with: "\\:")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "[", with: "\\[")
            .replacingOccurrences(of: "]", with: "\\]")
    }
}

enum ProgressParser {
    static func parse(line: String, totalDuration: Double) -> Double? {
        guard let range = line.range(of: "time=") else { return nil }
        let tail = line[range.upperBound...]
        let value = tail.split(separator: " ").first.map(String.init) ?? ""
        let seconds = parseTimestamp(value)
        guard seconds > 0, totalDuration > 0 else { return nil }
        return min(seconds / totalDuration, 0.98)
    }

    private static func parseTimestamp(_ value: String) -> Double {
        let parts = value.split(separator: ":").map(String.init)
        guard parts.count == 3 else { return 0 }
        let hour = Double(parts[0]) ?? 0
        let minute = Double(parts[1]) ?? 0
        let second = Double(parts[2]) ?? 0
        return hour * 3600 + minute * 60 + second
    }
}
