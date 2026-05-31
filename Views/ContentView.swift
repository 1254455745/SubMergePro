import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SubMergeViewModel
    @State private var dropActive = false
    @State private var selectedSection: WorkspaceSection = .project

    var body: some View {
        HStack(spacing: 0) {
            SidebarRail(selectedSection: $selectedSection, isRendering: viewModel.isOperationLocked)

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
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            viewModel.handleApplicationExit()
        }
        .onDisappear {
            viewModel.handleApplicationExit()
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

enum WorkspaceSection: String, CaseIterable {
    case project
    case style
}

struct MainWorkspacePage: View {
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

struct MainWorkspaceMetrics {
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

struct SidebarRail: View {
    @Binding var selectedSection: WorkspaceSection
    let isRendering: Bool

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
                    isSelected: selectedSection == .style,
                    isDisabled: isRendering
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
        .background(Color.white)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 1)
        }
    }
}

struct SidebarTabButton: View {
    let title: String
    let systemName: String
    let isSelected: Bool
    var isDisabled = false
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
            .foregroundStyle(isSelected ? .white : .black.opacity(isDisabled ? 0.36 : 0.72))
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(isSelected ? Color.blue : Color.black.opacity(isDisabled ? 0.025 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(isDisabled ? "合成中不能修改字幕样式" : "")
    }
}

struct HeaderBar: View {
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
            .disabled(viewModel.isOperationLocked)
            .opacity(viewModel.isOperationLocked ? 0.45 : 1)

            Spacer()

            CircleIconButton(systemName: "info.circle", helpText: "关于 SubMergePro") {
                viewModel.aboutPresented = true
            }
        }
    }
}

struct VideoTableCard: View {
    @ObservedObject var viewModel: SubMergeViewModel
    @Binding var dropActive: Bool
    let availableWidth: CGFloat
    let height: CGFloat

    var body: some View {
        let layout = VideoTableLayout(availableWidth: availableWidth)

        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                TableColumns(layout: layout) {
                    header("序号", width: layout.indexWidth, alignment: .center)
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
        .background(.white)
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
            guard !viewModel.isOperationLocked else { return false }
            return viewModel.handleDroppedItems(providers)
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

struct VideoRowView: View {
    let item: VideoItem
    @ObservedObject var viewModel: SubMergeViewModel
    let layout: VideoTableLayout

    var body: some View {
        let isBusy = viewModel.isOperationLocked

        TableColumns(layout: layout) {
            Text("\(item.index)")
                .font(.system(size: 13, weight: .medium))
                .frame(width: layout.indexWidth, alignment: .center)
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
            .help(item.videoURL.lastPathComponent)

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
                        .foregroundStyle(isBusy ? Color.secondary : (item.subtitleURL == nil ? Color.blue : Color.black.opacity(0.82)))
                        .underline(!isBusy && item.subtitleURL == nil, color: .blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help(item.subtitleURL?.lastPathComponent ?? "点击选择字幕")
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
                .help(item.subtitleURL?.lastPathComponent ?? "点击选择字幕")
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
                .disabled(isBusy)
                .opacity(isBusy ? 0.38 : 1)
                CircleIconButton(systemName: "text.viewfinder", size: layout.actionIconSize, helpText: "预览字幕效果") {
                    viewModel.showPreview(for: item.id)
                }
                .disabled(isBusy)
                .opacity(isBusy ? 0.38 : 1)
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
                .disabled(isBusy)
                .opacity(isBusy ? 0.38 : 1)
            }
            .frame(width: layout.actionsWidth, alignment: .leading)
        }
    }
}

struct VideoTableLayout {
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
        max(min(usableWidth * 0.055, 46), 38)
    }

    var durationWidth: CGFloat {
        max(min(usableWidth * 0.085, 82), 68)
    }

    var statusWidth: CGFloat {
        max(min(usableWidth * 0.20, 196), 170)
    }

    var actionsWidth: CGFloat {
        max(min(usableWidth * 0.20, 200), 180)
    }

    var actionIconSize: CGFloat {
        actionsWidth < 166 ? 30 : 36
    }

    var actionSpacing: CGFloat {
        actionIconSize < 36 ? 7 : 10
    }

    var removeButtonHorizontalPadding: CGFloat {
        actionIconSize < 36 ? 10 : 12
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
        max(flexibleWidth - subtitleWidth, 210)
    }

    var subtitleWidth: CGFloat {
        min(max(usableWidth * 0.18, 155), 180)
    }
}

struct VideoRowStatusView: View {
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

struct TableColumns<Content: View>: View {
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

struct SettingsPanel: View {
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
                    CompactIconButton(systemName: "terminal", helpText: "检测 FFmpeg") {
                        viewModel.checkFFmpegAvailability()
                    }
                }
            }
            .disabled(viewModel.isOperationLocked)
            .opacity(viewModel.isOperationLocked ? 0.48 : 1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

struct StyleToggle: View {
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

struct FooterBar: View {
    @ObservedObject var viewModel: SubMergeViewModel

    var body: some View {
        HStack {
            Text("共 \(viewModel.items.count) 个文件")
                .font(.system(size: 18))
                .foregroundStyle(.black.opacity(0.76))

            Spacer()

            Button {
                if viewModel.isRendering {
                    viewModel.cancelRendering()
                } else if !viewModel.isCancelling {
                    viewModel.startRenderAll()
                }
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 178, height: 58)
                    .background(
                        LinearGradient(
                            colors: buttonColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isCancelling && !viewModel.isRendering)
            .opacity(viewModel.isCancelling && !viewModel.isRendering ? 0.66 : 1)
            .help(viewModel.isRendering ? "停止当前合成任务" : "开始批量合成")
        }
        .padding(.top, 0)
    }

    private var buttonTitle: String {
        if viewModel.isCancelling { return "取消中..." }
        if viewModel.isRendering { return "取消合成" }
        return "开始合成"
    }

    private var buttonColors: [Color] {
        if viewModel.isRendering || viewModel.isCancelling {
            return [Color(red: 0.92, green: 0.24, blue: 0.22), Color(red: 0.78, green: 0.12, blue: 0.12)]
        }
        return [Color(red: 0.26, green: 0.45, blue: 1.0), Color(red: 0.18, green: 0.35, blue: 0.95)]
    }
}
