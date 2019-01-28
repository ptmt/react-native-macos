/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTSliderManager.h"

#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "RCTSlider.h"
#import "NSView+React.h"

@implementation RCTSliderManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  RCTSlider *slider = [RCTSlider new];
  slider.continuous = YES;
  [slider setTarget:self];
  [slider setAction:@selector(sliderValueChanged:)];
  return slider;
}

- (void)sliderValueChanged:(RCTSlider*)sender {
  float value = sender.floatValue;
  NSEvent *event = [[NSApplication sharedApplication] currentEvent];
  BOOL endingDrag = event.type == NSLeftMouseUp;
  if (!endingDrag) {
    if (sender.onValueChange) {
      sender.onValueChange(@{@"value": @(value)});
    }
  } else {
    if (sender.onSlidingComplete) {
      sender.onSlidingComplete(@{@"value": @(value)});
    }
  }
}

RCT_EXPORT_VIEW_PROPERTY(value, float);
RCT_EXPORT_VIEW_PROPERTY(step, float);
RCT_EXPORT_VIEW_PROPERTY(trackImage, NSImage);
RCT_EXPORT_VIEW_PROPERTY(minimumTrackImage, NSImage);
RCT_EXPORT_VIEW_PROPERTY(maximumTrackImage, NSImage);
RCT_EXPORT_VIEW_PROPERTY(minimumValue, float);
RCT_EXPORT_VIEW_PROPERTY(maximumValue, float);
//RCT_EXPORT_VIEW_PROPERTY(minimumTrackTintColor, NSColor);
//RCT_EXPORT_VIEW_PROPERTY(maximumTrackTintColor, NSColor);
RCT_EXPORT_VIEW_PROPERTY(onValueChange, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onSlidingComplete, RCTBubblingEventBlock);

RCT_CUSTOM_VIEW_PROPERTY(disabled, BOOL, RCTSlider)
{
  if (json) {
    view.enabled = !([RCTConvert BOOL:json]);
  } else {
    view.enabled = defaultView.enabled;
  }
}

@end
