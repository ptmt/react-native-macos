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

#import <AppKit/AppKit.h>
#import <XCTest/XCTest.h>

#import <RCTTest/RCTTestRunner.h>

#import "RCTAssert.h"
#import "RCTRedBox.h"
#import "RCTRootView.h"

@interface UIExplorerSnapshotTests : XCTestCase
{
  RCTTestRunner *_runner;
}

@end

@implementation UIExplorerSnapshotTests

- (void)setUp
{

  NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
<<<<<<< HEAD
  RCTAssert(version.majorVersion == 10 || version.minorVersion >= 10, @"Snapshot tests should be run on OSX 10.10+, found %zd.%zd.%zd", version.majorVersion, version.minorVersion, version.patchVersion);
  _runner = RCTInitRunnerForApp(@"Examples/UIExplorer/UIExplorerApp.osx", nil);
=======
  RCTAssert((version.majorVersion == 8 && version.minorVersion >= 3) || version.majorVersion >= 9, @"Tests should be run on iOS 8.3+, found %zd.%zd.%zd", version.majorVersion, version.minorVersion, version.patchVersion);
  _runner = RCTInitRunnerForApp(@"Examples/UIExplorer/UIExplorerApp.ios", nil);
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d
  _runner.recordMode = NO;
}

#define RCT_TEST(name)                  \
- (void)test##name                      \
{                                       \
  [_runner runTest:_cmd module:@#name]; \
}

<<<<<<< HEAD
//RCT_TEST(ViewExample) // Examples-UIExplorer-UIExplorerApp.ios/testViewExample_1@2x.png
//RCT_TEST(LayoutExample)
//RCT_TEST(TextExample)
//RCT_TEST(SwitchExample)
//RCT_TEST(SliderExample)
//RCT_TEST(TabBarExample)
=======
RCT_TEST(ViewExample)
RCT_TEST(LayoutExample)
RCT_TEST(TextExample)
RCT_TEST(SwitchExample)
//RCT_TEST(SliderExample) // Disabled: #8985988
//RCT_TEST(TabBarExample) // Disabled: #8985988
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d

- (void)testZZZNotInRecordMode
{
  XCTAssertFalse(_runner.recordMode, @"Don't forget to turn record mode back to off");
}

@end
