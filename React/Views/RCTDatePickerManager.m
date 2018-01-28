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

RCT_ENUM_CONVERTER(NSDatePickerStyle, (@{
  @"textField": @(NSTextFieldDatePickerStyle),
  @"clockAndCalendar": @(NSClockAndCalendarDatePickerStyle),
  @"textFieldAndStepper": @(NSTextFieldAndStepperDatePickerStyle),
}), NSTextFieldAndStepperDatePickerStyle, integerValue)

@end

@implementation RCTDatePickerManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  return [RCTDatePicker new];
}

RCT_EXPORT_VIEW_PROPERTY(date, NSDate)
RCT_EXPORT_VIEW_PROPERTY(locale, NSLocale)
RCT_EXPORT_VIEW_PROPERTY(minimumDate, NSDate)
RCT_EXPORT_VIEW_PROPERTY(maximumDate, NSDate)
RCT_EXPORT_VIEW_PROPERTY(minuteInterval, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(datePickerStyle, NSDatePickerStyle)
RCT_EXPORT_VIEW_PROPERTY(datePickerMode, NSDatePickerMode)
RCT_REMAP_VIEW_PROPERTY(timeZoneOffsetInMinutes, timeZone, NSTimeZone)

- (NSDictionary<NSString *, id> *)constantsToExport
{
  NSDatePicker *view = [NSDatePicker new];
  return @{
    @"ComponentHeight": @(view.intrinsicContentSize.height),
    @"ComponentWidth": @(view.intrinsicContentSize.width),
  };
}

@end
