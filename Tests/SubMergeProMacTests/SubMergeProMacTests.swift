import AVFoundation
import Foundation
import Testing
@testable import SubMergeProMac

@Suite("Subtitle conversion")
struct SubtitleConversionTests {
    @Test
    func convertsSRTToASSWithDialogueLines() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let srtURL = directory.appendingPathComponent("sample.srt")
        let assURL = directory.appendingPathComponent("sample.ass")
        try """
        1
        00:00:01,000 --> 00:00:03,500
        第一行字幕
        第二行字幕

        2
        00:00:04,000 --> 00:00:05,000
        结束
        """.write(to: srtURL, atomically: true, encoding: .utf8)

        try SRTConverter.convertToASS(srtURL: srtURL, assURL: assURL, appearance: SubtitleAppearance())
        let output = try String(contentsOf: assURL, encoding: .utf8)

        #expect(output.contains("[V4+ Styles]"))
        #expect(output.contains("Dialogue: 0,00:00:01.00,00:00:03.50"))
        #expect(output.contains("第一行字幕\\N第二行字幕"))
    }
}

@Suite("Formatting")
struct FormattingTests {
    @Test
    func formatsDurationAndFileSize() {
        #expect(VideoMetadataService.format(duration: CMTime(seconds: 3661, preferredTimescale: 600)) == "01:01:01")
        #expect(VideoMetadataService.formatFileSize(1_048_576) == "1.00 MB")
        #expect(VideoMetadataService.formatFileSize(1_073_741_824) == "1.00 GB")
    }

    @Test
    func parsesFFmpegProgress() {
        let line = "frame=  200 fps=0.0 q=28.0 size=1024kB time=00:00:05.00 bitrate=1677.7kbits/s speed=1.2x"
        #expect(ProgressParser.parse(line: line, totalDuration: 10) == 0.5)
        #expect(ProgressParser.parse(line: line, totalDuration: 0) == nil)
    }
}

@Suite("Subtitle style")
struct SubtitleStyleTests {
    @Test
    func buildsASSStyleFromAppearance() {
        var appearance = SubtitleAppearance()
        appearance.fontName = "Helvetica Neue"
        appearance.fontSize = 42
        appearance.isBold = true
        appearance.textColorHex = "#3366CC"

        let style = SubtitleStyleBuilder.makeASSStyle(from: appearance)

        #expect(style.contains("Helvetica Neue"))
        #expect(style.contains(",42,"))
        #expect(style.contains(",-1,"))
    }
}
