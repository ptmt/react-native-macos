/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTActivityIndicatorView.h"

@implementation RCTActivityIndicatorView {
}

- (void)setHidden:(BOOL)hidden
{
  [super setHidden: hidden];
}

-(void)workaroundForLayer {
  CALayer *layer = [self layer];
  CALayer *backgroundLayer = [[layer sublayers] firstObject];
  [backgroundLayer setHidden:YES];
}

-(void)layout {
  [self workaroundForLayer];
}

@end
