/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTSegmentedControlManager.h"

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTSegmentedControl.h"

@implementation RCTSegmentedControlManager

// TODO: add styling

//NSSegmentStyleAutomatic = 0,
//NSSegmentStyleRounded = 1,
//NSSegmentStyleTexturedRounded = 2,
//NSSegmentStyleRoundRect = 3,
//NSSegmentStyleTexturedSquare = 4,
//NSSegmentStyleCapsule = 5,
//NSSegmentStyleSmallSquare = 6,
//NSSegmentStyleSeparated = 8,

RCT_EXPORT_MODULE()

- (NSView *)view
{
  return [RCTSegmentedControl new];
}

RCT_EXPORT_VIEW_PROPERTY(values, NSStringArray)
RCT_EXPORT_VIEW_PROPERTY(selectedIndex, NSInteger)
//RCT_EXPORT_VIEW_PROPERTY(momentary, BOOL)
RCT_EXPORT_VIEW_PROPERTY(enabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)
RCT_CUSTOM_VIEW_PROPERTY(tintColor, NSColor, __unused RCTSegmentedControl)
{
  //[view.cell setControlTint:[RCTConvert NSColor:json]];
}

//- (NSDictionary *)constantsToExport
//{
//  RCTSegmentedControl *view = [RCTSegmentedControl new];
//  return @{
//    @"ComponentHeight": @(view.height),
//  };
//}

@end
