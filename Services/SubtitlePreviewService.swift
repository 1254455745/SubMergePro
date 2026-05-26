import Foundation

struct SubtitleCue: Identifiable, Hashable {
    let id = UUID()
    let start: TimeInterval
    let end: TimeInterval
    let text: String
}

enum SubtitlePreviewService {
    static func loadCues(from url: URL) -> [SubtitleCue] {
        switch url.pathExtension.lowercased() {
        case "srt":
            return loadSRTCues(from: url)
        case "ass":
            return loadASSCues(from: url)
        default:
            return []
        }
    }

    private static func loadSRTCues(from url: URL) -> [SubtitleCue] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = normalized.components(separatedBy: "\n\n")

        return blocks.compactMap { block in
            let lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            guard let timeLine = lines.first(where: { $0.contains("-->") }) else { return nil }
            let parts = timeLine.components(separatedBy: " --> ")
            guard parts.count == 2 else { return nil }
            let start = parseSRTTime(parts[0])
            let end = parseSRTTime(parts[1])
            let textLines = lines.drop { !$0.contains("-->") }.dropFirst().filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            guard !textLines.isEmpty else { return nil }
            return SubtitleCue(start: start, end: end, text: textLines.joined(separator: "\n"))
        }
    }

    private static func loadASSCues(from url: URL) -> [SubtitleCue] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return content
            .split(separator: "\n")
            .compactMap { line in
                let value = String(line)
                guard value.hasPrefix("Dialogue:") else { return nil }
                let parts = value.components(separatedBy: ",")
                guard parts.count >= 10 else { return nil }
                let start = parseASSTime(parts[1])
                let end = parseASSTime(parts[2])
                let text = parts[9...].joined(separator: ",").replacingOccurrences(of: "\\N", with: "\n")
                return SubtitleCue(start: start, end: end, text: text)
            }
    }

    private static func parseSRTTime(_ value: String) -> TimeInterval {
        let cleaned = value.replacingOccurrences(of: ",", with: ".")
        return parseClockTime(cleaned)
    }

    private static func parseASSTime(_ value: String) -> TimeInterval {
        parseClockTime(value)
    }

    private static func parseClockTime(_ value: String) -> TimeInterval {
        let parts = value.split(separator: ":")
        guard parts.count == 3 else { return 0 }
        let hour = Double(parts[0]) ?? 0
        let minute = Double(parts[1]) ?? 0
        let second = Double(parts[2]) ?? 0
        return hour * 3600 + minute * 60 + second
    }
}
