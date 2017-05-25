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

#import "RCTAccessibilityManager.h"
#import "RCTAssert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"

@implementation RCTDeviceInfo {
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;
}

static NSDictionary *RCTExportedDimensions(RCTBridge *bridge)
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
  return @{
           @"window": dims,
           @"screen": dims
           };
}

- (void)invalidate
{
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_bridge = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  });
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  NSMutableDictionary<NSString *, NSDictionary *> *constants = [NSMutableDictionary new];
  constants[@"Dimensions"] = RCTExportedDimensions(_bridge);
  return constants;
}

- (void)didReceiveNewContentSizeMultiplier
{
  // Report the event across the bridge.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [_bridge.eventDispatcher sendDeviceEventWithName:@"didUpdateDimensions"
                                              body:RCTExportedDimensions(_bridge)];
#pragma clang diagnostic pop
}

@end
