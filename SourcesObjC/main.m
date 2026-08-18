#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property NSWindow *window;
@property NSTextField *urlField;
@property NSButton *downloadButton;
@property NSTextField *statusLabel;
@property NSTextView *logView;
@end

@implementation AppDelegate

- (void)setupMenus {
    NSMenu *mainMenu = [NSMenu new];

    NSMenuItem *appMenuItem = [NSMenuItem new];
    [mainMenu addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"X 视频下载"];
    [appMenu addItemWithTitle:@"退出 X 视频下载" action:@selector(terminate:) keyEquivalent:@"q"];
    appMenuItem.submenu = appMenu;

    NSMenuItem *editMenuItem = [NSMenuItem new];
    [mainMenu addItem:editMenuItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"编辑"];
    [editMenu addItemWithTitle:@"剪切" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"复制" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"粘贴" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"全选" action:@selector(selectAll:) keyEquivalent:@"a"];
    editMenuItem.submenu = editMenu;

    NSApp.mainMenu = mainMenu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self setupMenus];
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 560, 350)
                                               styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                                                 backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"X 视频下载";
    [self.window center];

    NSView *view = self.window.contentView;
    NSTextField *title = [NSTextField labelWithString:@"X 视频下载"];
    title.font = [NSFont boldSystemFontOfSize:24];
    title.frame = NSMakeRect(24, 295, 500, 32);
    [view addSubview:title];

    NSTextField *subtitle = [NSTextField labelWithString:@"粘贴视频地址，文件会保存到你的 Downloads 文件夹"];
    subtitle.textColor = NSColor.secondaryLabelColor;
    subtitle.frame = NSMakeRect(24, 270, 500, 20);
    [view addSubview:subtitle];

    self.urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(24, 222, 512, 32)];
    self.urlField.placeholderString = @"https://x.com/…/status/…";
    self.urlField.font = [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightRegular];
    [view addSubview:self.urlField];

    NSButton *openButton = [NSButton buttonWithTitle:@"打开 Downloads" target:self action:@selector(openDownloads:)];
    openButton.frame = NSMakeRect(24, 174, 140, 30);
    [view addSubview:openButton];

    self.downloadButton = [NSButton buttonWithTitle:@"下载视频" target:self action:@selector(download:)];
    self.downloadButton.bezelStyle = NSBezelStyleRounded;
    self.downloadButton.keyEquivalent = @"\r";
    self.downloadButton.frame = NSMakeRect(414, 174, 122, 30);
    [view addSubview:self.downloadButton];

    self.statusLabel = [NSTextField labelWithString:@"准备就绪"];
    self.statusLabel.font = [NSFont boldSystemFontOfSize:13];
    self.statusLabel.frame = NSMakeRect(24, 138, 512, 20);
    [view addSubview:self.statusLabel];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(24, 24, 512, 100)];
    scroll.hasVerticalScroller = YES;
    scroll.borderType = NSBezelBorder;
    self.logView = [[NSTextView alloc] initWithFrame:scroll.bounds];
    self.logView.editable = NO;
    self.logView.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
    self.logView.string = @"需要登录的视频会使用 Chrome 中的 X 登录状态。";
    scroll.documentView = self.logView;
    [view addSubview:scroll];

    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }

- (void)openDownloads:(id)sender {
    NSURL *downloads = [[[NSFileManager defaultManager] URLsForDirectory:NSDownloadsDirectory inDomains:NSUserDomainMask] firstObject];
    [[NSWorkspace sharedWorkspace] openURL:downloads];
}

- (void)download:(id)sender {
    NSString *url = [self.urlField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSURL *parsed = [NSURL URLWithString:url];
    NSString *host = parsed.host.lowercaseString;
    if (!([host isEqualToString:@"x.com"] || [host hasSuffix:@".x.com"] || [host isEqualToString:@"twitter.com"] || [host hasSuffix:@".twitter.com"])) {
        self.statusLabel.stringValue = @"请输入有效的 x.com 视频帖子地址。";
        return;
    }

    self.downloadButton.enabled = NO;
    self.statusLabel.stringValue = @"正在下载…";
    self.logView.string = @"正在连接 x.com…";

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            NSString *tool = nil;
            for (NSString *path in @[@"/opt/homebrew/bin/yt-dlp", @"/usr/local/bin/yt-dlp", @"/usr/bin/yt-dlp"]) {
                if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) { tool = path; break; }
            }
            if (!tool) {
                [self finish:NO status:@"未找到 yt-dlp，请先安装下载组件。" log:@"请打开终端运行：brew install yt-dlp ffmpeg"];
                return;
            }

            NSString *downloads = [[[[NSFileManager defaultManager] URLsForDirectory:NSDownloadsDirectory inDomains:NSUserDomainMask] firstObject] path];
            NSMutableArray *args = [@[@"--newline", @"--no-playlist", @"--restrict-filenames", @"--merge-output-format", @"mp4", @"-o", [downloads stringByAppendingPathComponent:@"%(title).120s-%(id)s.%(ext)s"]] mutableCopy];
            [args addObjectsFromArray:@[@"--cookies-from-browser", @"chrome"]];
            [args addObject:url];

            NSTask *task = [NSTask new];
            NSPipe *pipe = [NSPipe pipe];
            task.executableURL = [NSURL fileURLWithPath:tool];
            task.arguments = args;
            task.standardOutput = pipe;
            task.standardError = pipe;
            NSError *error = nil;
            if (![task launchAndReturnError:&error]) {
                [self finish:NO status:@"无法启动下载工具。" log:error.localizedDescription];
                return;
            }
            [task waitUntilExit];
            NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
            NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
            [self finish:(task.terminationStatus == 0)
                   status:(task.terminationStatus == 0 ? @"下载完成，已保存到 Downloads。" : @"下载失败，请查看详细信息。")
                      log:text];
        }
    });
}

- (void)finish:(BOOL)success status:(NSString *)status log:(NSString *)log {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadButton.enabled = YES;
        self.statusLabel.stringValue = status;
        self.statusLabel.textColor = success ? NSColor.systemGreenColor : NSColor.labelColor;
        self.logView.string = log;
        if (success) [[NSSound soundNamed:@"Glass"] play];
    });
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
