/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTDevLoadingView.h"

#import <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>
#import "RCTBridge.h"
#import "RCTDefines.h"
#import "RCTModalHostViewController.h"
#import "RCTUtils.h"


#if RCT_DEV

static BOOL isEnabled = YES;

@implementation RCTDevLoadingView
{
  NSWindow *_window;
  NSTextField *_label;
  NSView *_back;
  NSDate *_showDate;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

+ (void)setEnabled:(BOOL)enabled
{
  isEnabled = enabled;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(hide)
                                               name:RCTJavaScriptDidLoadNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(hide)
                                               name:RCTJavaScriptDidFailToLoadNotification
                                             object:nil];

  if (bridge.loading) {
    [self showWithURL:bridge.bundleURL];
  }
}

RCT_EXPORT_METHOD(showMessage:(NSString *)message color:(NSColor *)color backgroundColor:(NSColor *)backgroundColor)
{
  if (!isEnabled) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    _showDate = [NSDate date];
    if (!_window && !RCTRunningInTestEnvironment()) {
      CGFloat screenWidth = [NSScreen mainScreen].frame.size.width;
      _window = [[NSWindow alloc]
                 initWithContentRect:CGRectMake(0, 0, screenWidth, 50)
                 styleMask:0
                 backing:NSBackingStoreBuffered
                 defer:NO];

      CGRect frame = _window.frame;
      frame.origin.y = -10;
      [_window setOpaque:YES];
      [_window setAlphaValue:0.9];
      [_window setBackgroundColor:backgroundColor];
      [_window setLevel:NSScreenSaverWindowLevel + 1];

      _label = [[NSTextField alloc] initWithFrame:frame];
      _label.font = [NSFont systemFontOfSize:22.0];
      _label.textColor = color;
      _label.bordered = NO;
      _label.editable = NO;
      _label.selectable = NO;
      [_label setBackgroundColor:[NSColor clearColor]];
      [_label setAlignment:NSCenterTextAlignment];
      _back = [[NSView alloc] initWithFrame:_window.frame];
      [_back.layer setBackgroundColor:[backgroundColor CGColor]];
      [_back addSubview:_label];
      [_window setContentView:_back];
      [_window makeKeyAndOrderFront:nil];
    }


    [_label setStringValue:message];
    //[_label setTextColor:color];
    [_label setBackgroundColor:backgroundColor];
    [_back.layer setBackgroundColor:[backgroundColor CGColor]];

  });
}

RCT_EXPORT_METHOD(hide)
{
  if (!isEnabled) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    const NSTimeInterval MIN_PRESENTED_TIME = 0.6;
    NSTimeInterval presentedTime = [[NSDate date] timeIntervalSinceDate:self->_showDate];
    NSTimeInterval delay = MAX(0, MIN_PRESENTED_TIME - presentedTime);
    [NSThread sleepForTimeInterval:delay]; // blocking the thread
    CGRect windowFrame = _window.frame;

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.35];
    [[_window animator] setFrame: CGRectOffset(windowFrame, 0, -windowFrame.size.height) display:YES animate:YES];
    [NSAnimationContext endGrouping];
    
    _window = nil;
    

  });
}

- (void)showWithURL:(NSURL *)URL
{
  NSColor *color;
  NSColor *backgroundColor;
  NSString *source;
  if (URL.fileURL) {
    color = [NSColor grayColor];
    backgroundColor = [NSColor blackColor];
    source = @"pre-bundled file";
  } else {
    color = [NSColor whiteColor];
    backgroundColor = [NSColor colorWithHue:1./3 saturation:1 brightness:.35 alpha:1];
    source = [NSString stringWithFormat:@"%@:%@", URL.host, URL.port];
  }

  [self showMessage:[NSString stringWithFormat:@"Loading from %@...", source]
              color:color
    backgroundColor:backgroundColor];
}

- (void)updateProgress:(RCTLoadingProgress *)progress
{
  if (!progress) {
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
      [_label setStringValue:[progress description]];
  });
}

- (void)invalidate
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [_window setFrame: CGRectOffset(_window.frame, 0, -_window.frame.size.height) display:NO animate:NO];
    _window = nil;
  });
}

@end

#else

@implementation RCTDevLoadingView

+ (NSString *)moduleName { return nil; }
+ (void)setEnabled:(BOOL)enabled { }
- (void)showWithURL:(NSURL *)URL { }
- (void)updateProgress:(RCTLoadingProgress *)progress { }
- (void)hide { }

@end

#endif
