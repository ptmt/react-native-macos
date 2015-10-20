/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTSegmentedControl.h"

#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "NSView+React.h"

@implementation RCTSegmentedControl

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _selectedIndex = self.selectedIndex;
    [self setSegmentStyle:NSSegmentStyleRounded];
    // TODO:

//    [self addTarget:self action:@selector(didChange)
//               forControlEvents:UIControlEventValueChanged];
  }
  return self;
}

- (void)setValues:(NSArray *)values
{
  _values = [values copy];
  self.segmentCount = values.count;
  for (NSUInteger i = 0; i < values.count; i++) {
    //[self insertSegmentWithTitle:value atIndex:self.numberOfSegments animated:NO];
    [self setLabel:[values objectAtIndex:i] forSegment:i];
  }
  self.selectedIndex = _selectedIndex;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
  _selectedIndex = selectedIndex;
  [super setSelectedSegment:selectedIndex];
}

- (BOOL)isFlipped
{
  return YES;
}

- (void)didChange
{
  _selectedIndex = self.selectedIndex;
  if (_onChange) {
    _onChange(@{
      @"value": [self labelForSegment:_selectedIndex],
      @"selectedSegmentIndex": @(_selectedIndex)
    });
  }
}

@end
