import AVFoundation
import Foundation

struct VideoMetadata {
    let durationText: String
    let durationSeconds: Double
    let container: String
    let fileSizeText: String
    let resolutionText: String
    let frameRateText: String
    let bitrateText: String
}

enum VideoMetadataService {
    static func loadMetadata(for url: URL) async -> VideoMetadata {
        let asset = AVURLAsset(url: url)
        let duration = (try? await asset.load(.duration)) ?? .zero
        let tracks = (try? await asset.loadTracks(withMediaType: .video)) ?? []
        let firstTrack = tracks.first
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Double($0) } ?? 0
        let ext = url.pathExtension.isEmpty ? "未知" : url.pathExtension.uppercased()

        var resolution = "未知"
        var frameRate = "未知"
        var bitrate = "未知"

        if let firstTrack {
            let naturalSize = (try? await firstTrack.load(.naturalSize)) ?? .zero
            let preferredTransform = (try? await firstTrack.load(.preferredTransform)) ?? .identity
            let transformed = naturalSize.applying(preferredTransform)
            resolution = "\(Int(abs(transformed.width)))x\(Int(abs(transformed.height)))"

            let fps = (try? await firstTrack.load(.nominalFrameRate)) ?? 0
            if fps > 0 {
                frameRate = String(format: "%.0f fps", fps)
            }

            let estimatedRate = (try? await firstTrack.load(.estimatedDataRate)) ?? 0
            if estimatedRate > 0 {
                bitrate = String(format: "%.0f kbps", estimatedRate / 1000)
            }
        }

        return VideoMetadata(
            durationText: format(duration: duration),
            durationSeconds: max(duration.seconds, 0),
            container: ext,
            fileSizeText: formatFileSize(size),
            resolutionText: resolution,
            frameRateText: frameRate,
            bitrateText: bitrate
        )
    }

    static func format(duration: CMTime) -> String {
        let totalSeconds = max(Int(duration.seconds.rounded()), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func formatFileSize(_ bytes: Double) -> String {
        guard bytes > 0 else { return "未知" }
        let mb = bytes / 1024 / 1024
        if mb >= 1024 {
            return String(format: "%.2f GB", mb / 1024)
        }
        return String(format: "%.2f MB", mb)
    }
}
