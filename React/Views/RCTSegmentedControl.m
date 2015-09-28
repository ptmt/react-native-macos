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
    // TODO:
//    [self addTarget:self action:@selector(didChange)
//               forControlEvents:UIControlEventValueChanged];
  }
  return self;
}

- (void)setValues:(NSArray *)values
{
  _values = [values copy];
  //[self removeSe];
  for (NSString *value in values) {
    //[self insertSegmentWithTitle:value atIndex:self.numberOfSegments animated:NO];
    [self setLabel:value forSegment:self.segmentCount];
  }
  self.selectedIndex = _selectedIndex;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
  _selectedIndex = selectedIndex;
  self.selectedIndex = selectedIndex;
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
