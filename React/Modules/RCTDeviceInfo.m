/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTDeviceInfo.h"
#import <AppKit/AppKit.h>

//#import "RCTAccessibilityManager.h"
#import "RCTAssert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"

@implementation RCTDeviceInfo {
  id subscription;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;
  
  NSWindow *currentWindow = RCTKeyWindow();
  
  subscription = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResizeNotification
                                                                   object:currentWindow queue:nil usingBlock:^(__unused NSNotification * n){
    [self didReceiveNewContentSizeMultiplier];
  }];
}

static BOOL RCTIsIPhoneX() {
  static BOOL isIPhoneX = NO;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    RCTAssertMainQueue();

    isIPhoneX = NO;
  });

  return isIPhoneX;
}

static NSDictionary *RCTExportedDimensions(__unused RCTBridge *bridge)
{
  RCTAssertMainQueue();

  // Don't use RCTScreenSize since it the interface orientation doesn't apply to it
  CGRect screenSize = [[NSScreen mainScreen] frame];
  NSDictionary *dims = @{
                         @"width": @(screenSize.size.width),
                         @"height": @(screenSize.size.height),
                         @"scale": @(RCTScreenScale()),
                         @"fontScale": @(1) // TODO: fix accessibility bridge.accessibilityManager.multiplier)
                         };
  
  CGRect windowSize = RCTKeyWindow().frame;
  NSDictionary *windowDims = @{
                         @"width": @(windowSize.size.width),
                         @"height": @(windowSize.size.height),
                         @"scale": @(RCTScreenScale()),
                         @"fontScale": @(1) // TODO: fix accessibility bridge.accessibilityManager.multiplier)
                         };
  return @{
           @"window": windowDims,
           @"screen": dims
           };
}

- (void)dealloc
{
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)invalidate
{
  RCTExecuteOnMainQueue(^{
    self->_bridge = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  });
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  return @{
    @"Dimensions": RCTExportedDimensions(_bridge),
  };
}

- (void)didReceiveNewContentSizeMultiplier
{
  RCTBridge *bridge = _bridge;
  RCTExecuteOnMainQueue(^{
    // Report the event across the bridge.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [bridge.eventDispatcher sendDeviceEventWithName:@"didUpdateDimensions"
                                        body:RCTExportedDimensions(bridge)];
#pragma clang diagnostic pop
  });
}

@end
