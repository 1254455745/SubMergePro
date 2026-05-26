import AppKit
import AVFoundation
import Foundation
import UniformTypeIdentifiers

@MainActor
final class SubMergeViewModel: ObservableObject {
    @Published var items: [VideoItem] = []
    @Published var renderOptions = VideoRenderOptions()
    @Published var subtitleAppearance = SubtitleAppearance()
    @Published var isRenderingAll = false
    @Published var aboutPresented = false
    @Published var previewPresented = false
    @Published var alertMessage: String?
    @Published var previewText = "这里是字幕预览效果\n第二行可以帮助你观察位置和样式"
    @Published var previewItem: VideoItem?
    @Published var previewTime: Double = 0
    @Published var previewDuration: Double = 0
    @Published var previewCues: [SubtitleCue] = []
    @Published var previewImage: NSImage?
    @Published var previewIsRendering = false
    @Published var previewRenderError: String?

    let formatOptions = ["MP4", "MOV", "AVI", "MKV"]
    let resolutionOptions = ["原始", "3840x2160", "1920x1080", "1280x720"]
    let bitrateOptions = ["原始", "10M", "5M", "3M", "1M"]
    let frameRateOptions = ["原始", "60", "50", "30", "25", "24"]
    let codecOptions = ["H.264", "H.265"]
    let fontOptions = ["PingFang SC", "Hiragino Sans GB", "Helvetica Neue", "Arial Unicode MS"]
    let alignmentOptions = [
        "顶部居左", "顶部居中", "顶部居右",
        "中间居左", "中间居中", "中间居右",
        "底部居左", "底部居中", "底部居右"
    ]

    private let ffmpegService = FFmpegService()
    private let supportedVideoExtensions = ["mp4", "mov", "avi", "mkv"]
    private let defaultStylePreviewText = "这里是字幕样式预览\n第二行可以帮助你观察描边、阴影和位置"
    private var previewDebounceTask: Task<Void, Never>?
    private var previewRequestID = UUID()

    func addVideos() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = supportedVideoExtensions.compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK else { return }
        Task { await importVideos(from: panel.urls) }
    }

    func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let folderURL = panel.url else { return }
        let urls = (try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil))?
            .filter { supportedVideoExtensions.contains($0.pathExtension.lowercased()) } ?? []
        Task { await importVideos(from: urls) }
    }

    func clearList() {
        Task {
            await ffmpegService.cancelCurrentTask()
        }
        items.removeAll()
        isRenderingAll = false
    }

    func chooseSubtitle(for itemID: UUID) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ["srt", "ass"].compactMap { UTType(filenameExtension: $0) }
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        updateItem(itemID) {
            $0.subtitleURL = url
            $0.status = .pending
            $0.lastError = nil
        }
    }

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let folderURL = panel.url else { return }
        renderOptions.outputDirectory = folderURL.path
    }

    func removeItem(_ itemID: UUID) {
        items.removeAll { $0.id == itemID }
        reindex()
    }

    func openItemOutput(_ itemID: UUID) {
        guard let item = items.first(where: { $0.id == itemID }) else { return }
        if let outputURL = item.outputURL, FileManager.default.fileExists(atPath: outputURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([outputURL])
        } else {
            alertMessage = "还没有找到导出文件。请先完成合成。"
        }
    }

    func startRender(for itemID: UUID) {
        let appearanceSnapshot = subtitleAppearance
        let optionsSnapshot = renderOptions
        Task { await renderSingle(itemID: itemID, appearance: appearanceSnapshot, options: optionsSnapshot) }
    }

    func startRenderAll() {
        guard !items.isEmpty else {
            alertMessage = "请先添加视频。"
            return
        }

        isRenderingAll = true
        let appearanceSnapshot = subtitleAppearance
        let optionsSnapshot = renderOptions
        Task {
            for item in items where item.status != .success {
                await renderSingle(itemID: item.id, appearance: appearanceSnapshot, options: optionsSnapshot)
            }
            isRenderingAll = false
        }
    }

    func showPreview() {
        prepareStylePreview(useProjectVideo: false)
        previewPresented = true
        renderCurrentPreviewFrame()
    }

    func showStyleEditor() {
        prepareStylePreview(useProjectVideo: false)
        renderCurrentPreviewFrame()
    }

    func showPreview(for itemID: UUID) {
        guard let item = items.first(where: { $0.id == itemID }) else { return }
        prepareVideoPreview(for: item)
        previewPresented = true
        renderCurrentPreviewFrame()
    }

    func scheduleLivePreviewRender(delayNanoseconds: UInt64 = 180_000_000) {
        previewDebounceTask?.cancel()
        previewDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.renderCurrentPreviewFrame()
            }
        }
    }

    func subtitleText(at time: Double) -> String {
        if let cue = previewCues.first(where: { time >= $0.start && time <= $0.end }) {
            return cue.text
        }
        return ""
    }

    func renderCurrentPreviewFrame() {
        guard let item = previewItem, let subtitleURL = item.subtitleURL else {
            renderStylePreviewFrame()
            return
        }

        let requestedTime = previewTime
        let requestID = UUID()
        previewRequestID = requestID
        previewIsRendering = true
        previewRenderError = nil

        Task {
            do {
                let data = try await ffmpegService.renderPreviewFrame(
                    videoURL: item.videoURL,
                    subtitleURL: subtitleURL,
                    appearance: subtitleAppearance,
                    options: renderOptions,
                    seconds: requestedTime
                )

                if self.previewRequestID == requestID, abs(self.previewTime - requestedTime) < 0.35 {
                    self.previewImage = NSImage(data: data)
                    self.previewIsRendering = false
                }
            } catch {
                if self.previewRequestID == requestID, abs(self.previewTime - requestedTime) < 0.35 {
                    self.previewRenderError = error.localizedDescription
                    self.previewIsRendering = false
                }
            }
        }
    }

    func renderStylePreviewFrame() {
        guard previewItem == nil else {
            renderCurrentPreviewFrame()
            return
        }

        let requestedText = previewText
        let requestID = UUID()
        previewRequestID = requestID
        previewIsRendering = true
        previewRenderError = nil

        Task {
            do {
                let data = try await ffmpegService.renderStylePreviewFrame(
                    appearance: subtitleAppearance,
                    options: renderOptions,
                    text: requestedText
                )
                if self.previewRequestID == requestID {
                    self.previewImage = NSImage(data: data)
                    self.previewIsRendering = false
                }
            } catch {
                if self.previewRequestID == requestID {
                    self.previewRenderError = error.localizedDescription
                    self.previewImage = nil
                    self.previewIsRendering = false
                }
            }
        }
    }

    func handleDroppedItems(_ providers: [NSItemProvider]) -> Bool {
        var handled = false

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
                    guard let self else { return }
                    guard let data = item as? Data,
                          let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? else {
                        return
                    }

                    Task { @MainActor in
                        if url.hasDirectoryPath {
                            let urls = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil))?
                                .filter { self.supportedVideoExtensions.contains($0.pathExtension.lowercased()) } ?? []
                            await self.importVideos(from: urls)
                        } else if self.supportedVideoExtensions.contains(url.pathExtension.lowercased()) {
                            await self.importVideos(from: [url])
                        }
                    }
                }
                handled = true
            }
        }

        return handled
    }

    private func importVideos(from urls: [URL]) async {
        for url in urls {
            if items.contains(where: { $0.videoURL == url }) { continue }

            let subtitleURL = autoMatchSubtitle(for: url)
            var item = VideoItem(index: items.count + 1, videoURL: url, subtitleURL: subtitleURL)
            let metadata = await VideoMetadataService.loadMetadata(for: url)
            item.durationText = metadata.durationText
            item.durationSeconds = metadata.durationSeconds
            item.container = metadata.container
            item.fileSizeText = metadata.fileSizeText
            item.resolutionText = metadata.resolutionText
            item.frameRateText = metadata.frameRateText
            item.bitrateText = metadata.bitrateText
            items.append(item)
        }

        if let first = items.first, renderOptions.outputDirectory == "\(NSHomeDirectory())/Movies/SubMergePro" {
            renderOptions.outputDirectory = first.videoURL.deletingLastPathComponent().path
        }
    }

    private func autoMatchSubtitle(for videoURL: URL) -> URL? {
        let srt = videoURL.deletingPathExtension().appendingPathExtension("srt")
        let ass = videoURL.deletingPathExtension().appendingPathExtension("ass")
        if FileManager.default.fileExists(atPath: srt.path) { return srt }
        if FileManager.default.fileExists(atPath: ass.path) { return ass }
        return nil
    }

    private func prepareStylePreview(useProjectVideo: Bool) {
        previewImage = nil
        previewRenderError = nil
        previewCues = []
        previewDuration = 0
        previewTime = 0

        if useProjectVideo, let item = items.first(where: { $0.subtitleURL != nil }) {
            prepareVideoPreview(for: item)
            return
        }

        previewItem = nil
        previewText = defaultStylePreviewText
    }

    private func prepareVideoPreview(for item: VideoItem) {
        previewItem = item
        previewImage = nil
        previewRenderError = nil
        previewCues = item.subtitleURL.map { SubtitlePreviewService.loadCues(from: $0) } ?? []
        previewDuration = max(item.durationSeconds, 1)
        previewTime = previewCues.first.map { ($0.start + $0.end) / 2 } ?? min(max(item.durationSeconds * 0.18, 0), previewDuration)
        previewText = previewCues.first?.text ?? defaultStylePreviewText
    }

    private func renderSingle(
        itemID: UUID,
        appearance: SubtitleAppearance? = nil,
        options: VideoRenderOptions? = nil
    ) async {
        guard let item = items.first(where: { $0.id == itemID }) else { return }
        guard let subtitleURL = item.subtitleURL else {
            updateItem(itemID) {
                $0.status = .failed
                $0.lastError = "没有字幕文件"
            }
            return
        }

        let effectiveAppearance = appearance ?? subtitleAppearance
        let effectiveOptions = options ?? renderOptions
        let outputDirectoryURL = URL(fileURLWithPath: effectiveOptions.outputDirectory, isDirectory: true)
        let baseName = "Sub_" + item.videoURL.deletingPathExtension().lastPathComponent
        let outputURL = outputDirectoryURL
            .appendingPathComponent(baseName)
            .appendingPathExtension(effectiveOptions.container.lowercased())

        updateItem(itemID) {
            $0.status = .processing
            $0.progress = 0.02
            $0.outputURL = outputURL
            $0.lastError = nil
        }

        let task = RenderTask(
            itemID: itemID,
            videoURL: item.videoURL,
            subtitleURL: subtitleURL,
            outputURL: outputURL,
            expectedDurationSeconds: item.durationSeconds,
            appearance: effectiveAppearance,
            options: effectiveOptions
        )

        do {
            try await ffmpegService.render(task: task) { [weak self] progress in
                self?.updateItem(itemID) {
                    $0.progress = progress
                }
            }
            updateItem(itemID) {
                $0.progress = 1
                $0.status = .success
                $0.lastError = nil
            }
        } catch {
            updateItem(itemID) {
                $0.progress = 0
                $0.status = .failed
                $0.lastError = error.localizedDescription
            }
        }
    }

    private func updateItem(_ id: UUID, _ mutate: (inout VideoItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        mutate(&items[index])
    }

    private func reindex() {
        for index in items.indices {
            items[index].index = index + 1
        }
    }
}
