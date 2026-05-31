import AppKit
import SwiftUI

struct ActionCapsule: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct AppIconBadge: View {
    var body: some View {
        Group {
            if let image = NSImage(named: "SubMergeProIcon") ?? loadBundledImage() {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "play.square.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .foregroundStyle(.blue)
            }
        }
        .frame(width: 54, height: 54)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func loadBundledImage() -> NSImage? {
        let candidates: [URL?] = [
            Bundle.main.url(forResource: "SubMergeProIcon", withExtension: "png"),
            Bundle.main.url(forResource: "SubMergeProIcon", withExtension: "png", subdirectory: "Resources"),
            Bundle.main.resourceURL?.appendingPathComponent("SubMergeProIcon.png"),
            Bundle.main.resourceURL?.appendingPathComponent("Resources/SubMergeProIcon.png")
        ]

        guard let url = candidates.compactMap({ $0 }).first else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

struct CapsuleTextButton: View {
    let title: String
    var fontSize: CGFloat = 16
    var horizontalPadding: CGFloat = 18
    var verticalPadding: CGFloat = 10
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct CircleIconButton: View {
    let systemName: String
    var size: CGFloat = 40
    var helpText: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size == 40 ? 15 : 14, weight: .semibold))
                .frame(width: size, height: size)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(helpText ?? "")
    }
}

struct CompactIconButton: View {
    let systemName: String
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black.opacity(0.72))
                .frame(width: 36, height: 34)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(helpText)
        .accessibilityLabel(Text(helpText))
    }
}

struct AboutInfoCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

func styleCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 14) {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
        content()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.black.opacity(0.025))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}

struct StatusBadge: View {
    let status: ProcessingStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(color.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .pending: return .gray
        case .queued: return .orange
        case .processing: return .blue
        case .success: return .green
        case .failed: return .red
        case .canceled: return .secondary
        }
    }
}

struct SettingPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var width: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .frame(width: width)
        }
    }
}

struct NumberInputField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix: String = ""
    @State private var textValue = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            TextField("", text: Binding(
                get: { textValue },
                set: { newValue in
                    textValue = newValue
                    let filtered = newValue.filter { $0.isNumber }
                    if let number = Int(filtered), !filtered.isEmpty {
                        value = min(max(number, range.lowerBound), range.upperBound)
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 78)
            .focused($isFocused)
            .overlay(alignment: .trailing) {
                Text(suffix)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 10)
            }
            .onAppear {
                textValue = "\(value)"
            }
            .onTapGesture {
                if !isFocused {
                    textValue = ""
                }
            }
            .onChange(of: value) { newValue in
                if !isFocused {
                    textValue = "\(newValue)"
                }
            }
            .onChange(of: isFocused) { focused in
                if !focused {
                    if textValue.isEmpty {
                        textValue = "\(value)"
                    } else {
                        let filtered = textValue.filter { $0.isNumber }
                        if let number = Int(filtered), !filtered.isEmpty {
                            value = min(max(number, range.lowerBound), range.upperBound)
                        }
                        textValue = "\(value)"
                    }
                }
            }
        }
    }
}

struct ColorPickerField: View {
    let title: String
    @Binding var value: String
    @State private var color: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            HStack(spacing: 10) {
                ColorPicker("", selection: Binding(
                    get: { color },
                    set: {
                        color = $0
                        value = $0.toHexString() ?? value
                    }
                ))
                .labelsHidden()
                .frame(width: 36)

                TextField("#FFFFFF", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 96)
            }
            .onAppear {
                color = Color(hex: value) ?? .white
            }
            .onChange(of: value) { newValue in
                color = Color(hex: newValue) ?? color
            }
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                AppIconBadge()
                VStack(alignment: .leading, spacing: 6) {
                    Text("关于 SubMergePro")
                        .font(.system(size: 28, weight: .bold))
                    Text("批量视频字幕合成工具")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(Bundle.main.appVersionLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SheetCloseButton {
                    dismiss()
                }
            }

            Text("SubMergePro 用来把本地视频和字幕快速合成到一起，适合课程、口播、讲解和访谈这类需要统一字幕样式的内容。")
                .font(.system(size: 15))
                .foregroundStyle(.black.opacity(0.76))

            VStack(alignment: .leading, spacing: 10) {
                AboutLine(systemName: "film.stack", text: "支持批量添加视频或整个文件夹。")
                AboutLine(systemName: "captions.bubble", text: "自动匹配同名字幕，也可以手动替换字幕文件。")
                AboutLine(systemName: "slider.horizontal.3", text: "可以统一调整字幕样式，再开始导出。")
            }

            Text("建议先在“字幕样式”页确认效果，再开始批量合成。")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 500)
    }
}

struct AboutLine: View {
    let systemName: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.black.opacity(0.76))
        }
    }
}

struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.black.opacity(0.68))
                .frame(width: 34, height: 34)
                .background(Color.black.opacity(0.05))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help("关闭")
    }
}
