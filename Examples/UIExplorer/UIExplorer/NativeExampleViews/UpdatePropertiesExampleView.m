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

#import "UpdatePropertiesExampleView.h"

#import <React/RCTRootView.h>
#import <React/RCTViewManager.h>

#import "AppDelegate.h"

@interface UpdatePropertiesExampleViewManager : RCTViewManager

@end

@implementation UpdatePropertiesExampleViewManager

RCT_EXPORT_MODULE();

- (NSView *)view
{
  return [UpdatePropertiesExampleView new];
}

@end

@implementation UpdatePropertiesExampleView
{
  RCTRootView *_rootView;
  NSButton *_button;
  BOOL _beige;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    _beige = YES;

    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];

    _rootView = [[RCTRootView alloc] initWithBridge:appDelegate.bridge
                                         moduleName:@"SetPropertiesExampleApp"
                                  initialProperties:@{@"color":@"beige"}];

    _button = [[NSButton alloc] init];
    [_button setTitle:@"Native Button" ];
    //[_button setT:[NSColor whiteColor]];
    //[_button setBackgroundColor:[NSColor grayColor]];

    [_button setTarget:self];
    [_button setAction:@selector(changeColor)];


    [self addSubview:_button];
    [self addSubview:_rootView];
  }
  return self;
}

- (void)layoutSubviews
{
  float spaceHeight = 20;
  float buttonHeight = 40;
  float rootViewWidth = self.bounds.size.width;
  float rootViewHeight = self.bounds.size.height - spaceHeight - buttonHeight;

  [_rootView setFrame:CGRectMake(0, 0, rootViewWidth, rootViewHeight)];
  [_button setFrame:CGRectMake(0, rootViewHeight + spaceHeight, rootViewWidth, buttonHeight)];
}

- (void)changeColor
{
  _beige = !_beige;
  [_rootView setAppProperties:@{@"color":_beige ? @"beige" : @"purple"}];
}

- (NSArray<NSView<RCTComponent> *> *)reactSubviews
{
  // this is to avoid unregistering our RCTRootView when the component is removed from RN hierarchy
  (void)[super reactSubviews];
  return @[];
}

@end
