/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTDatePickerManager.h"

#import "RCTBridge.h"
#import "RCTDatePicker.h"
#import "RCTEventDispatcher.h"
#import "NSView+React.h"

@implementation RCTConvert(NSDatePicker)

RCT_ENUM_CONVERTER(NSDatePickerMode, (@{
  @"single": @(NSSingleDateMode),
  @"range": @(NSRangeDateMode),
}), NSSingleDateMode, integerValue)

@end

@implementation RCTDatePickerManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  return [RCTDatePicker new];
}

RCT_REMAP_VIEW_PROPERTY(date, dateValue, NSDate)
RCT_REMAP_VIEW_PROPERTY(minimumDate, minDate, NSDate)
RCT_REMAP_VIEW_PROPERTY(maximumDate, maxDate, NSDate)
RCT_EXPORT_VIEW_PROPERTY(minuteInterval, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)
RCT_REMAP_VIEW_PROPERTY(mode, datePickerMode, NSDatePickerMode)
RCT_REMAP_VIEW_PROPERTY(timeZoneOffsetInMinutes, timeZone, NSTimeZone)

- (NSDictionary *)constantsToExport
{
  NSDatePicker *view = [NSDatePicker new];
  return @{
    @"ComponentHeight": @(view.intrinsicContentSize.height),
    @"ComponentWidth": @(view.intrinsicContentSize.width),
  };
}

@end
