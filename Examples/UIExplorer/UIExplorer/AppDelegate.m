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
#import <AppKit/AppKit.h>

@interface AppDelegate() <RCTBridgeDelegate>

@end

@implementation AppDelegate

-(id)init
{
  if(self = [super init]) {
    NSRect contentSize = NSMakeRect(200, 500, 1000, 500);

    self.window = [[NSWindow alloc] initWithContentRect:contentSize
                                              styleMask:NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:self.window];

//
    [self.window setTitle:@"UIExplorerApp"];
//
    [windowController setShouldCascadeWindows:NO];
    [windowController setWindowFrameAutosaveName:@"UIExplorer"];

    [windowController showWindow:self.window];
//    [self.window makeKeyAndOrderFront:nil];

  }
  return self;
}

- (void)applicationDidFinishLaunching:(__unused NSNotification *)aNotification
{

  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self
                                            launchOptions:nil];

  RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge
                                                   moduleName:@"UIExplorerApp"
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

    sourceURL = [NSURL URLWithString:@"http://localhost:8081/Examples/UIExplorer/UIExplorerApp.osx.bundle?platform=osx&dev=true"];

    /**
     * OPTION 2
     * Load from pre-bundled file on disk. To re-generate the static bundle, `cd`
     * to your Xcode project folder and run
     *
     * $ curl 'http://localhost:8081/Examples/UIExplorer/UIExplorerApp.ios.bundle' -o main.jsbundle
     *
     * then add the `main.jsbundle` file to your project and uncomment this line:
     */

  //  sourceURL = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];

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

@end

