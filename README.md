# SubMergePro

SubMergePro 是一个面向 macOS 的字幕压制工具，用 SwiftUI 重写自早期的 Python 版本。它可以批量导入视频，自动匹配同名字幕，并通过 FFmpeg 将字幕烧录到视频中。

![macOS](https://img.shields.io/badge/macOS-13.0%2B-111111)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 功能

- 批量添加视频文件或整个文件夹
- 自动匹配同名 `.srt` 字幕
- 支持单个视频导出和批量导出
- 可统一设置输出格式、分辨率、码率、帧率和编码器
- 可调整字幕字体、字号、颜色、描边、阴影、位置和背景
- 内置字幕样式预览和视频预览帧
- 导出后可直接打开输出文件位置
- 显示视频时长、分辨率、帧率、码率和文件大小

## 系统要求

- macOS 13.0 或更高版本
- Xcode 16 或更高版本
- FFmpeg

安装 FFmpeg：

```bash
brew install ffmpeg
```

应用会依次查找这些位置：

- 应用包内的 `ffmpeg`
- 当前环境变量 `PATH`
- `/opt/homebrew/bin/ffmpeg`
- `/usr/local/bin/ffmpeg`
- `/usr/bin/ffmpeg`

## 本地运行

用 Xcode 打开：

```bash
open SubMergeProMac.xcodeproj
```

在 Xcode 中选择 `SubMergeProMac` scheme，然后点击运行。

也可以用命令行编译：

```bash
xcodebuild \
  -project SubMergeProMac.xcodeproj \
  -scheme SubMergeProMac \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

Swift Package Manager 也可以用于快速检查源码编译：

```bash
swift build
```

常用命令也可以走 `make`：

```bash
make doctor
make build
make xcode-build
make release
```

## 打包发布

生成 Release 版 `.app`、`.zip`、`.dmg` 和校验文件：

```bash
scripts/build_release.sh
```

输出文件会生成到 `dist/` 目录。

### 签名说明

当前自动构建产物没有使用 Apple Developer ID 签名和公证。第一次打开下载版 app 时，macOS 可能提示无法验证开发者；正式分发前建议接入 Developer ID 签名和 notarization。

完整发布流程见 [docs/RELEASING.md](docs/RELEASING.md)。

## 版本号

版本号由 Xcode 工程中的 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION` 控制，并会写入最终 app 的 `Info.plist`。

更新版本：

```bash
scripts/bump_version.sh 1.1.0
```

指定构建号：

```bash
scripts/bump_version.sh 1.1.0 12
```

推荐发布流程：

```bash
scripts/bump_version.sh 1.1.0
git add .
git commit -m "Release 1.1.0"
git tag v1.1.0
git push origin main --tags
```

推送 `v*.*.*` 标签后，GitHub Actions 会自动构建软件并上传到 GitHub Releases。

## 自动化

仓库包含两条 GitHub Actions 工作流：

- `CI`: push 和 pull request 时自动编译项目
- `Release`: 推送版本标签时自动构建 `.zip`、`.dmg` 并发布到 GitHub Releases

如果想手动从本机发布，先登录 GitHub CLI：

```bash
gh auth login
```

然后执行：

```bash
scripts/publish_release.sh v1.1.0
```

## 项目结构

```text
App/              应用入口和窗口配置
Models/           数据模型和导出配置
Services/         FFmpeg、字幕转换、预览、视频元数据服务
ViewModels/       页面状态和业务流程
Views/            SwiftUI 页面和控件
Resources/        Info.plist、图标和资源
scripts/          本地构建、发版、版本管理脚本
docs/             发布、FFmpeg 和路线图文档
.github/          GitHub Actions 和协作模板
```

## 参与贡献

欢迎提交 issue 和 pull request。提交 PR 前请先确认：

```bash
swift build
xcodebuild -project SubMergeProMac.xcodeproj -scheme SubMergeProMac -configuration Debug -destination 'platform=macOS' build
```

更多约定见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

本项目使用 MIT License，详见 [LICENSE](LICENSE)。
