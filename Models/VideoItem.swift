import Foundation

enum ProcessingStatus: String, Codable {
    case pending = "待处理"
    case queued = "等待中"
    case processing = "处理中"
    case success = "已完成"
    case failed = "失败"
    case canceled = "已取消"
}

struct VideoRenderOptions: Codable, Equatable {
    var container: String = "MP4"
    var resolution: String = "原始"
    var bitrate: String = "原始"
    var frameRate: String = "原始"
    var codec: String = "H.264"
    var outputDirectory: String = "\(NSHomeDirectory())/Movies/SubMergePro"
}

struct SubtitleAppearance: Codable, Equatable {
    var presetName: String = "默认样式"
    var fontName: String = "PingFang SC"
    var fontSize: Int = 54
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var textColorHex: String = "#FFFFFF"
    var textOpacity: Int = 100
    var outlineEnabled: Bool = true
    var outlineColorHex: String = "#3B3B53"
    var outlineOpacity: Int = 90
    var outlineWidth: Int = 2
    var shadowEnabled: Bool = true
    var shadowColorHex: String = "#07080E"
    var shadowOpacity: Int = 50
    var shadowDistance: Int = 3
    var shadowBlur: Int = 3
    var backgroundEnabled: Bool = false
    var backgroundColorHex: String = "#000000"
    var backgroundOpacity: Int = 20
    var backgroundPaddingX: Int = 10
    var backgroundPaddingY: Int = 0
    var scaleX: Int = 100
    var scaleY: Int = 100
    var letterSpacing: Int = 0
    var rotation: Int = 0
    var marginLeft: Int = 0
    var marginRight: Int = 0
    var marginVertical: Int = 80
    var alignment: String = "底部居中"
}

struct VideoItem: Identifiable, Hashable {
    let id: UUID
    var index: Int
    var videoURL: URL
    var subtitleURL: URL?
    var durationText: String
    var durationSeconds: Double
    var status: ProcessingStatus
    var progress: Double
    var container: String
    var fileSizeText: String
    var resolutionText: String
    var frameRateText: String
    var bitrateText: String
    var outputURL: URL?
    var lastError: String?

    init(
        id: UUID = UUID(),
        index: Int,
        videoURL: URL,
        subtitleURL: URL?,
        durationText: String = "--:--:--",
        durationSeconds: Double = 0,
        status: ProcessingStatus = .pending,
        progress: Double = 0,
        container: String = "未知",
        fileSizeText: String = "未知",
        resolutionText: String = "未知",
        frameRateText: String = "未知",
        bitrateText: String = "未知",
        outputURL: URL? = nil,
        lastError: String? = nil
    ) {
        self.id = id
        self.index = index
        self.videoURL = videoURL
        self.subtitleURL = subtitleURL
        self.durationText = durationText
        self.durationSeconds = durationSeconds
        self.status = status
        self.progress = progress
        self.container = container
        self.fileSizeText = fileSizeText
        self.resolutionText = resolutionText
        self.frameRateText = frameRateText
        self.bitrateText = bitrateText
        self.outputURL = outputURL
        self.lastError = lastError
    }
}
