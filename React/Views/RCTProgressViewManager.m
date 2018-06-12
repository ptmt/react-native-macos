/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTProgressViewManager.h"

#import "RCTConvert.h"

@implementation RCTConvert (RCTProgressViewManager)

//RCT_ENUM_CONVERTER(UIProgressViewStyle, (@{
//  @"default": @(UIProgressViewStyleDefault),
//  @"bar": @(UIProgressViewStyleBar),
//}), UIProgressViewStyleDefault, integerValue)

@end

@implementation RCTProgressViewManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  NSProgressIndicator *indicator = [NSProgressIndicator new];
  [indicator setMinValue:0.0];
  [indicator setMaxValue:1.0];
  [indicator startAnimation:nil];
  [indicator setIndeterminate:NO];
  return indicator;

}

RCT_REMAP_VIEW_PROPERTY(progressTintColor, controlTint, NSColor)

//RCT_EXPORT_VIEW_PROPERTY(trackTintColor, NSColor)
//RCT_EXPORT_VIEW_PROPERTY(progressImage, NSImage)
//RCT_EXPORT_VIEW_PROPERTY(trackImage, NSImage)
RCT_CUSTOM_VIEW_PROPERTY(progress, BOOL, NSProgressIndicator)
{
  if (json) {
    double progress = [json doubleValue];//NSNumber[RCTConvert double:json];
    view.doubleValue = progress;
  } else {
    view.doubleValue = defaultView.doubleValue;
  }
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  NSProgressIndicator *view = [NSProgressIndicator new];
  return @{
    @"ComponentHeight": @(view.intrinsicContentSize.height),
  };
}

@end
