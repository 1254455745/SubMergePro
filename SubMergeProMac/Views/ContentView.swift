import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SubMergeViewModel
    @State private var dropActive = false
    @State private var selectedSection: WorkspaceSection = .project

    var body: some View {
        HStack(spacing: 0) {
            SidebarRail(selectedSection: $selectedSection)

            ZStack(alignment: .topLeading) {
                if selectedSection == .project {
                    MainWorkspacePage(viewModel: viewModel, dropActive: $dropActive)
                } else {
                    SubtitleStyleStudioPage(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color.white, Color(red: 0.97, green: 0.98, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onChange(of: selectedSection) { section in
            if section == .style {
                viewModel.showStyleEditor()
            }
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .sheet(isPresented: $viewModel.aboutPresented) {
            AboutSheet()
        }
        .sheet(isPresented: $viewModel.previewPresented) {
            SubtitlePreviewSheet(viewModel: viewModel)
        }
    }
}

private enum WorkspaceSection: String, CaseIterable {
    case project
    case style
}

private struct MainWorkspacePage: View {
    @ObservedObject var viewModel: SubMergeViewModel
    @Binding var dropActive: Bool

    var body: some View {
        GeometryReader { proxy in
            let metrics = MainWorkspaceMetrics(size: proxy.size)

            VStack(spacing: metrics.sectionSpacing) {
                HeaderBar(viewModel: viewModel)
                VideoTableCard(
                    viewModel: viewModel,
                    dropActive: $dropActive,
                    availableWidth: metrics.contentWidth,
                    height: metrics.tableHeight
                )
                SettingsPanel(viewModel: viewModel)
                FooterBar(viewModel: viewModel)
            }
            .padding(.top, metrics.topPadding)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.bottom, metrics.bottomPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct MainWorkspaceMetrics {
    let size: CGSize

    let horizontalPadding: CGFloat = 18
    let topPadding: CGFloat = 18
    let bottomPadding: CGFloat = 2
    let sectionSpacing: CGFloat = 14

    var contentWidth: CGFloat {
        max(size.width - (horizontalPadding * 2), 0)
    }

    var tableHeight: CGFloat {
        let reservedHeight: CGFloat = 320
        let available = size.height - topPadding - bottomPadding - (sectionSpacing * 3) - reservedHeight
        return max(available, 260)
    }
}

private struct SidebarRail: View {
    @Binding var selectedSection: WorkspaceSection

    var body: some View {
        VStack(spacing: 16) {
            AppIconBadge()
                .frame(width: 52, height: 52)

            VStack(spacing: 10) {
                SidebarTabButton(
                    title: "主页面",
                    systemName: "square.grid.2x2",
                    isSelected: selectedSection == .project
                ) {
                    selectedSection = .project
                }

                SidebarTabButton(
                    title: "字幕样式",
                    systemName: "captions.bubble",
                    isSelected: selectedSection == .style
                ) {
                    selectedSection = .style
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 18)
        .frame(width: 88)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.white.opacity(0.62))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 1)
        }
    }
}

private struct SidebarTabButton: View {
    let title: String
    let systemName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(isSelected ? .white : .black.opacity(0.72))
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(isSelected ? Color.blue : Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct HeaderBar: View {
    @ObservedObject var viewModel: SubMergeViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SubMergePro")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.72))
                Text("批量视频字幕合成")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 16) {
                ActionCapsule(title: "添加视频", action: viewModel.addVideos)
                ActionCapsule(title: "添加文件夹", action: viewModel.addFolder)
                ActionCapsule(title: "清空列表", action: viewModel.clearList)
            }

            Spacer()

            CircleIconButton(systemName: "info.circle", helpText: "关于 SubMergePro") {
                viewModel.aboutPresented = true
            }
        }
    }
}

private struct VideoTableCard: View {
    @ObservedObject var viewModel: SubMergeViewModel
    @Binding var dropActive: Bool
    let availableWidth: CGFloat
    let height: CGFloat

    var body: some View {
        let layout = VideoTableLayout(availableWidth: availableWidth)

        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                TableColumns(layout: layout) {
                    header("序号", width: layout.indexWidth, alignment: .leading)
                    header("文件名", width: layout.fileNameWidth, alignment: .leading)
                    header("时长", width: layout.durationWidth, alignment: .leading)
                    header("字幕文件", width: layout.subtitleWidth, alignment: .leading)
                    header("状态", width: layout.statusWidth, alignment: .center)
                    header("操作", width: layout.actionsWidth, alignment: .center)
                }

                Divider()

                if viewModel.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("把视频或文件夹拖到这里，或者点击上方按钮添加")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: layout.tableWidth)
                    .frame(minHeight: max(height - 58, 236))
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.items) { item in
                                VideoRowView(item: item, viewModel: viewModel, layout: layout)
                                Divider().padding(.leading, layout.horizontalPadding)
                            }
                        }
                    }
                    .frame(maxHeight: max(height - 58, 236))
                }
            }
            .frame(width: layout.tableWidth, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .overlay {
            if dropActive {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.blue.opacity(0.08))

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
                        .foregroundStyle(Color.blue.opacity(0.7))

                    VStack(spacing: 14) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.blue)
                        Text("松开鼠标即可导入视频或文件夹")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.8))
                    }
                    .padding(24)
                }
            }
        }
        .shadow(color: .black.opacity(0.04), radius: 18, x: 0, y: 10)
        .onDrop(of: [.fileURL], isTargeted: $dropActive) { providers in
            viewModel.handleDroppedItems(providers)
        }
    }

    private func header(_ text: String, width: CGFloat, alignment: Alignment) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.black.opacity(0.75))
            .frame(width: width, alignment: alignment)
            .lineLimit(1)
    }
}

private struct VideoRowView: View {
    let item: VideoItem
    @ObservedObject var viewModel: SubMergeViewModel
    let layout: VideoTableLayout

    var body: some View {
        TableColumns(layout: layout) {
            Text("\(item.index)")
                .font(.system(size: 13, weight: .medium))
                .frame(width: layout.indexWidth, alignment: .leading)
                .foregroundStyle(.black.opacity(0.72))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.videoURL.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.system(size: 16, weight: .medium))
                    .help(item.videoURL.lastPathComponent)
                Text("\(item.container)  |  \(item.resolutionText)  |  \(item.frameRateText)  |  \(item.bitrateText)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: layout.fileNameWidth, alignment: .leading)

            Text(item.durationText)
                .font(.system(size: 14))
                .frame(width: layout.durationWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Button {
                    viewModel.chooseSubtitle(for: item.id)
                } label: {
                    Text(item.subtitleURL?.lastPathComponent ?? "点击选择字幕")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(item.subtitleURL == nil ? .blue : .black.opacity(0.82))
                        .underline(item.subtitleURL == nil, color: .blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .help(item.subtitleURL?.path ?? "点击选择字幕")
                if let lastError = item.lastError {
                    Text(lastError)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
            .frame(width: layout.subtitleWidth, alignment: .leading)

            VideoRowStatusView(item: item)
                .frame(width: layout.statusWidth)

            HStack(spacing: layout.actionSpacing) {
                CircleIconButton(systemName: "play.fill", size: layout.actionIconSize, helpText: "开始合成这个视频") {
                    viewModel.startRender(for: item.id)
                }
                CircleIconButton(systemName: "text.viewfinder", size: layout.actionIconSize, helpText: "预览字幕效果") {
                    viewModel.showPreview(for: item.id)
                }
                CircleIconButton(systemName: "folder", size: layout.actionIconSize, helpText: "打开导出位置") {
                    viewModel.openItemOutput(item.id)
                }
                CapsuleTextButton(
                    title: "移除",
                    fontSize: 14,
                    horizontalPadding: layout.removeButtonHorizontalPadding,
                    verticalPadding: 8
                ) {
                    viewModel.removeItem(item.id)
                }
            }
            .frame(width: layout.actionsWidth)
        }
    }
}

private struct VideoTableLayout {
    let availableWidth: CGFloat

    private var compactMode: Bool {
        tableWidth < 980
    }

    var horizontalPadding: CGFloat {
        compactMode ? 10 : 12
    }

    var columnSpacing: CGFloat {
        compactMode ? 10 : 12
    }

    var indexWidth: CGFloat {
        max(min(usableWidth * 0.05, 38), 28)
    }

    var durationWidth: CGFloat {
        max(min(usableWidth * 0.08, 82), 62)
    }

    var statusWidth: CGFloat {
        max(min(usableWidth * 0.16, 156), 136)
    }

    var actionsWidth: CGFloat {
        max(min(usableWidth * 0.18, 178), 162)
    }

    var actionIconSize: CGFloat {
        actionsWidth < 166 ? 30 : 36
    }

    var actionSpacing: CGFloat {
        actionIconSize < 36 ? 6 : 8
    }

    var removeButtonHorizontalPadding: CGFloat {
        actionIconSize < 36 ? 10 : 14
    }

    var tableWidth: CGFloat {
        max(availableWidth, 0)
    }

    private var chromeWidth: CGFloat {
        (horizontalPadding * 2) + (columnSpacing * 5)
    }

    private var usableWidth: CGFloat {
        max(tableWidth - chromeWidth, 560)
    }

    private var flexibleWidth: CGFloat {
        max(usableWidth - indexWidth - durationWidth - statusWidth - actionsWidth, 260)
    }

    var fileNameWidth: CGFloat {
        flexibleWidth - subtitleWidth
    }

    var subtitleWidth: CGFloat {
        min(max(flexibleWidth * 0.42, 190), 250)
    }
}

private struct VideoRowStatusView: View {
    let item: VideoItem

    var body: some View {
        Group {
            if item.status == .processing {
                HStack(spacing: 10) {
                    StatusBadge(status: item.status)

                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                        .tint(Color.blue)
                        .frame(maxWidth: .infinity)
                }
            } else {
                StatusBadge(status: item.status)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: item.status == .processing ? .leading : .center)
    }
}

private struct TableColumns<Content: View>: View {
    let layout: VideoTableLayout
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: layout.columnSpacing) {
            content()
        }
        .padding(.horizontal, layout.horizontalPadding)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsPanel: View {
    @ObservedObject var viewModel: SubMergeViewModel

    var body: some View {
        styleCard("导出设置") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 10) {
                    SettingPicker(title: "格式", selection: $viewModel.renderOptions.container, options: viewModel.formatOptions, width: 82)
                    SettingPicker(title: "分辨率", selection: $viewModel.renderOptions.resolution, options: viewModel.resolutionOptions, width: 112)
                    SettingPicker(title: "比特率", selection: $viewModel.renderOptions.bitrate, options: viewModel.bitrateOptions, width: 82)
                    SettingPicker(title: "帧率", selection: $viewModel.renderOptions.frameRate, options: viewModel.frameRateOptions, width: 78)
                    SettingPicker(title: "编码器", selection: $viewModel.renderOptions.codec, options: viewModel.codecOptions, width: 88)
                }

                HStack(spacing: 8) {
                    TextField("输出目录", text: $viewModel.renderOptions.outputDirectory)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 260)
                    CapsuleTextButton(title: "浏览") {
                        viewModel.chooseOutputDirectory()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct StyleToggle: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 28, height: 27)
                .foregroundStyle(isOn ? .white : (colorScheme == .dark ? .white.opacity(0.82) : .black.opacity(0.7)))
                .background(isOn ? Color.blue : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(title == "B" ? "加粗" : title == "I" ? "斜体" : "下划线")
    }
}

private struct FooterBar: View {
    @ObservedObject var viewModel: SubMergeViewModel

    var body: some View {
        HStack {
            Text("共 \(viewModel.items.count) 个文件")
                .font(.system(size: 18))
                .foregroundStyle(.black.opacity(0.76))

            Spacer()

            Button(action: viewModel.startRenderAll) {
                Text(viewModel.isRenderingAll ? "合成中..." : "开始合成")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 170, height: 58)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.26, green: 0.45, blue: 1.0), Color(red: 0.18, green: 0.35, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 0)
    }
}

private struct ActionCapsule: View {
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

private struct AppIconBadge: View {
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
        .background(Color.white.opacity(0.9))
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

private struct CapsuleTextButton: View {
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

private struct CircleIconButton: View {
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

private struct AboutInfoCard: View {
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

private func styleCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
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

private struct StatusBadge: View {
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

private struct SettingPicker: View {
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

private struct NumberInputField: View {
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

private struct ColorPickerField: View {
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

private struct AboutSheet: View {
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

private struct AboutLine: View {
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

private struct SubtitleStyleStudioPage: View {
    @ObservedObject var viewModel: SubMergeViewModel

    private var outlineEnabled: Binding<Bool> {
        Binding(
            get: {
                viewModel.subtitleAppearance.outlineWidth > 0 && viewModel.subtitleAppearance.outlineOpacity > 0
            },
            set: { enabled in
                if enabled {
                    if viewModel.subtitleAppearance.outlineWidth == 0 {
                        viewModel.subtitleAppearance.outlineWidth = 3
                    }
                    if viewModel.subtitleAppearance.outlineOpacity == 0 {
                        viewModel.subtitleAppearance.outlineOpacity = 90
                    }
                } else {
                    viewModel.subtitleAppearance.outlineWidth = 0
                    viewModel.subtitleAppearance.outlineOpacity = 0
                }
            }
        )
    }

    private var shadowEnabled: Binding<Bool> {
        Binding(
            get: {
                viewModel.subtitleAppearance.shadowOpacity > 0 ||
                viewModel.subtitleAppearance.shadowDistance > 0 ||
                viewModel.subtitleAppearance.shadowBlur > 0
            },
            set: { enabled in
                if enabled {
                    if viewModel.subtitleAppearance.shadowOpacity == 0 {
                        viewModel.subtitleAppearance.shadowOpacity = 43
                    }
                    if viewModel.subtitleAppearance.shadowDistance == 0 {
                        viewModel.subtitleAppearance.shadowDistance = 1
                    }
                } else {
                    viewModel.subtitleAppearance.shadowOpacity = 0
                    viewModel.subtitleAppearance.shadowDistance = 0
                    viewModel.subtitleAppearance.shadowBlur = 0
                }
            }
        )
    }

    private var backgroundEnabled: Binding<Bool> {
        Binding(
            get: {
                viewModel.subtitleAppearance.backgroundOpacity > 0
            },
            set: { enabled in
                viewModel.subtitleAppearance.backgroundOpacity = enabled ? max(viewModel.subtitleAppearance.backgroundOpacity, 70) : 0
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("字幕样式页")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.black.opacity(0.82))
                        Text("左侧调整字幕参数，右侧查看 FFmpeg/libass 的实时渲染结果。")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    StudioSectionCard(title: "文字", subtitle: "字体、字号、基础样式与颜色") {
                        StudioMenuRow(title: "字体", selection: $viewModel.subtitleAppearance.fontName, options: viewModel.fontOptions)
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
                        StudioSliderRow(title: "透明", value: $viewModel.subtitleAppearance.textOpacity, range: 0...100, suffix: "%")
                        StudioSliderRow(title: "字距", value: $viewModel.subtitleAppearance.letterSpacing, range: 0...20)
                    }

                    StudioSectionCard(title: "描边", subtitle: "控制字幕边缘粗细和透明度", isEnabled: outlineEnabled) {
                        StudioColorRow(title: "颜色", value: $viewModel.subtitleAppearance.outlineColorHex)
                        StudioSliderRow(title: "透明", value: $viewModel.subtitleAppearance.outlineOpacity, range: 0...100, suffix: "%")
                        StudioSliderRow(title: "粗细", value: $viewModel.subtitleAppearance.outlineWidth, range: 0...12)
                    }

                    StudioSectionCard(title: "阴影", subtitle: "让字幕和画面分离得更干净", isEnabled: shadowEnabled) {
                        StudioColorRow(title: "颜色", value: $viewModel.subtitleAppearance.shadowColorHex)
                        StudioSliderRow(title: "透明", value: $viewModel.subtitleAppearance.shadowOpacity, range: 0...100, suffix: "%")
                        StudioSliderRow(title: "模糊", value: $viewModel.subtitleAppearance.shadowBlur, range: 0...20)
                        StudioSliderRow(title: "距离", value: $viewModel.subtitleAppearance.shadowDistance, range: 0...20)
                    }

                    StudioSectionCard(title: "背景", subtitle: "为字幕加背景框，提升复杂画面下的可读性", isEnabled: backgroundEnabled) {
                        StudioColorRow(title: "颜色", value: $viewModel.subtitleAppearance.backgroundColorHex)
                        StudioSliderRow(title: "透明", value: $viewModel.subtitleAppearance.backgroundOpacity, range: 0...100, suffix: "%")
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

private struct StyleStudioPreviewPanel: View {
    @ObservedObject var viewModel: SubMergeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("实时预览")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black.opacity(0.82))
                    Text("这里始终使用固定示例画布来预览字幕效果。")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
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
            }

            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    if let image = viewModel.previewImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                    } else {
                        studioPreviewFallbackBackground
                            .overlay {
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
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("16:9 固定示例画面")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(16)
                }

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
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.previewItem == nil ? "预览文案" : "当前字幕文本")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.8))

                if viewModel.previewItem == nil {
                    TextEditor(text: $viewModel.previewText)
                        .font(.system(size: 16))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(height: 112)
                        .background(Color.black.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var studioPreviewFallbackBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.24, blue: 0.34),
                Color(red: 0.56, green: 0.71, blue: 0.83),
                Color(red: 0.96, green: 0.73, blue: 0.62)
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

private struct StudioSectionCard<Content: View>: View {
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

private struct StudioMenuRow: View {
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

private struct StudioColorRow: View {
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

private struct StudioSliderRow: View {
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

private struct StudioValueStepper: View {
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

private struct StudioAlignmentGrid: View {
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

private struct PlainTrackSlider: View {
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

private struct SubtitlePreviewSheet: View {
    @ObservedObject var viewModel: SubMergeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.previewItem == nil ? "真实样式预览" : "视频字幕预览")
                        .font(.system(size: 26, weight: .bold))
                    Text("这里显示的是 FFmpeg/libass 真实渲染结果，目标是和最终导出尽量一致。")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if viewModel.previewItem == nil {
                    CapsuleTextButton(title: "重新渲染") {
                        viewModel.renderStylePreviewFrame()
                    }
                }
            }

            previewImageView
            .frame(width: 900, height: 506)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .topLeading) {
                Text(viewModel.previewItem?.videoURL.lastPathComponent ?? "16:9 画面预览")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(16)
            }

            if viewModel.previewItem != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("预览时间")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Text(formatTime(viewModel.previewTime) + " / " + formatTime(viewModel.previewDuration))
                            .font(.system(size: 14))
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
                    .onChange(of: viewModel.previewTime) { _ in
                        viewModel.scheduleLivePreviewRender(delayNanoseconds: 120_000_000)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.previewItem == nil ? "样式预览文本" : "当前字幕文本")
                    .font(.system(size: 16, weight: .medium))
                if viewModel.previewItem == nil {
                    TextEditor(text: Binding(
                        get: { previewSubtitleText },
                        set: { _ in }
                    ))
                        .font(.system(size: 15))
                        .frame(height: 90)
                        .padding(8)
                        .background(Color.black.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(true)
                } else {
                    Text(previewSubtitleText)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(28)
        .frame(minWidth: 980, minHeight: viewModel.previewItem == nil ? 680 : 760)
        .onAppear {
            if viewModel.previewItem == nil, viewModel.previewImage == nil {
                viewModel.renderStylePreviewFrame()
            }
        }
    }

    private var previewImageView: some View {
        ZStack {
            if let image = viewModel.previewImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else {
                previewFallbackBackground
                    .overlay {
                        VStack(spacing: 10) {
                            if viewModel.previewIsRendering {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.previewRenderError ?? "正在生成真实字幕预览")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(12)
                                .background(Color.black.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
            }
        }
    }

    private var previewFallbackBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.24, blue: 0.34),
                Color(red: 0.56, green: 0.71, blue: 0.83),
                Color(red: 0.96, green: 0.73, blue: 0.62)
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

private extension Color {
    init?(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    func toHexString() -> String? {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB)
        guard let nsColor else { return nil }
        let red = Int(round(nsColor.redComponent * 255))
        let green = Int(round(nsColor.greenComponent * 255))
        let blue = Int(round(nsColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

private extension Bundle {
    var appVersionLabel: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "v\(version) (\(build))"
    }
}
