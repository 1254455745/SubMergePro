import SwiftUI

struct SubtitlePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SubMergeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(viewModel.previewItem == nil ? "样式预览" : "视频字幕预览")
                    .font(.system(size: 26, weight: .bold))
                Spacer()
                if viewModel.previewItem == nil {
                    CapsuleTextButton(title: "重新渲染") {
                        viewModel.renderStylePreviewFrame()
                    }
                    .disabled(viewModel.isOperationLocked)
                    .opacity(viewModel.isOperationLocked ? 0.45 : 1)
                }
                SheetCloseButton {
                    dismiss()
                }
            }

            previewImageView
                .frame(width: 1080, height: 608)
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
                    .disabled(viewModel.isOperationLocked)
                    .opacity(viewModel.isOperationLocked ? 0.45 : 1)
                    .onChange(of: viewModel.previewTime) { _ in
                        viewModel.scheduleLivePreviewRender(delayNanoseconds: 120_000_000)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("当前字幕文本")
                        .font(.system(size: 16, weight: .medium))
                    Text(previewSubtitleText)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(44)
        .frame(minWidth: 1180, minHeight: viewModel.previewItem == nil ? 740 : 860)
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
                Color(red: 0.96, green: 0.98, blue: 1.0),
                Color(red: 0.60, green: 0.80, blue: 0.95),
                Color(red: 1.0, green: 0.82, blue: 0.67)
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
