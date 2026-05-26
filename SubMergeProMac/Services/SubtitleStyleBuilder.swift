import Foundation

enum SubtitleStyleBuilder {
    static func makeASSStyle(from appearance: SubtitleAppearance) -> String {
        let primary = assColor(fromHex: appearance.textColorHex, opacity: appearance.textOpacity)
        let outline = assColor(fromHex: appearance.outlineColorHex, opacity: appearance.outlineOpacity)
        let back = appearance.backgroundOpacity > 0
            ? assColor(fromHex: appearance.backgroundColorHex, opacity: appearance.backgroundOpacity)
            : assColor(fromHex: appearance.shadowColorHex, opacity: appearance.shadowOpacity)
        let alignment = alignmentCode(from: appearance.alignment)
        let borderStyle = appearance.backgroundOpacity > 0 ? "3" : "1"

        return [
            "Style: Default",
            appearance.fontName,
            "\(appearance.fontSize)",
            primary,
            primary,
            outline,
            back,
            appearance.isBold ? "-1" : "0",
            appearance.isItalic ? "-1" : "0",
            appearance.isUnderline ? "-1" : "0",
            "0",
            "\(appearance.scaleX)",
            "\(appearance.scaleY)",
            "\(appearance.letterSpacing)",
            "\(appearance.rotation)",
            borderStyle,
            "\(appearance.outlineWidth)",
            "\(appearance.shadowDistance)",
            "\(alignment)",
            "\(appearance.marginLeft)",
            "\(appearance.marginRight)",
            "\(appearance.marginVertical)",
            "1"
        ].joined(separator: ",")
    }

    static func dialoguePrefix(from appearance: SubtitleAppearance) -> String {
        guard appearance.shadowBlur > 0 else { return "" }
        return "{\\blur\(appearance.shadowBlur)}"
    }

    static func assColor(fromHex hex: String, opacity: Int) -> String {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6 else { return "&H00FFFFFF" }
        let r = cleaned.prefix(2)
        let g = cleaned.dropFirst(2).prefix(2)
        let b = cleaned.dropFirst(4).prefix(2)
        let alpha = alphaHex(fromPercentage: opacity)
        return "&H\(alpha)\(b)\(g)\(r)"
    }

    static func alphaHex(fromPercentage percentage: Int) -> String {
        let clamped = max(0, min(100, percentage))
        let alpha = 255 - Int((Double(clamped) / 100) * 255)
        return String(format: "%02X", alpha)
    }

    static func alignmentCode(from label: String) -> Int {
        switch label {
        case "顶部居左": return 7
        case "顶部居中": return 8
        case "顶部居右": return 9
        case "中间居左": return 4
        case "中间居中": return 5
        case "中间居右": return 6
        case "底部居左": return 1
        case "底部居右": return 3
        default: return 2
        }
    }
}
