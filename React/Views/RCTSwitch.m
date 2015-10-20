/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTSwitch.h"

#import "RCTEventDispatcher.h"
#import "NSView+React.h"

@implementation RCTSwitch

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self setButtonType:NSSwitchButton];
    [self setTitle:@""];
    [self setControlSize:NSRegularControlSize];
    [self setStringValue:@""];
  }
  return self;
}

- (void)setOn:(BOOL)on animated:(__unused BOOL)animated {
  _wasOn = on;
  [self setState:on ? 1 : 0];
  //[self setOn:on animated:animated];
}

@end
