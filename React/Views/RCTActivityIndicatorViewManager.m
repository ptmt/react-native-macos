/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTActivityIndicatorViewManager.h"

#import "RCTConvert.h"

@implementation RCTConvert (NSProgressIndicator)

// NOTE: It's pointless to support UIActivityIndicatorViewStyleGray
// as we can set the color to any arbitrary value that we want to

//RCT_ENUM_CONVERTER(UIActivityIndicatorViewStyle, (@{
//  @"large": @(UIActivityIndicatorViewStyleWhiteLarge),
//  @"small": @(UIActivityIndicatorViewStyleWhite),
//}), UIActivityIndicatorViewStyleWhiteLarge, integerValue)

@end

@implementation RCTActivityIndicatorViewManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  NSProgressIndicator* indicator = [[NSProgressIndicator alloc] init];
  [indicator setControlSize:NSRegularControlSize];
  [indicator setStyle:NSProgressIndicatorSpinningStyle];
  [indicator setUsesThreadedAnimation:YES];
  [indicator setHidden:YES];
  return indicator;
}

//RCT_EXPORT_VIEW_PROPERTY(color, NSColor) // imlement drawRect
//RCT_EXPORT_VIEW_PROPERTY(hidesWhenStopped, BOOL)
//RCT_REMAP_VIEW_PROPERTY(size, activityIndicatorViewStyle, NSProgressIndicatorSpinningStyle)
RCT_CUSTOM_VIEW_PROPERTY(animating, BOOL, NSProgressIndicator)
{
  //TODO: store animated property because NSProgressIndicator doesn't have a suitable method
  BOOL animating = json ? [RCTConvert BOOL:json] : YES;
  if (animating) {
    [view setHidden:NO];
    [view startAnimation:self];
  } else {
    [view stopAnimation:self];
    [view setHidden:YES];
  }
}



@end
