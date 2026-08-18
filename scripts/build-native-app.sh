#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_dir="$project_dir/dist/X 视频下载.app"

if [[ ! -f "$project_dir/Assets/AppIcon.icns" ]]; then
  iconset="$project_dir/Assets/AppIcon.iconset"
  mkdir -p "$iconset"
  base64 -D "$project_dir/Assets/AppIcon-256.png.b64" > "$project_dir/Assets/AppIcon-source.png"
  sips -z 16 16 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_16x16.png" >/dev/null
  sips -z 32 32 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_32x32.png" >/dev/null
  sips -z 64 64 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_128x128.png" >/dev/null
  sips -z 256 256 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_128x128@2x.png" >/dev/null
  cp "$project_dir/Assets/AppIcon-source.png" "$iconset/icon_256x256.png"
  sips -z 512 512 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$project_dir/Assets/AppIcon-source.png" --out "$iconset/icon_512x512@2x.png" >/dev/null
  python3 "$project_dir/scripts/make_icns.py"
fi

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
clang -fobjc-arc -fblocks -framework Cocoa "$project_dir/SourcesObjC/main.m" -o "$app_dir/Contents/MacOS/XVideoDownloader"
cp "$project_dir/AppInfo.plist" "$app_dir/Contents/Info.plist"
cp "$project_dir/Assets/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$app_dir"
echo "$app_dir"
