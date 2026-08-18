#!/usr/bin/env python3
"""Pack PNG icon sizes into an Apple ICNS container (stdlib only)."""
import struct
from pathlib import Path

root = Path(__file__).resolve().parent.parent
iconset = root / "Assets" / "AppIcon.iconset"
entries = [
    (b"icp4", "icon_16x16.png"),
    (b"icp5", "icon_32x32.png"),
    (b"icp6", "icon_32x32@2x.png"),
    (b"ic07", "icon_128x128.png"),
    (b"ic08", "icon_256x256.png"),
    (b"ic09", "icon_512x512.png"),
    (b"ic10", "icon_512x512@2x.png"),
]
chunks = []
for kind, filename in entries:
    data = (iconset / filename).read_bytes()
    chunks.append(kind + struct.pack(">I", len(data) + 8) + data)
body = b"".join(chunks)
(root / "Assets" / "AppIcon.icns").write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
