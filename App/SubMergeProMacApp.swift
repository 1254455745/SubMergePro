import AppKit
import SwiftUI

@main
struct SubMergeProMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = SubMergeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .background(WindowConfigurator())
        }
        .defaultSize(width: 1196, height: 768)
        .windowStyle(.hiddenTitleBar)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        FFmpegService.terminateActiveRenderProcess()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowConfiguratorView {
        WindowConfiguratorView()
    }

    func updateNSView(_ nsView: WindowConfiguratorView, context: Context) {}
}

private final class WindowConfiguratorView: NSView {
    private var didApplyInitialSize = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowConfiguration()
    }

    override func layout() {
        super.layout()
        applyWindowConfiguration()
    }

    private func applyWindowConfiguration() {
        guard let window else { return }

        window.isOpaque = true
        window.backgroundColor = .white

        let minimumSize = NSSize(width: 1196, height: 768)
        if window.minSize != minimumSize {
            window.minSize = minimumSize
        }

        guard !didApplyInitialSize else { return }
        didApplyInitialSize = true

        let targetSize = NSSize(width: 1196, height: 768)
        window.setContentSize(targetSize)
        window.center()
    }
}
