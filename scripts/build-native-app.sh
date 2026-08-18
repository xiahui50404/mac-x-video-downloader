#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_dir="$project_dir/dist/X 视频下载.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
clang -fobjc-arc -fblocks -framework Cocoa "$project_dir/SourcesObjC/main.m" -o "$app_dir/Contents/MacOS/XVideoDownloader"
cp "$project_dir/AppInfo.plist" "$app_dir/Contents/Info.plist"
cp "$project_dir/Assets/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$app_dir"
echo "$app_dir"
