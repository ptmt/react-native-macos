#import "AppDelegate.h"

#import "RCTBridge.h"
#import "RCTJavaScriptLoader.h"
#import "RCTRootView.h"
#import <Cocoa/Cocoa.h>

@interface AppDelegate() <RCTBridgeDelegate>

@end

@implementation AppDelegate

-(id)init
{
    if(self = [super init]) {
        NSRect contentSize = NSMakeRect(200, 500, 1000, 500); // TODO: should not be hardcoded

        self.window = [[NSWindow alloc] initWithContentRect:contentSize
                                                  styleMask:NSTitledWindowMask | NSResizableWindowMask | NSFullSizeContentViewWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
        NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:self.window];

        [[self window] setTitleVisibility:NSWindowTitleHidden];
        [[self window] setTitlebarAppearsTransparent:YES];
        [[self window] setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];

        [windowController setShouldCascadeWindows:NO];
        [windowController setWindowFrameAutosaveName:@"<%= name %>"];

        [windowController showWindow:self.window];

        // TODO: remove broilerplate
        [self setUpApplicationMenu];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(__unused NSNotification *)aNotification
{

    RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self
                                              launchOptions:nil];

    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge
                                                     moduleName:@"<%= name %>"
                                              initialProperties:nil];



    [self.window setContentView:rootView];
}


- (NSURL *)sourceURLForBridge:(__unused RCTBridge *)bridge
{
    NSURL *sourceURL;

    /**
     * Loading JavaScript code - uncomment the one you want.
     *
     * OPTION 1
     * Load from development server. Start the server from the repository root:
     *
     * $ npm start
     *
     * To run on device, change `localhost` to the IP address of your computer
     * (you can get this by typing `ifconfig` into the terminal and selecting the
     * `inet` value under `en0:`) and make sure your computer and iOS device are
     * on the same Wi-Fi network.
     */

    sourceURL = [NSURL URLWithString:@"http://localhost:8081/index.osx.bundle?platform=osx&dev=true"];

    /**
     * OPTION 2
     * Load from pre-bundled file on disk. To re-generate the static bundle, `cd`
     * to your Xcode project folder and run
     *
     * $ curl 'http://localhost:8081/index.osx.bundle?platform=osx&dev=false&minify=true' -o RNGLDesktop/main.jsbundle
     *
     * then add the `main.jsbundle` file to your project and uncomment this line:
     */

    //sourceURL = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];

#if RUNNING_ON_CI
    sourceURL = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif

    return sourceURL;
}

- (void)loadSourceForBridge:(RCTBridge *)bridge
                  withBlock:(RCTSourceLoadBlock)loadCallback
{
    [RCTJavaScriptLoader loadBundleAtURL:[self sourceURLForBridge:bridge]
                              onComplete:loadCallback];
}


- (void)setUpApplicationMenu
{
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"" ];
    NSMenuItem *containerItem = [[NSMenuItem alloc] init];
    NSMenu *rootMenu = [[NSMenu alloc] initWithTitle:@"" ];
    [containerItem setSubmenu:rootMenu];
    [mainMenu addItem:containerItem];
    [rootMenu addItemWithTitle:@"Quit <%= name %>" action:@selector(terminate) keyEquivalent:@"Q"];

}

- (id)firstResponder
{
    return [self.window firstResponder];
}

@end
