import SwiftUI
import AppKit

@main
struct XVideoDownloaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 560, height: 360)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

struct ContentView: View {
    @State private var urlText = ""
    @State private var isDownloading = false
    @State private var status = "粘贴 x.com 视频地址，然后开始下载。"
    @State private var output = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("X 视频下载")
                        .font(.title2.bold())
                    Text("视频会保存到你的 Downloads 文件夹")
                        .foregroundStyle(.secondary)
                }
            }

            TextField("https://x.com/…/status/…", text: $urlText)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onSubmit { startDownload() }

            HStack {
                Spacer()
                Button("打开 Downloads") { openDownloads() }
                Button {
                    startDownload()
                } label: {
                    if isDownloading {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("下载视频", systemImage: "arrow.down")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDownloading || !isValidXURL)
                .keyboardShortcut(.return, modifiers: .command)
            }

            Divider()

            Text(status)
                .font(.callout.weight(.medium))
                .foregroundStyle(status.hasPrefix("下载完成") ? .green : .primary)

            ScrollView {
                Text(output.isEmpty ? "提示：需要登录的视频会使用 Chrome 中的 X 登录状态。" : output)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 92)
        }
        .padding(24)
    }

    private var isValidXURL: Bool {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host?.lowercased() else { return false }
        return host == "x.com" || host.hasSuffix(".x.com") || host == "twitter.com" || host.hasSuffix(".twitter.com")
    }

    private func startDownload() {
        guard isValidXURL, !isDownloading else { return }
        let input = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        isDownloading = true
        status = "正在下载…"
        output = ""

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Downloader.run(url: input)
            DispatchQueue.main.async {
                isDownloading = false
                output = result.output
                status = result.success
                    ? "下载完成，文件已保存到 Downloads。"
                    : result.message
                if result.success { NSSound(named: "Glass")?.play() }
            }
        }
    }

    private func openDownloads() {
        let folder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        NSWorkspace.shared.open(folder)
    }
}

private enum Downloader {
    struct Result: Sendable {
        let success: Bool
        let message: String
        let output: String
    }

    nonisolated static func run(url: String) -> Result {
        guard let executable = findYTDLP() else {
            return Result(
                success: false,
                message: "未找到 yt-dlp。请先在终端运行：brew install yt-dlp ffmpeg",
                output: "安装完成后重新打开本应用即可。"
            )
        }

        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0].path
        var arguments = [
            "--newline",
            "--no-playlist",
            "--restrict-filenames",
            "--merge-output-format", "mp4",
            "-o", downloads + "/%(title).120s-%(id)s.%(ext)s"
        ]
        arguments += ["--cookies-from-browser", "chrome"]
        arguments.append(url)

        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""
            if process.terminationStatus == 0 {
                return Result(success: true, message: "", output: text)
            }
            return Result(success: false, message: "下载失败，请查看下面的详细信息。", output: text)
        } catch {
            return Result(success: false, message: "无法启动下载工具。", output: error.localizedDescription)
        }
    }

    nonisolated private static func findYTDLP() -> String? {
        let candidates = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
