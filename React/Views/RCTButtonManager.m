/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTButtonManager.h"

#import "RCTBridge.h"
#import "RCTButton.h"

@implementation RCTConvert(RCTButton)


RCT_ENUM_CONVERTER(NSButtonType, (@{
     @"momentaryLight": @(NSMomentaryLightButton),
     @"push": @(NSPushOnPushOffButton),
     @"toggle": @(NSToggleButton),
     @"switch": @(NSSwitchButton),
     @"radio": @(NSRadioButton),
     @"momentaryChange": @(NSMomentaryChangeButton),
     @"onOff": @(NSOnOffButton),
     @"momentaryPushInButton": @(NSMomentaryPushInButton),
     @"accelerator": @(NSAcceleratorButton),
     @"multiLevelAccelerator": @(NSMultiLevelAcceleratorButton),
     }), NSMomentaryLightButton, integerValue)

RCT_ENUM_CONVERTER(NSBezelStyle, (@{
      @"rounded": @(NSRoundedBezelStyle),
      @"regularSquare": @(NSRegularSquareBezelStyle),
      @"thickSquare": @(NSThickSquareBezelStyle),
      @"thickerSquare": @(NSThickerSquareBezelStyle),
      @"disclosure": @(NSDisclosureBezelStyle),
      @"shadowlessSquare": @(NSShadowlessSquareBezelStyle),
      @"circular": @(NSCircularBezelStyle),
      @"texturedSquare": @(NSTexturedSquareBezelStyle),
      @"helpButton": @(NSHelpButtonBezelStyle),
      @"smallSquare": @(NSSmallSquareBezelStyle),
      @"texturedRounded": @(NSTexturedRoundedBezelStyle),
      @"roundRect": @(NSRoundRectBezelStyle),
      @"recessed": @(NSRecessedBezelStyle),
      @"roundedDisclosure": @(NSRoundedDisclosureBezelStyle),
      @"inline": @(NSInlineBezelStyle),
      }), NSRoundedBezelStyle, integerValue)

@end

@implementation RCTButtonManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  return [RCTButton new];
}

RCT_EXPORT_VIEW_PROPERTY(title, NSString)
RCT_EXPORT_VIEW_PROPERTY(alternateTitle, NSString)
RCT_EXPORT_VIEW_PROPERTY(toolTip, NSString)
RCT_EXPORT_VIEW_PROPERTY(bezelStyle, NSBezelStyle)
RCT_EXPORT_VIEW_PROPERTY(image, NSImage)
RCT_EXPORT_VIEW_PROPERTY(alternateImage, NSImage)
RCT_EXPORT_VIEW_PROPERTY(onClick, RCTBubblingEventBlock)

RCT_CUSTOM_VIEW_PROPERTY(type, NSButtonType, __unused NSButton)
{
  if (json) {
    [view setButtonType:[RCTConvert NSButtonType:json]];
  }
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  NSButton *view = [NSButton new];
  return @{
           @"ComponentHeight": @(view.intrinsicContentSize.height),
           @"ComponentWidth": @(view.intrinsicContentSize.width)
           };
}

@end
