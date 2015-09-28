/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTSlider.h"

@implementation RCTSlider
{
  float _unclippedValue;
}

- (void)setValue:(float)value
{
  _unclippedValue = value;
  [self setDoubleValue:value];
}

- (void)setMinimumValue:(float)minimumValue
{
  self.minValue = minimumValue;
  [self setDoubleValue:_unclippedValue];
}

- (void)setMaximumValue:(float)maximumValue
{
  self.maxValue = maximumValue;
  [self setDoubleValue:_unclippedValue];
}

@end
