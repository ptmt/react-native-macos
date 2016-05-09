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
        [[self window] setAutorecalculatesKeyViewLoop:YES];

        [windowController setShouldCascadeWindows:NO];
        [windowController setWindowFrameAutosaveName:@"SimpleChatClient"];

        [windowController showWindow:self.window];

        // TODO: remove broilerplate
        [self setUpApplicationMenu];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSDictionary *)launchOptions
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

#if DEBUG
    sourceURL = [NSURL URLWithString:@"http://localhost:8081/Examples/SimpleChatClient/index.osx.bundle?platform=osx&dev=true"];
#else
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
    [rootMenu addItemWithTitle:@"Quit SimpleChatClient" action:@selector(terminate:) keyEquivalent:@"q"];
    [NSApp setMainMenu:mainMenu];

    [self setUpEditMenu];
}

- (id)firstResponder
{
    return [self.window firstResponder];
}

- (void)setUpEditMenu
{
    NSMenuItem *developerItemContainer = [[NSMenuItem alloc] init];
    NSMenu *developerMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [developerItemContainer setSubmenu:developerMenu];
    [developerMenu setAutoenablesItems:YES];
    [developerMenu addItem:[self addEditMenuItem:@"Cut" action:@selector(cut:) key:@"x" ]];
    [developerMenu addItem:[self addEditMenuItem:@"Copy" action:@selector(copy:) key:@"c" ]];
    [developerMenu addItem:[self addEditMenuItem:@"Paste" action:@selector(paste:) key:@"v" ]];
    [developerMenu addItem:[self addEditMenuItem:@"SelectAll" action:@selector(selectAll:) key:@"a" ]];
    [developerMenu addItem:[self addEditMenuItem:@"Debug Key-view Loop" action:@selector(debug) key:@"D" ]];
    [[NSApp mainMenu] addItem:developerItemContainer];
}

- (NSMenuItem *)addEditMenuItem:(NSString *)title
                         action:(SEL _Nullable)action
                            key:(NSString *)key
{
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    [menuItem setTitle:title];
    [menuItem setEnabled:YES];
    [menuItem setAction:action];
    [menuItem setKeyEquivalent:key];
    return menuItem;
}

- (void)debug
{
    [[self window] recalculateKeyViewLoop];
    [self debugKeyLoop:[self window].contentView];
   //NSView* currentView = (NSView*)[[self window] firstResponder];
    [[self window] selectNextKeyView:self];

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication * __unused)theApplication {
    return YES;
}

- (void)debugKeyLoop:(NSView *)view
{
    if ([view nextValidKeyView]) {
         NSLog(@"has nextValidKeyView: %@ %@", view.className, view.nextValidKeyView.className);
    }

    if ([view subviews] && [view subviews].count > 0) {
        int length = (int) [view subviews].count;
        for (int i=0; i < length; i++) {
            [self debugKeyLoop:view.subviews[i]];
        }
    }
}

@end

