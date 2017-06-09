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

#import "FlexibleSizeExampleView.h"

#import <React/RCTBridge.h>
#import <React/RCTRootView.h>
#import <React/RCTRootViewDelegate.h>
#import <React/RCTViewManager.h>

#import "AppDelegate.h"

@interface FlexibleSizeExampleViewManager : RCTViewManager

@end

@implementation FlexibleSizeExampleViewManager

RCT_EXPORT_MODULE();

- (NSView *)view
{
  return [FlexibleSizeExampleView new];
}

@end


@interface FlexibleSizeExampleView () <RCTRootViewDelegate>

@end


@implementation FlexibleSizeExampleView
{
  RCTRootView *_resizableRootView;
  NSTextView *_currentSizeTextView;
  BOOL _sizeUpdated;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _sizeUpdated = NO;

    AppDelegate *appDelegate = (AppDelegate*)[NSApplication sharedApplication].delegate;

    _resizableRootView = [[RCTRootView alloc] initWithBridge:appDelegate.bridge
                                                  moduleName:@"RootViewSizeFlexibilityExampleApp"
                                           initialProperties:@{}];

    [_resizableRootView setSizeFlexibility:RCTRootViewSizeFlexibilityHeight];

    _currentSizeTextView = [NSTextView new];
    _currentSizeTextView.editable = NO;
    [_currentSizeTextView setString:@"Resizable view has not been resized yet"];
    _currentSizeTextView.textColor = [NSColor blackColor];
    _currentSizeTextView.backgroundColor = [NSColor whiteColor];
    _currentSizeTextView.font = [NSFont boldSystemFontOfSize:10];

    _resizableRootView.delegate = self;

    [self addSubview:_currentSizeTextView];
    [self addSubview:_resizableRootView];
  }
  return self;
}

- (void)layoutSubviews
{
  float textViewHeight = 60;
  float spacingHeight = 10;
  [_resizableRootView setFrame:CGRectMake(0, textViewHeight + spacingHeight, self.frame.size.width, _resizableRootView.frame.size.height)];
  [_currentSizeTextView setFrame:CGRectMake(0, 0, self.frame.size.width, textViewHeight)];
}


- (NSArray<NSView<RCTComponent> *> *)reactSubviews
{
  // this is to avoid unregistering our RCTRootView when the component is removed from RN hierarchy
  (void)[super reactSubviews];
  return @[];
}


#pragma mark - RCTRootViewDelegate

- (void)rootViewDidChangeIntrinsicSize:(RCTRootView *)rootView
{
  CGRect newFrame = rootView.frame;
  newFrame.size = rootView.intrinsicContentSize;

  if (!_sizeUpdated) {
    _sizeUpdated = TRUE;
    _currentSizeTextView.string = [NSString stringWithFormat:@"RCTRootViewDelegate: content with initially unknown size has appeared, updating root view's size so the content fits."];

  } else {
    _currentSizeTextView.string = [NSString stringWithFormat:@"RCTRootViewDelegate: content size has been changed to (%ld, %ld), updating root view's size.",
                                 (long)newFrame.size.width,
                                 (long)newFrame.size.height];

  }

  rootView.frame = newFrame;
}

@end
