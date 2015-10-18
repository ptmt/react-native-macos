/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>
#import "RCTBridge.h"
#import "RCTDevLoadingView.h"
#import "RCTDefines.h"
#import "RCTUtils.h"

#if RCT_DEV

static BOOL isEnabled = YES;

@implementation RCTDevLoadingView
{
  NSWindow *_window;
  NSTextField *_label;
  NSDate *_showDate;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

+ (void)setEnabled:(BOOL)enabled
{
  isEnabled = enabled;
}

- (instancetype)init
{
  if ((self = [super init])) {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hide)
                                                 name:RCTJavaScriptDidLoadNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hide)
                                                 name:RCTJavaScriptDidFailToLoadNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;
  [self showWithURL:bridge.bundleURL];
}

- (void)showWithURL:(NSURL *)URL
{
  if (!isEnabled) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{

    _showDate = [NSDate date];
    if (!_window && !RCTRunningInTestEnvironment()) {
      CGFloat screenWidth = [NSScreen mainScreen].frame.size.width;
      _window = [[NSWindow alloc]
                 initWithContentRect:CGRectMake(0, 0, screenWidth, 22)
                 styleMask:0
                 backing:NSBackingStoreBuffered
                 defer:NO];

      _window.backgroundColor = [NSColor blackColor];
      [_window setLevel:NSScreenSaverWindowLevel + 1];

      _label = [[NSTextField alloc] initWithFrame:_window.frame];
      _label.font = [NSFont systemFontOfSize:12.0];
      _label.textColor = [NSColor grayColor];
      [_label setAlignment:NSCenterTextAlignment];

      [_window setContentView:_label];
      [_window makeKeyAndOrderFront:nil];
    }

    NSString *source;
    if (URL.fileURL) {
      source = @"pre-bundled file";
    } else {
      source = [NSString stringWithFormat:@"%@:%@", URL.host, URL.port];
    }

    [_label setStringValue:[NSString stringWithFormat:@"Loading from %@...", source]];
    //_window.hidden = NO;

  });
}

- (void)hide
{
  if (!isEnabled) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{

    const NSTimeInterval MIN_PRESENTED_TIME = 0.6;
    NSTimeInterval presentedTime = [[NSDate date] timeIntervalSinceDate:_showDate];
    NSTimeInterval delay = MAX(0, MIN_PRESENTED_TIME - presentedTime);
    [NSThread sleepForTimeInterval:delay]; // blocking the thread
    CGRect windowFrame = _window.frame;

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.25];
    [_window setFrame: CGRectOffset(windowFrame, 0, -windowFrame.size.height) display:YES animate:YES];
    [NSAnimationContext endGrouping];
    [_window setFrame: windowFrame display:NO animate:YES];
    _window = nil;

  });
}

@end

#else

@implementation RCTDevLoadingView

+ (NSString *)moduleName { return nil; }
+ (void)setEnabled:(BOOL)enabled { }

@end

#endif
