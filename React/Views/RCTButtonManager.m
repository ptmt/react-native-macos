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
#import "RCTFont.h"

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
  if ([NSButton methodSignatureForSelector: @selector(buttonWithTitle:target:action:)]) {
    RCTButton *button = [RCTButton buttonWithTitle:@"Button" target:nil action:nil];
    [button setTarget:button];
    [button setAction:@selector(onPressHandler:)];

    return button;
  } else {
    return [RCTButton new];
  }

}

RCT_EXPORT_VIEW_PROPERTY(title, NSString)
RCT_EXPORT_VIEW_PROPERTY(alternateTitle, NSString)
RCT_EXPORT_VIEW_PROPERTY(toolTip, NSString)
RCT_EXPORT_VIEW_PROPERTY(bezelStyle, NSBezelStyle)
RCT_EXPORT_VIEW_PROPERTY(image, NSImage)
RCT_EXPORT_VIEW_PROPERTY(alternateImage, NSImage)
RCT_EXPORT_VIEW_PROPERTY(onPress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(allowsMixedState, BOOL)
RCT_EXPORT_VIEW_PROPERTY(state, NSInteger)
RCT_CUSTOM_VIEW_PROPERTY(fontSize, NSNumber, RCTButton)
{
  view.font = [RCTFont updateFont:view.font withSize:json ?: @(defaultView.font.pointSize)];
}
RCT_CUSTOM_VIEW_PROPERTY(fontWeight, NSString, __unused RCTButton)
{
  view.font = [RCTFont updateFont:view.font withWeight:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontStyle, NSString, __unused RCTButton)
{
  view.font = [RCTFont updateFont:view.font withStyle:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontFamily, NSString, RCTButton)
{
  view.font = [RCTFont updateFont:view.font withFamily:json ?: defaultView.font.familyName];
}

RCT_CUSTOM_VIEW_PROPERTY(type, NSButtonType, __unused NSButton)
{
  if (json) {
    [view setButtonType:[RCTConvert NSButtonType:json]];
  }
}

RCT_CUSTOM_VIEW_PROPERTY(systemImage, NSString, __unused NSButton)
{
  if (json) {
    [view setImage:[NSImage imageNamed:json]];
  }
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  NSButton *view = (NSButton *)[self view];
  if (view.frame.size.width > 0) {
    return @{
            @"ComponentHeight": @(view.frame.size.height),
            @"ComponentWidth": @(view.frame.size.width)
            };
  } else {
    return @{
             @"ComponentHeight": @(view.intrinsicContentSize.height),
             @"ComponentWidth": @(view.intrinsicContentSize.width)
             };
  }

}

@end
