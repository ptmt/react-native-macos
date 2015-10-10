/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/CVDisplayLink.h>
#import <Foundation/Foundation.h>
#import "RCTFrameUpdate.h"

#import "RCTUtils.h"
#import "AppKit/AppKit.h"

@implementation RCTFrameUpdate

RCT_NOT_IMPLEMENTED(- (instancetype)init)

- (instancetype)initWithTimer:(NSTimer *)timer
{
  if ((self = [super init])) {
    _timestamp = timer.timeInterval;
    _deltaTime = timer.tolerance; // TODO: real duration
  }
  return self;
}

@end
