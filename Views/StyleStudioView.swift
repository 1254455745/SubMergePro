import AppKit
import SwiftUI

struct SubtitleStyleStudioPage: View {
    @ObservedObject var viewModel: SubMergeViewModel

    private var outlineEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.subtitleAppearance.outlineEnabled },
            set: { enabled in
                viewModel.subtitleAppearance.outlineEnabled = enabled
            }
        )
    }

    private var shadowEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.subtitleAppearance.shadowEnabled },
            set: { enabled in
                viewModel.subtitleAppearance.shadowEnabled = enabled
            }
        )
    }

    private var backgroundEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.subtitleAppearance.backgroundEnabled },
            set: { enabled in
                viewModel.subtitleAppearance.backgroundEnabled = enabled
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 12) {
                        Text("字幕样式页")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.black.opacity(0.82))
                        Spacer()
                        CapsuleTextButton(title: "恢复默认样式", fontSize: 14, horizontalPadding: 14, verticalPadding: 9) {
                            viewModel.resetSubtitleAppearance()
                        }
                    }

                    StudioSectionCard(title: "文字", subtitle: "字体、字号、基础样式与颜色") {
                        StudioFontPickerRow(title: "字体", selection: $viewModel.subtitleAppearance.fontName, options: viewModel.fontOptions)
                        StudioSliderRow(title: "字号", value: $viewModel.subtitleAppearance.fontSize, range: 12...120)

                        HStack(spacing: 12) {
                            Text("样式")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.black.opacity(0.72))
                                .frame(width: 60, alignment: .leading)
                            HStack(spacing: 8) {
                                StyleToggle(title: "B", isOn: $viewModel.subtitleAppearance.isBold)
                                StyleToggle(title: "I", isOn: $viewModel.subtitleAppearance.isItalic)
                                StyleToggle(title: "U", isOn: $viewModel.subtitleAppearance.isUnderline)
                            }
                            Spacer()
                        }

                        StudioColorRow(title: "颜色", value: $viewModel.subtitleAppearance.textColorHex)
                        StudioSliderRow(title: "不透明", value: $viewModel.subtitleAppearance.textOpacity, range: 0...100, suffix: "%")
                        StudioSliderRow(title: "字距", value: $viewModel.subtitleAppearance.letterSpacing, range: 0...20)
                    }

                    StudioSectionCard(title: "描边", subtitle: "控制字幕边缘粗细和透明度", isEnabled: outlineEnabled) {
                        StudioColorRow(title: "颜色", value: $viewModel.subtitleAppearance.outlineColorHex)
                        StudioSliderRow(title: "不透明", value: $viewModel.subtitleAppearance.outlineOpacity, range: 0...100, suffix: "%")
                        StudioSliderRow(title: "粗细", value: $viewModel.subtitleAppearance.outlineWidth, range: 0...12)
                    }

                    StudioSectionCard(title: "阴影", subtitle: "让字幕和画面分离得更干净", isEnabled: shadowEnabled) {
                        StudioColorRow(title: "颜色", value: $viewModel.subtitleAppearance.shadowColorHex)
                        StudioSliderRow(title: "不透明", value: $viewModel.subtitleAppearance.shadowOpacity, range: 0...100, suffix: "%")
                        StudioSliderRow(title: "模糊", value: $viewModel.subtitleAppearance.shadowBlur, range: 0...20)
                        StudioSliderRow(title: "距离", value: $viewModel.subtitleAppearance.shadowDistance, range: 0...20)
                    }

                    StudioSectionCard(title: "背景", subtitle: "为字幕加背景框，提升复杂画面下的可读性", isEnabled: backgroundEnabled) {
                        StudioColorRow(title: "颜色", value: $viewModel.subtitleAppearance.backgroundColorHex)
                        StudioSliderRow(title: "不透明", value: $viewModel.subtitleAppearance.backgroundOpacity, range: 0...100, suffix: "%")
                        StudioSliderRow(title: "宽度", value: $viewModel.subtitleAppearance.backgroundPaddingX, range: 0...100)
                        StudioSliderRow(title: "高度", value: $viewModel.subtitleAppearance.backgroundPaddingY, range: 0...100)
                    }

                    StudioSectionCard(title: "位置", subtitle: "对齐方式、边距、缩放和旋转") {
                        StudioAlignmentGrid(selection: $viewModel.subtitleAppearance.alignment)
                        StudioSliderRow(title: "底部", value: $viewModel.subtitleAppearance.marginVertical, range: 0...240)
                        StudioSliderRow(title: "左边", value: $viewModel.subtitleAppearance.marginLeft, range: 0...360)
                        StudioSliderRow(title: "右边", value: $viewModel.subtitleAppearance.marginRight, range: 0...360)
                        StudioSliderRow(title: "横向", value: $viewModel.subtitleAppearance.scaleX, range: 20...200, suffix: "%")
                        StudioSliderRow(title: "纵向", value: $viewModel.subtitleAppearance.scaleY, range: 20...200, suffix: "%")
                        StudioSliderRow(title: "旋转", value: $viewModel.subtitleAppearance.rotation, range: -180...180, suffix: "°")
                    }
                }
                .padding(28)
                .frame(width: 430, alignment: .leading)
                .disabled(viewModel.isOperationLocked)
                .opacity(viewModel.isOperationLocked ? 0.55 : 1)
            }

            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 1)

            StyleStudioPreviewPanel(viewModel: viewModel)
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            viewModel.showStyleEditor()
        }
        .onChange(of: viewModel.subtitleAppearance) { _ in
            viewModel.scheduleLivePreviewRender()
        }
        .onChange(of: viewModel.previewTime) { _ in
            if viewModel.previewItem != nil {
                viewModel.scheduleLivePreviewRender(delayNanoseconds: 120_000_000)
            }
        }
        .onChange(of: viewModel.previewText) { _ in
            if viewModel.previewItem == nil {
                viewModel.scheduleLivePreviewRender(delayNanoseconds: 220_000_000)
            }
        }
    }
}

struct StyledSubtitleTextPreview: View {
    let text: String
    let appearance: SubtitleAppearance

    var body: some View {
        ZStack {
            textPreviewContent
                .fixedSize(horizontal: true, vertical: true)
                .scaleEffect(
                    x: CGFloat(appearance.scaleX) / 100,
                    y: CGFloat(appearance.scaleY) / 100,
                    anchor: .center
                )
                .rotationEffect(.degrees(Double(appearance.rotation)))
                .drawingGroup(opaque: false, colorMode: .linear)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var textPreviewContent: some View {
        ZStack {
            ZStack {
                ZStack {
                    outlinePreviewLayer

                    textLayer(color: textColor)
                        .shadow(
                            color: shadowColor,
                            radius: scaledShadowBlur,
                            x: scaledShadowDistance,
                            y: scaledShadowDistance
                        )
                }
                .padding(.horizontal, horizontalBackgroundPadding)
                .padding(.vertical, verticalBackgroundPadding)
                .background {
                    if appearance.backgroundEnabled {
                        Rectangle()
                            .fill(backgroundColor)
                    }
                }
            }
        }
    }

    private var outlinePreviewLayer: some View {
        ZStack {
            ForEach(Array(outlineOffsets.enumerated()), id: \.offset) { _, offset in
                textLayer(color: outlineColor)
                    .offset(x: offset.width, y: offset.height)
            }
        }
        .compositingGroup()
        .overlay {
            if !outlineOffsets.isEmpty {
                textLayer(color: .white)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
    }

    private func textLayer(color: Color) -> some View {
        styledText
            .font(.custom(appearance.fontName, size: CGFloat(appearance.fontSize)))
            .kerning(CGFloat(appearance.letterSpacing))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.45)
    }

    private var styledText: Text {
        var rendered = Text(text)
        if appearance.isBold {
            rendered = rendered.bold()
        }
        if appearance.isItalic {
            rendered = rendered.italic()
        }
        if appearance.isUnderline {
            rendered = rendered.underline()
        }
        return rendered
    }

    private var outlineOffsets: [CGSize] {
        guard appearance.outlineEnabled, appearance.outlineWidth > 0, appearance.outlineOpacity > 0 else { return [] }
        let radius = min(max(CGFloat(appearance.outlineWidth), 1), 10)
        let steps = max(1, min(5, Int(ceil(radius))))
        let directions = (0..<16).map { index in
            let angle = Double(index) / 16 * 2 * Double.pi
            return CGSize(width: cos(angle), height: sin(angle))
        }

        return (1...steps).flatMap { step in
            let amount = radius * CGFloat(step) / CGFloat(steps)
            return directions.map { CGSize(width: $0.width * amount, height: $0.height * amount) }
        }
    }

    private var textColor: Color {
        (Color(hex: appearance.textColorHex) ?? .white).opacity(Double(appearance.textOpacity) / 100)
    }

    private var outlineColor: Color {
        (Color(hex: appearance.outlineColorHex) ?? .black).opacity(Double(appearance.outlineOpacity) / 100)
    }

    private var shadowColor: Color {
        guard appearance.shadowEnabled else { return .clear }
        return (Color(hex: appearance.shadowColorHex) ?? .black).opacity(Double(appearance.shadowOpacity) / 100)
    }

    private var scaledShadowBlur: CGFloat {
        appearance.shadowEnabled ? min(CGFloat(max(appearance.shadowBlur, 0)) * 0.35, 7) : 0
    }

    private var scaledShadowDistance: CGFloat {
        appearance.shadowEnabled ? CGFloat(max(appearance.shadowDistance, 0)) * 0.55 : 0
    }

    private var backgroundColor: Color {
        (Color(hex: appearance.backgroundColorHex) ?? .black).opacity(Double(appearance.backgroundOpacity) / 100)
    }

    private var horizontalBackgroundPadding: CGFloat {
        appearance.backgroundEnabled ? CGFloat(max(appearance.backgroundPaddingX, 1)) : 16
    }

    private var verticalBackgroundPadding: CGFloat {
        appearance.backgroundEnabled ? CGFloat(max(appearance.backgroundPaddingY, 1)) : 8
    }
}

struct StyleStudioPreviewPanel: View {
    @ObservedObject var viewModel: SubMergeViewModel

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width, 0)
            let previewHeight = contentWidth * 9 / 16

            VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("实时预览")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black.opacity(0.82))
                }

                Spacer()

                Button(action: viewModel.renderCurrentPreviewFrame) {
                    Label("重新渲染", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(.black.opacity(0.76))
                        .background(Color.black.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isOperationLocked)
                .opacity(viewModel.isOperationLocked ? 0.45 : 1)
            }
            .frame(width: contentWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("文字样式")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.8))

                    StyledSubtitleTextPreview(
                        text: previewSubtitleText,
                        appearance: viewModel.subtitleAppearance
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 138)
                    .frame(width: contentWidth)
                    .background(textPreviewSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                }

                ZStack {
                    studioPreviewFallbackBackground

                    if let image = viewModel.previewImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: contentWidth, height: previewHeight)
                            .clipped()
                    } else {
                        VStack(spacing: 12) {
                            if viewModel.previewIsRendering {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.previewRenderError ?? "正在生成实时字幕预览")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .frame(width: contentWidth, height: previewHeight)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("16:9 固定示例画面")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(16)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    viewModel.presentCurrentPreview()
                }
                .help("双击放大预览")

                if viewModel.previewItem != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("预览时间")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.black.opacity(0.76))
                            Spacer()
                            Text(formatTime(viewModel.previewTime) + " / " + formatTime(viewModel.previewDuration))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        PlainTrackSlider(
                            value: Binding(
                                get: { viewModel.previewTime },
                                set: { viewModel.previewTime = $0 }
                            ),
                            range: 0...max(viewModel.previewDuration, 1),
                            step: 0.1
                        )
                        .disabled(viewModel.isOperationLocked)
                        .opacity(viewModel.isOperationLocked ? 0.45 : 1)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                }
            }
            .frame(width: contentWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.previewItem == nil ? "预览文案" : "当前字幕文本")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.8))

                if viewModel.previewItem == nil {
                    TextField("预览文案", text: $viewModel.previewText)
                        .font(.system(size: 16))
                        .padding(.horizontal, 12)
                        .textFieldStyle(.plain)
                        .frame(height: 44)
                        .background(Color.black.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(viewModel.isOperationLocked)
                        .opacity(viewModel.isOperationLocked ? 0.55 : 1)
                } else {
                    ScrollView {
                        Text(previewSubtitleText)
                            .font(.system(size: 16))
                            .foregroundStyle(.black.opacity(0.82))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }
                    .frame(height: 112)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(16)
            .frame(width: contentWidth, alignment: .leading)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )

            Spacer(minLength: 0)
        }
            .frame(width: contentWidth, alignment: .leading)
        }
    }

    private var studioPreviewFallbackBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.98, blue: 1.0),
                Color(red: 0.60, green: 0.80, blue: 0.95),
                Color(red: 1.0, green: 0.82, blue: 0.67)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var textPreviewSurface: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.99, blue: 1.0),
                Color(red: 0.91, green: 0.96, blue: 1.0),
                Color(red: 1.0, green: 0.95, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var previewSubtitleText: String {
        let text = viewModel.previewItem == nil ? viewModel.previewText : viewModel.subtitleText(at: viewModel.previewTime)
        return text.isEmpty ? "当前时间点没有字幕" : text
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = max(Int(seconds.rounded()), 0)
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}

struct StudioSectionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var isEnabled: Binding<Bool>? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        let enabled = isEnabled?.wrappedValue ?? true

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                if let isEnabled {
                    Button {
                        isEnabled.wrappedValue.toggle()
                    } label: {
                        Image(systemName: isEnabled.wrappedValue ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isEnabled.wrappedValue ? Color.blue : Color.black.opacity(0.22))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.black.opacity(0.82))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            VStack(spacing: 14) {
                content()
            }
            .opacity(enabled ? 1 : 0.42)
            .disabled(!enabled)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

struct StudioMenuRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black.opacity(0.72))
                .frame(width: 60, alignment: .leading)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 14)
                .frame(height: 42)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

struct StudioFontPickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    @State private var isPresented = false

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black.opacity(0.72))
                .frame(width: 60, alignment: .leading)

            Button {
                isPresented.toggle()
            } label: {
                HStack {
                    Text(selection)
                        .font(.custom(selection, size: 15))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 14)
                .frame(height: 42)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                selection = option
                                isPresented = false
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .opacity(selection == option ? 1 : 0)
                                        .frame(width: 16)
                                    Text(option)
                                        .font(.custom(option, size: 14))
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .foregroundStyle(.black.opacity(0.82))
                                .padding(.horizontal, 12)
                                .frame(height: 32)
                                .background(selection == option ? Color.blue.opacity(0.10) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                }
                .frame(width: 300, height: 320)
            }
        }
    }
}

struct StudioColorRow: View {
    let title: String
    @Binding var value: String
    @State private var color: Color = .white

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black.opacity(0.72))
                .frame(width: 60, alignment: .leading)

            ColorPicker("", selection: Binding(
                get: { color },
                set: {
                    color = $0
                    value = $0.toHexString() ?? value
                }
            ))
            .labelsHidden()
            .frame(width: 58)

            TextField("#FFFFFF", text: $value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 110)
                .onAppear {
                    color = Color(hex: value) ?? .white
                }
                .onChange(of: value) { newValue in
                    color = Color(hex: newValue) ?? color
                }

            Spacer()
        }
    }
}

struct StudioSliderRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black.opacity(0.72))
                .frame(width: 60, alignment: .leading)

            PlainTrackSlider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                range: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )

            StudioValueStepper(value: $value, range: range, suffix: suffix)
        }
    }
}

struct StudioValueStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix: String = ""

    var body: some View {
        HStack(spacing: 0) {
            Text(displayValue)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 76)

            Divider()
                .overlay(Color.black.opacity(0.06))

            Stepper("", value: $value, in: range)
                .labelsHidden()
                .frame(width: 28)
        }
        .frame(height: 40)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var displayValue: String {
        suffix.isEmpty ? "\(value)" : "\(value)\(suffix)"
    }
}

struct StudioAlignmentGrid: View {
    @Binding var selection: String

    private let entries: [(String, String)] = [
        ("顶部居左", "左上"), ("顶部居中", "上中"), ("顶部居右", "右上"),
        ("中间居左", "左中"), ("中间居中", "居中"), ("中间居右", "右中"),
        ("底部居左", "左下"), ("底部居中", "下中"), ("底部居右", "右下")
    ]

    private let columns = Array(repeating: GridItem(.flexible(minimum: 70), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("对齐方式")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black.opacity(0.72))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(entries, id: \.0) { entry in
                    Button {
                        selection = entry.0
                    } label: {
                        Text(entry.1)
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .foregroundStyle(selection == entry.0 ? .white : .black.opacity(0.75))
                            .background(selection == entry.0 ? Color.blue : Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct PlainTrackSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let progress = normalizedValue
            let thumbX = progress * width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.blue)
                    .frame(width: max(thumbX, 0), height: 4)

                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .offset(x: min(max(thumbX - 9, -9), width - 9))
            }
            .frame(height: 22)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let ratio = min(max(gesture.location.x / width, 0), 1)
                        let rawValue = range.lowerBound + (range.upperBound - range.lowerBound) * ratio
                        let stepped = ((rawValue - range.lowerBound) / step).rounded() * step + range.lowerBound
                        value = min(max(stepped, range.lowerBound), range.upperBound)
                    }
            )
        }
        .frame(height: 22)
    }

    private var normalizedValue: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}
