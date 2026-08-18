# X 视频下载（macOS）

一个极简的原生 macOS 小程序：粘贴 x.com / twitter.com 视频地址，保存到系统 Downloads 文件夹。

## 使用

1. 安装下载依赖：`brew install yt-dlp ffmpeg`
2. 双击 `dist/X 视频下载.app`（已生成，可直接使用）
3. 粘贴视频地址并点击“下载视频”

如果 macOS 首次阻止打开，请在 Finder 中右键应用，选择“打开”。应用会使用 Chrome 中的 X 登录状态。

## 重新构建

无需 Xcode 的原生版本：`./scripts/build-native-app.sh`

SwiftUI 源码版本：`./scripts/build-app.sh`
