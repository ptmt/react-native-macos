/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTRootView.h"

#import <objc/runtime.h>

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "RCTKeyCommands.h"
#import "RCTLog.h"
#import "RCTPerformanceLogger.h"
#import "RCTSourceCode.h"
//#import "RCTTouchHandler.h"
#import "RCTUIManager.h"
#import "RCTUtils.h"
#import "RCTView.h"
#import "RCTWebViewExecutor.h"
#import "NSView+React.h"

NSString *const RCTContentDidAppearNotification = @"RCTContentDidAppearNotification";

@interface RCTBridge (RCTRootView)

@property (nonatomic, weak, readonly) RCTBridge *batchedBridge;

@end

@interface RCTUIManager (RCTRootView)

- (NSNumber *)allocateRootTag;

@end

@interface RCTRootContentView : RCTView <RCTInvalidating>

@property (nonatomic, readonly) BOOL contentHasAppeared;

- (instancetype)initWithFrame:(CGRect)frame bridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

@end

@implementation RCTRootView
{
  RCTBridge *_bridge;
  NSString *_moduleName;
  NSDictionary *_launchOptions;
  RCTRootContentView *_contentView;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
                    moduleName:(NSString *)moduleName
             initialProperties:(NSDictionary *)initialProperties
{
  RCTAssertMainThread();
  RCTAssert(bridge, @"A bridge instance is required to create an RCTRootView");
  RCTAssert(moduleName, @"A moduleName is required to create an RCTRootView");

  if ((self = [super initWithFrame:CGRectZero])) {

    self.backgroundColor = [NSColor whiteColor];

    _bridge = bridge;
    _moduleName = moduleName;
    _initialProperties = [initialProperties copy];
    _loadingViewFadeDelay = 0.25;
    _loadingViewFadeDuration = 0.25;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(javaScriptDidLoad:)
                                                 name:RCTJavaScriptDidLoadNotification
                                               object:_bridge];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideLoadingView)
                                                 name:RCTContentDidAppearNotification
                                               object:self];
    if (!_bridge.loading) {
      [self bundleFinishedLoading:_bridge.batchedBridge];
    }

    [self showLoadingView];
  }
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

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
  NSLog(@"RCTRootView: setBackgroundColor");
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[backgroundColor CGColor]]; //RGB plus Alpha Channel
  [super setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
  [super setLayer:viewLayer];

  [_contentView setWantsLayer:YES];
  [_contentView setLayer:viewLayer];
}

- (NSViewController *)reactViewController
{
  return _reactViewController ?: [super reactViewController];
}

- (BOOL)canBecomeFirstResponder
{
  return YES;
}

- (void)setLoadingView:(NSView *)loadingView
{
  NSLog(@"RCTRootView: setLoadingView");
  _loadingView = loadingView;
  if (!_contentView.contentHasAppeared) {
    [self showLoadingView];
  }
}

- (void)showLoadingView
{
  if (_loadingView && !_contentView.contentHasAppeared) {
    NSLog(@"RCTRootView: showLoadingView");
    _loadingView.hidden = NO;
    [self addSubview:_loadingView];
  }
}

- (void)hideLoadingView
{
  if (_loadingView.superview == self && _contentView.contentHasAppeared) {

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_loadingViewFadeDelay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

//
//      [NSView transitionWithView:self
//                        duration:_loadingViewFadeDuration
//                         options:UIViewAnimationOptionTransitionCrossDissolve
//                      animations:^{
//                        _loadingView.hidden = YES;
//                      } completion:^(__unused BOOL finished) {
//                        [_loadingView removeFromSuperview];
//                      }];
    });
  }
}

- (void)javaScriptDidLoad:(NSNotification *)notification
{
  RCTAssertMainThread();
  RCTBridge *bridge = notification.userInfo[@"bridge"];
  [self bundleFinishedLoading:bridge];
}

- (void)bundleFinishedLoading:(RCTBridge *)bridge
{
  if (!bridge.valid) {
    return;
  }

  [_contentView removeFromSuperview];
  _contentView = [[RCTRootContentView alloc] initWithFrame:self.bounds bridge:bridge];
  //_contentView.backgroundColor = self.backgroundColor;
  [self addSubview:_contentView positioned:NSWindowAbove relativeTo:nil];

  NSString *moduleName = _moduleName ?: @"";
  NSDictionary *appParameters = @{
    @"rootTag": _contentView.reactTag,
    @"initialProps": _initialProperties ?: @{},
  };

  [bridge enqueueJSCall:@"AppRegistry.runApplication"
                   args:@[moduleName, appParameters]];
}

- (void)layoutSubviews
{
//  [super layoutSubviews];
//  _contentView.frame = self.bounds;
//  _loadingView.center = (CGPoint){
//    CGRectGetMidX(self.bounds),
//    CGRectGetMidY(self.bounds)
//  };
}

- (NSNumber *)reactTag
{
  return _contentView.reactTag;
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

@end

@implementation RCTUIManager (RCTRootView)

- (NSNumber *)allocateRootTag
{
  NSNumber *rootTag = objc_getAssociatedObject(self, _cmd) ?: @1;
  objc_setAssociatedObject(self, _cmd, @(rootTag.integerValue + 10), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return rootTag;
}

@end

@implementation RCTRootContentView
{
  __weak RCTBridge *_bridge;
 // RCTTouchHandler *_touchHandler;
  NSColor *_backgroundColor;
}

- (instancetype)initWithFrame:(CGRect)frame
                       bridge:(RCTBridge *)bridge
{
  if ((self = [super initWithFrame:frame])) {
    _bridge = bridge;
    [self setUp];
    self.frame = frame;
    self.layer.backgroundColor = NULL;
  }
  return self;
}

RCT_NOT_IMPLEMENTED(-(instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(-(instancetype)initWithCoder:(nonnull NSCoder *)aDecoder)

- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(NSInteger)atIndex
{
  [super insertReactSubview:subview atIndex:atIndex];
  RCTPerformanceLoggerEnd(RCTPLTTI);
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!_contentHasAppeared) {
      _contentHasAppeared = YES;
      [[NSNotificationCenter defaultCenter] postNotificationName:RCTContentDidAppearNotification
                                                          object:self.superview];
    }
  });
}

- (void)setFrame:(CGRect)frame
{
  super.frame = frame;
  if (self.reactTag && _bridge.isValid) {
    [_bridge.uiManager setFrame:frame forView:self];
  }
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
  _backgroundColor = backgroundColor;
  if (self.reactTag && _bridge.isValid) {
    [_bridge.uiManager setBackgroundColor:backgroundColor forRootView:self];
  }
}

- (NSColor *)backgroundColor
{
  return _backgroundColor;
}

- (void)setUp
{
  /**
   * Every root view that is created must have a unique react tag.
   * Numbering of these tags goes from 1, 11, 21, 31, etc
   *
   * NOTE: Since the bridge persists, the RootViews might be reused, so now
   * the react tag is assigned every time we load new content.
   */
  self.reactTag = [_bridge.uiManager allocateRootTag];
 // [self addGestureRecognizer:[[RCTTouchHandler alloc] initWithBridge:_bridge]];
  [_bridge.uiManager registerRootView:self];
}

- (void)invalidate
{
  //if (self.userInteractionEnabled) {
  //  self.userInteractionEnabled = NO;
    [(RCTRootView *)self.superview contentViewInvalidated];
    [_bridge enqueueJSCall:@"ReactNative.unmountComponentAtNodeAndRemoveContainer"
                      args:@[self.reactTag]];
  //}
}

@end
