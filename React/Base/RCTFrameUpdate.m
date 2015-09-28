/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/CVDisplayLink.h>

#import "RCTFrameUpdate.h"

#import "RCTUtils.h"

@implementation RCTFrameUpdate

RCT_NOT_IMPLEMENTED(- (instancetype)init)

- (instancetype)initWithDisplayLink:(CVDisplayLinkRef)displayLink
{
  if ((self = [super init])) {
    _timestamp =  CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLink);
//    _deltaTime = displayLink.duration;
  }
  return self;
}

@end
