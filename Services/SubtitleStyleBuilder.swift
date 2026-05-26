import Foundation

enum SubtitleStyleBuilder {
    static func makeASSStyle(from appearance: SubtitleAppearance) -> String {
        let primary = assColor(fromHex: appearance.textColorHex, opacity: appearance.textOpacity)
        let outline = appearance.outlineEnabled
            ? assColor(fromHex: appearance.outlineColorHex, opacity: appearance.outlineOpacity)
            : "&HFF000000"
        let back = appearance.shadowEnabled
            ? assColor(fromHex: appearance.shadowColorHex, opacity: appearance.shadowOpacity)
            : "&HFF000000"
        let alignment = alignmentCode(from: appearance.alignment)

        let textStyle = makeStyleLine(
            name: "Default",
            appearance: appearance,
            primary: primary,
            outline: outline,
            back: back,
            borderStyle: "1",
            outlineWidth: appearance.outlineEnabled ? appearance.outlineWidth : 0,
            shadowDistance: appearance.shadowEnabled ? scaledShadowDistance(from: appearance.shadowDistance) : 0,
            alignment: alignment
        )

        guard appearance.backgroundEnabled else {
            return textStyle
        }

        let background = assColor(fromHex: appearance.backgroundColorHex, opacity: appearance.backgroundOpacity)
        let transparent = "&HFF000000"
        let backgroundStyle = makeStyleLine(
            name: "Background",
            appearance: appearance,
            primary: transparent,
            outline: background,
            back: background,
            borderStyle: "3",
            outlineWidth: max(max(appearance.backgroundPaddingX, appearance.backgroundPaddingY), 1),
            shadowDistance: 0,
            alignment: alignment
        )

        return backgroundStyle + "\n" + textStyle
    }

    private static func makeStyleLine(
        name: String,
        appearance: SubtitleAppearance,
        primary: String,
        outline: String,
        back: String,
        borderStyle: String,
        outlineWidth: Int,
        shadowDistance: Double,
        alignment: Int
    ) -> String {
        [
            "Style: \(name)",
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
            "\(outlineWidth)",
            formatASSNumber(shadowDistance),
            "\(alignment)",
            "\(appearance.marginLeft)",
            "\(appearance.marginRight)",
            "\(appearance.marginVertical)",
            "1"
        ].joined(separator: ",")
    }

    static func dialoguePrefix(from appearance: SubtitleAppearance) -> String {
        if appearance.shadowEnabled, appearance.shadowBlur > 0 {
            return "{\\blur\(formatASSNumber(scaledShadowBlur(from: appearance.shadowBlur)))}"
        }
        if appearance.outlineEnabled, appearance.outlineWidth > 0, appearance.outlineOpacity > 0 {
            return "{\\blur0.25}"
        }
        return ""
    }

    static func backgroundDialoguePrefix(from appearance: SubtitleAppearance) -> String {
        guard appearance.backgroundEnabled else { return "" }
        let xBorder = max(appearance.backgroundPaddingX, 1)
        let yBorder = max(appearance.backgroundPaddingY, 1)
        return "{\\xbord\(xBorder)\\ybord\(yBorder)}"
    }

    private static func scaledShadowDistance(from value: Int) -> Double {
        Double(max(value, 0)) * 0.45
    }

    private static func scaledShadowBlur(from value: Int) -> Double {
        min(Double(max(value, 0)) * 0.08, 1.6)
    }

    private static func formatASSNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
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
