import Foundation

enum SRTConverter {
    static func convertToASS(subtitleURL: URL, assURL: URL, appearance: SubtitleAppearance) throws {
        switch subtitleURL.pathExtension.lowercased() {
        case "ass":
            try restyleASS(assURL: subtitleURL, outputURL: assURL, appearance: appearance)
        default:
            try convertSRTToASS(srtURL: subtitleURL, assURL: assURL, appearance: appearance)
        }
    }

    static func convertToASS(srtURL: URL, assURL: URL, appearance: SubtitleAppearance) throws {
        try convertSRTToASS(srtURL: srtURL, assURL: assURL, appearance: appearance)
    }

    static func makeSampleASS(assURL: URL, appearance: SubtitleAppearance, text: String) throws {
        let escapedText = sanitizeDialogueText(text)
            .replacingOccurrences(of: "\n", with: "\\N")
        let eventText = SubtitleStyleBuilder.dialoguePrefix(from: appearance) + escapedText
        let ass = assHeader(appearance: appearance) + "Dialogue: 0,0:00:00.00,0:00:10.00,Default,,0,0,0,,\(eventText)\n"
        try ass.write(to: assURL, atomically: true, encoding: .utf8)
    }

    private static func convertSRTToASS(srtURL: URL, assURL: URL, appearance: SubtitleAppearance) throws {
        let content = try loadText(from: srtURL)
        let style = SubtitleStyleBuilder.makeASSStyle(from: appearance)

        var ass = """
        [Script Info]
        ScriptType: v4.00+
        Collisions: Normal
        PlayDepth: 0
        PlayResX: 1920
        PlayResY: 1080
        Timer: 100.0000

        [V4+ Styles]
        Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
        \(style)

        [Events]
        Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text

        """

        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = normalized.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            guard lines.count >= 2 else { continue }
            let timeLineIndex = lines.firstIndex(where: { $0.contains("-->") }) ?? 1
            guard timeLineIndex < lines.count else { continue }
            let parts = lines[timeLineIndex].components(separatedBy: " --> ")
            guard parts.count == 2 else { continue }

            let start = convertSRTTime(parts[0])
            let end = convertSRTTime(parts[1])
            let textLines = lines[(timeLineIndex + 1)...].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            guard !textLines.isEmpty else { continue }
            let text = SubtitleStyleBuilder.dialoguePrefix(from: appearance) + sanitizeDialogueText(textLines.joined(separator: "\\N"))
            ass += "Dialogue: 0,\(start),\(end),Default,,0,0,0,,\(text)\n"
        }

        try ass.write(to: assURL, atomically: true, encoding: .utf8)
    }

    private static func restyleASS(assURL: URL, outputURL: URL, appearance: SubtitleAppearance) throws {
        let content = try loadText(from: assURL)
        var output = assHeader(appearance: appearance)
        let prefix = SubtitleStyleBuilder.dialoguePrefix(from: appearance)

        for rawLine in content.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            guard line.hasPrefix("Dialogue:") else { continue }

            let fields = splitASSDialogue(line)
            guard fields.count >= 10 else { continue }
            let start = fields[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let end = fields[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let text = prefix + sanitizeDialogueText(fields[9...].joined(separator: ","), removingASSOverrides: true)
            output += "Dialogue: 0,\(start),\(end),Default,,0,0,0,,\(text)\n"
        }

        try output.write(to: outputURL, atomically: true, encoding: .utf8)
    }

    private static func assHeader(appearance: SubtitleAppearance) -> String {
        let style = SubtitleStyleBuilder.makeASSStyle(from: appearance)
        return """
        [Script Info]
        ScriptType: v4.00+
        Collisions: Normal
        PlayDepth: 0
        PlayResX: 1920
        PlayResY: 1080
        Timer: 100.0000

        [V4+ Styles]
        Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
        \(style)

        [Events]
        Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text

        """
    }

    private static func splitASSDialogue(_ line: String) -> [String] {
        let value = line.replacingOccurrences(of: "Dialogue:", with: "", options: [.anchored])
        return value.split(separator: ",", maxSplits: 9, omittingEmptySubsequences: false).map(String.init)
    }

    private static func sanitizeDialogueText(_ value: String, removingASSOverrides: Bool = false) -> String {
        var text = value
            .replacingOccurrences(of: "\n", with: "\\N")
            .replacingOccurrences(of: "\r", with: "")
        if removingASSOverrides {
            text = stripASSOverrideTags(from: text)
        }
        return text
    }

    private static func stripASSOverrideTags(from value: String) -> String {
        var result = ""
        var isInsideTag = false

        for character in value {
            if character == "{" {
                isInsideTag = true
                continue
            }
            if character == "}" {
                isInsideTag = false
                continue
            }
            if !isInsideTag {
                result.append(character)
            }
        }

        return result
    }

    private static func loadText(from url: URL) throws -> String {
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            return utf8
        }
        return try String(contentsOf: url, encoding: .unicode)
    }

    private static func convertSRTTime(_ value: String) -> String {
        value.replacingOccurrences(of: ",", with: ".")
            .split(separator: ".")
            .enumerated()
            .map { index, part in
                if index == 1 {
                    return String(part.prefix(2))
                }
                return String(part)
            }
            .joined(separator: ".")
    }
}
