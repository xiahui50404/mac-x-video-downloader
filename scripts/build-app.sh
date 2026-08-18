#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

swift build -c release

app_dir="$project_dir/dist/X 视频下载.app"
contents="$app_dir/Contents"
mkdir -p "$contents/MacOS" "$contents/Resources"
cp "$project_dir/.build/release/XVideoDownloader" "$contents/MacOS/XVideoDownloader"
cp "$project_dir/AppInfo.plist" "$contents/Info.plist"
chmod +x "$contents/MacOS/XVideoDownloader"
codesign --force --sign - "$app_dir"

echo "$app_dir"
