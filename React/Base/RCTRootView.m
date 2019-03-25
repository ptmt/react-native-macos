/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTRootView.h"
#import "RCTRootViewDelegate.h"
#import "RCTRootViewInternal.h"

#import <objc/runtime.h>

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTBridge+Private.h"
#import "RCTEventDispatcher.h"
#import "RCTKeyCommands.h"
#import "RCTLog.h"
#import "RCTPerformanceLogger.h"
#import "RCTProfile.h"
#import "RCTRootContentView.h"
#import "RCTTouchHandler.h"
#import "RCTUIManager.h"
#import "RCTUIManagerUtils.h"
#import "RCTUtils.h"
#import "RCTView.h"
#import "NSView+React.h"

#if TARGET_OS_TV
#import "RCTTVRemoteHandler.h"
#import "RCTTVNavigationEventEmitter.h"
#endif

NSString *const RCTContentDidAppearNotification = @"RCTContentDidAppearNotification";

@interface RCTUIManager (RCTRootView)

- (NSNumber *)allocateRootTag;

@end

@implementation RCTRootView
{
  RCTBridge *_bridge;
  NSString *_moduleName;
  RCTRootContentView *_contentView;
  BOOL _passThroughTouches;
  CGSize _intrinsicContentSize;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
                    moduleName:(NSString *)moduleName
             initialProperties:(NSDictionary *)initialProperties
{
  RCTAssertMainQueue();
  RCTAssert(bridge, @"A bridge instance is required to create an RCTRootView");
  RCTAssert(moduleName, @"A moduleName is required to create an RCTRootView");

  RCT_PROFILE_BEGIN_EVENT(RCTProfileTagAlways, @"-[RCTRootView init]", nil);
  if (!bridge.isLoading) {
    [bridge.performanceLogger markStartForTag:RCTPLTTI];
  }

  // TODO: Turn on layer backing just to avoid https://github.com/ptmt/react-native-macos/issues/47
  // Maybe we could turn it off after the bug fixed in the future.
  if (([self window].styleMask & NSFullSizeContentViewWindowMask) != NSFullSizeContentViewWindowMask
        && [self window].contentView == self) {
        [self setWantsLayer:YES];
  }

  if (self = [super initWithFrame:CGRectZero]) {
    self.backgroundColor = [NSColor clearColor];

    [self setNeedsLayout:NO];

    _bridge = bridge;
    _moduleName = moduleName;
    _appProperties = [initialProperties copy];
    _loadingViewFadeDelay = 0.25;
    _loadingViewFadeDuration = 0.25;
    _sizeFlexibility = RCTRootViewSizeFlexibilityNone;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bridgeDidReload)
                                                 name:RCTJavaScriptWillStartLoadingNotification
                                               object:_bridge];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(javaScriptDidLoad:)
                                                 name:RCTJavaScriptDidLoadNotification
                                               object:_bridge];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideLoadingView)
                                                 name:RCTContentDidAppearNotification
                                               object:self];

#if TARGET_OS_TV
    self.tvRemoteHandler = [RCTTVRemoteHandler new];
    for (NSString *key in [self.tvRemoteHandler.tvRemoteGestureRecognizers allKeys]) {
      [self addGestureRecognizer:self.tvRemoteHandler.tvRemoteGestureRecognizers[key]];
    }
#endif

    [self showLoadingView];

    // Immediately schedule the application to be started.
    // (Sometimes actual `_bridge` is already batched bridge here.)
    [self bundleFinishedLoading:([_bridge batchedBridge] ?: _bridge)];
  }

  RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"");

  return self;
}

- (instancetype)initWithBundleURL:(NSURL *)bundleURL
                       moduleName:(NSString *)moduleName
                initialProperties:(NSDictionary *)initialProperties
                    launchOptions:(NSDictionary *)launchOptions
{
  RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL:bundleURL
                                            moduleProvider:nil
                                             launchOptions:launchOptions];

  return [self initWithBridge:bridge moduleName:moduleName initialProperties:initialProperties];
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

#if TARGET_OS_TV
- (UIView *)preferredFocusedView
{
  if (self.reactPreferredFocusedView) {
    return self.reactPreferredFocusedView;
  }
  return [super preferredFocusedView];
}
#endif

- (void)viewDidMoveToWindow
{
  [super viewDidMoveToWindow];
  NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                              options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect
                                                                owner:self
                                                             userInfo:nil];

  [self addTrackingArea:trackingArea];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
  [[_contentView touchHandler] mouseMoved:theEvent];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
  [super.layer setBackgroundColor:[backgroundColor CGColor]];
}

#pragma mark - passThroughTouches

- (BOOL)passThroughTouches
{
  return _contentView.passThroughTouches;
}

- (void)setPassThroughTouches:(BOOL)passThroughTouches
{
  _passThroughTouches = passThroughTouches;
  _contentView.passThroughTouches = passThroughTouches;
}

#pragma mark - Layout

- (CGSize)sizeThatFits:(CGSize)size
{
  CGSize fitSize = _intrinsicContentSize;
  CGSize currentSize = self.bounds.size;

  // Following the current `size` and current `sizeFlexibility` policy.
  fitSize = CGSizeMake(
      _sizeFlexibility & RCTRootViewSizeFlexibilityWidth ? fitSize.width : currentSize.width,
      _sizeFlexibility & RCTRootViewSizeFlexibilityHeight ? fitSize.height : currentSize.height
    );

  // Following the given size constraints.
  fitSize = CGSizeMake(
      MIN(size.width, fitSize.width),
      MIN(size.height, fitSize.height)
    );

  return fitSize;
}

- (void)layout
{
  [super layout];
  _contentView.frame = self.bounds;
}

- (NSViewController *)reactViewController
{
  return _reactViewController ?: [super reactViewController];
}

- (BOOL)canBecomeFirstResponder
{
  return YES;
}

- (BOOL)isFlipped
{
  return NO;
}

- (void)setLoadingView:(NSView *)loadingView
{
  _loadingView = loadingView;
  if (!_contentView.contentHasAppeared) {
    [self showLoadingView];
  }
}

- (void)showLoadingView
{
  if (_loadingView && !_contentView.contentHasAppeared) {
    _loadingView.hidden = NO;
    [self addSubview:_loadingView];
  }
}

- (void)hideLoadingView
{
  if (_loadingView.superview == self && _contentView.contentHasAppeared) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_loadingViewFadeDelay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

      _loadingView.hidden = YES;
    });
  }
}

- (NSNumber *)reactTag
{
  RCTAssertMainQueue();
  if (!super.reactTag) {
    /**
     * Every root view that is created must have a unique react tag.
     * Numbering of these tags goes from 1, 11, 21, 31, etc
     *
     * NOTE: Since the bridge persists, the RootViews might be reused, so the
     * react tag must be re-assigned every time a new UIManager is created.
     */
    self.reactTag = RCTAllocateRootViewTag();
  }
  return super.reactTag;
}

- (void)bridgeDidReload
{
  RCTAssertMainQueue();
  // Clear the reactTag so it can be re-assigned
  self.reactTag = nil;
}

- (void)javaScriptDidLoad:(NSNotification *)notification
{
  RCTAssertMainQueue();

  // Use the (batched) bridge that's sent in the notification payload, so the
  // RCTRootContentView is scoped to the right bridge
  RCTBridge *bridge = notification.userInfo[@"bridge"];
  if (bridge != _contentView.bridge) {
    [self bundleFinishedLoading:bridge];
  }
}

- (void)bundleFinishedLoading:(RCTBridge *)bridge
{
  RCTAssert(bridge != nil, @"Bridge cannot be nil");
  if (!bridge.valid) {
    return;
  }

  NSViewController *rootController = [NSViewController new];
  rootController.view = self;
  _reactViewController = rootController;

  [_contentView removeFromSuperview];
  _contentView = [[RCTRootContentView alloc] initWithFrame:self.bounds
                                                    bridge:bridge
                                                  reactTag:self.reactTag
                                            sizeFlexiblity:_sizeFlexibility];
  [self runApplication:bridge];

  _contentView.passThroughTouches = _passThroughTouches;
  [self addSubview:_contentView];

  if (_sizeFlexibility == RCTRootViewSizeFlexibilityNone) {
    self.intrinsicContentSize = self.bounds.size;
  }
}

- (void)runApplication:(RCTBridge *)bridge
{
  NSString *moduleName = _moduleName ?: @"";
  NSDictionary *appParameters = @{
    @"rootTag": _contentView.reactTag,
    @"initialProps": _appProperties ?: @{},
  };

  RCTLogInfo(@"Running application %@ (%@)", moduleName, appParameters);
  [bridge enqueueJSCall:@"AppRegistry"
                 method:@"runApplication"
                   args:@[moduleName, appParameters]
             completion:NULL];
}

- (void)setSizeFlexibility:(RCTRootViewSizeFlexibility)sizeFlexibility
{
  if (_sizeFlexibility == sizeFlexibility) {
    return;
  }

  _sizeFlexibility = sizeFlexibility;
  [self setNeedsLayout:YES];
  _contentView.sizeFlexibility = _sizeFlexibility;
}

- (NSView *)hitTest:(CGPoint)point
{
  // The root view itself should never receive touches
  NSView *hitView = [super hitTest:point];
  if (self.passThroughTouches && hitView == self) {
    return nil;
  }
  return hitView;
}

- (void)setAppProperties:(NSDictionary *)appProperties
{
  RCTAssertMainQueue();

  if ([_appProperties isEqualToDictionary:appProperties]) {
    return;
  }

  _appProperties = [appProperties copy];

  if (_contentView && _bridge.valid && !_bridge.loading) {
    [self runApplication:_bridge];
  }
}

- (void)setIntrinsicContentSize:(CGSize)intrinsicContentSize
{
  BOOL oldSizeHasAZeroDimension = _intrinsicContentSize.height == 0 || _intrinsicContentSize.width == 0;
  BOOL newSizeHasAZeroDimension = intrinsicContentSize.height == 0 || intrinsicContentSize.width == 0;
  BOOL bothSizesHaveAZeroDimension = oldSizeHasAZeroDimension && newSizeHasAZeroDimension;

  BOOL sizesAreEqual = CGSizeEqualToSize(_intrinsicContentSize, intrinsicContentSize);

  _intrinsicContentSize = intrinsicContentSize;

  [self invalidateIntrinsicContentSize];
  [self.superview setNeedsLayout: YES];

  // Don't notify the delegate if the content remains invisible or its size has not changed
  if (bothSizesHaveAZeroDimension || sizesAreEqual) {
    return;
  }

  [_delegate rootViewDidChangeIntrinsicSize:self];
}

- (CGSize)intrinsicContentSize
{
  return _intrinsicContentSize;
}

- (void)contentViewInvalidated
{
  [_contentView removeFromSuperview];
  _contentView = nil;
  [self showLoadingView];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_contentView invalidate];
}

- (void)cancelTouches
{
  [[_contentView touchHandler] cancel];
}

@end

@implementation RCTRootView (Deprecated)

- (CGSize)intrinsicSize
{
  RCTLogWarn(@"Calling deprecated `[-RCTRootView intrinsicSize]`.");
  return self.intrinsicContentSize;
}

@end
