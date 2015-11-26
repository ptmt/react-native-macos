//
//  AppDelegate.m
//  SimpleGmailClient
//
//  Created by Dmitriy Loktev on 10/21/15.
//  Copyright © 2015 Elephant. All rights reserved.
//

/**
 * The examples provided by Facebook are for non-commercial testing and
 * evaluation purposes only.
 *
 * Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 * AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
        [windowController setWindowFrameAutosaveName:@"SimpleChatClient"];

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
                                                     moduleName:@"SimpleChatClient"
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

    sourceURL = [NSURL URLWithString:@"http://localhost:8081/Examples/SimpleChatClient/index.osx.bundle?platform=osx&dev=true"];

    /**
     * OPTION 2
     * Load from pre-bundled file on disk. To re-generate the static bundle, `cd`
     * to your Xcode project folder and run
     *
     * $ curl 'http://localhost:8081/Examples/SimpleChatClient/index.osx.bundle?platform=osx&dev=false&minify=true' -o SimpleChatClient/main.jsbundle
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
    [rootMenu addItemWithTitle:@"Quit SimpleChatClient" action:@selector(terminate) keyEquivalent:@"Q"];
    [NSApp setMainMenu:mainMenu];

    [self setUpEditMenu];
}

- (id)firstResponder
{
    return [self.window firstResponder];
}

- (void)setUpEditMenu
{
//
//    416	  if (![[[NSApp keyWindow] firstResponder] tryToPerform:@selector(cut:) with:nil])
//        417	    if (wbui->get_active_form() && wbui->get_active_form()->can_cut())
    NSMenuItem *developerItemContainer = [[NSMenuItem alloc] init]; //WithTitle:@"Developer" action:nil keyEquivalent:@"d"
    NSMenu *developerMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [developerItemContainer setSubmenu:developerMenu];
    [developerMenu setAutoenablesItems:YES];
    [developerMenu addItem:[self addEditMenuItem:@"Cut" action:@selector(cut:) key:@"x" ]];
    [developerMenu addItem:[self addEditMenuItem:@"Copy" action:@selector(copy:) key:@"c" ]];
    [developerMenu addItem:[self addEditMenuItem:@"Paste" action:@selector(paste:) key:@"v" ]];
    [developerMenu addItem:[self addEditMenuItem:@"SelectAll" action:@selector(selectAll:) key:@"a" ]];
    [[NSApp mainMenu] addItem:developerItemContainer];
}

- (NSMenuItem *)addEditMenuItem:(NSString *)title
                         action:(SEL _Nullable)action
                            key:(NSString *)key
{
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    [menuItem setTitle:title];
    [menuItem setEnabled:YES];
    //[menuItem setTarget:[self.window firstResponder]];
    [menuItem setAction:action];
    [menuItem setKeyEquivalent:key];
    return menuItem;
}

@end

