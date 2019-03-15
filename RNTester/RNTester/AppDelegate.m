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
#import <Cocoa/Cocoa.h>

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTJavaScriptLoader.h>
#import <React/RCTLinkingManager.h>
#import <React/RCTRootView.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTWindow.h>

@interface AppDelegate() <RCTBridgeDelegate, NSSearchFieldDelegate>

@end


@implementation AppDelegate
{
  NSToolbar *_toolbar;
}

- (void)applicationDidFinishLaunching:(NSNotification * __unused)aNotification
{
  [self setDefaultURL];

  _bridge = [[RCTBridge alloc] initWithDelegate:self
                                  launchOptions:@{@"argv": [self argv]}];

  _window = [[RCTWindow alloc] initWithBridge:_bridge
                                  contentRect:NSMakeRect(200, 500, 1000, 500)
                                    styleMask:(NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask)
                                        defer:NO];

  _window.title = @"RNTester";
  _window.titleVisibility = NSWindowTitleHidden;

  [self setUpToolbar];
  [self setUpMainMenu];

  _window.contentView = [[RCTRootView alloc] initWithBridge:_bridge
                                                 moduleName:@"RNTesterApp"
                                          initialProperties:nil];

  [_window makeKeyAndOrderFront:nil];
}

- (void)setDefaultURL
{
  _sourceURL = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"RNTester/js/RNTesterApp.macos"
                                                        fallbackResource:nil];
}

- (void)resetBridgeToDefault
{
  [self setDefaultURL];
  [_bridge reload];
}


- (NSURL *)sourceURLForBridge:(__unused RCTBridge *)bridge
{
  return _sourceURL;
}

- (void)loadSourceForBridge:(RCTBridge *)bridge
                 onProgress:(RCTSourceLoadProgressBlock)onProgress
                 onComplete:(RCTSourceLoadBlock)loadCallback
{
  [RCTJavaScriptLoader loadBundleAtURL:[self sourceURLForBridge:bridge]
                            onProgress:onProgress
                            onComplete:loadCallback];
}

- (void)setUpToolbar
{
  NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
  toolbar.delegate = self;
  toolbar.sizeMode = NSToolbarSizeModeRegular;
  _window.toolbar = toolbar;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(__unused NSToolbar *)toolbar
{
  return @[NSToolbarFlexibleSpaceItemIdentifier, @"searchBar", NSToolbarFlexibleSpaceItemIdentifier, @"resetButton"];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(__unused NSToolbar *)toolbar
{
  return @[NSToolbarFlexibleSpaceItemIdentifier, @"searchBar", NSToolbarFlexibleSpaceItemIdentifier, @"resetButton"];
}

- (NSToolbarItem *)toolbar:(NSToolbar * __unused)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL __unused)flag {

  if ([itemIdentifier isEqualToString:@"searchBar"]) {
    NSSearchField *searchField = [[NSSearchField alloc] init];
    [searchField setFrameSize:NSMakeSize(400, searchField.intrinsicContentSize.height)];
    [searchField setDelegate:self];
    [searchField setRecentsAutosaveName:@"mainSearchField"];
    [searchField setPlaceholderString:@"Search Example"];
    [searchField setAction:@selector(searchURLorQuery:)];
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setView:searchField];
    return item;
  }

  if ([itemIdentifier isEqualToString:@"resetButton"]) {
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 50, 33)];
    [button setBezelStyle:NSRoundedBezelStyle];
    [button setImage:[NSImage imageNamed:NSImageNameRefreshTemplate]];
    [button setTarget:self];
    [button setAction:@selector(resetBridgeToDefault)];
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setView:button];
    [item setAction:@selector(resetBridgeToDefault)];

    return item;
  }
  return nil;

}

- (IBAction)searchURLorQuery:(id)sender {
  if ([[sender stringValue] containsString:@"http"]) {
    _sourceURL =[NSURL URLWithString:[sender stringValue]];
    _bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:nil];
    NSString * moduleName = [_sourceURL.lastPathComponent stringByReplacingOccurrencesOfString:@".macos.bundle" withString:@""];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:_bridge
                                                     moduleName:moduleName
                                              initialProperties:nil];
    [self.window setContentView:rootView];
  } else {
    [_bridge.eventDispatcher sendDeviceEventWithName:@"onSearchExample"
                                                body:@{@"query": [sender stringValue]}
     ];
  }
}

- (void) setUpMainMenu
{
  NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"" ];
  NSMenuItem *containerItem = [[NSMenuItem alloc] init];
  NSMenu *rootMenu = [[NSMenu alloc] initWithTitle:@"" ];
  [containerItem setSubmenu:rootMenu];
  [mainMenu addItem:containerItem];
  [rootMenu addItemWithTitle:@"Quit UIExplorer" action:@selector(terminate:) keyEquivalent:@"q"];
  [NSApp setMainMenu:mainMenu];

  NSMenuItem *editItemContainer = [[NSMenuItem alloc] init];
  NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
  [editItemContainer setSubmenu:editMenu];
  [editMenu setAutoenablesItems:NO];
  [editMenu addItem:[self addEditMenuItem:@"Undo" action:@selector(undo) key:@"z" ]];
  [editMenu addItem:[self addEditMenuItem:@"Redo" action:@selector(redo) key:@"Z" ]];
  [editMenu addItem:[self addEditMenuItem:@"Cut" action:@selector(cut:) key:@"x" ]];
  [editMenu addItem:[self addEditMenuItem:@"Copy" action:@selector(copy:) key:@"c" ]];
  [editMenu addItem:[self addEditMenuItem:@"Paste" action:@selector(paste:) key:@"v" ]];
  [editMenu addItem:[self addEditMenuItem:@"SelectAll" action:@selector(selectAll:) key:@"a" ]];
  [[NSApp mainMenu] addItem:editItemContainer];
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

- (void)undo
{
  [[[self window] undoManager] undo];
}

- (void)redo
{
  [[[self window] undoManager] redo];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication * __unused)theApplication {
  return YES;
}

@end
