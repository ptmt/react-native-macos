/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTPicker.h"

#import "RCTConvert.h"
#import "RCTUtils.h"
#import "NSView+React.h"

@interface RCTPicker() <NSComboBoxDataSource, NSComboBoxDelegate>

@end

@implementation RCTPicker

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _color = [NSColor blackColor];
    _font = [NSFont systemFontOfSize:21]; // TODO: selected title default should be 23.5
    _selectedIndex = NSNotFound;
    _textAlign = NSTextAlignmentCenter;
    self.delegate = self;
    self.usesDataSource = YES;
    [self setDataSource:self];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (void)setItems:(NSArray<NSDictionary *> *)items
{
  _items = [items copy];
  [self layout];
}

- (BOOL)usesDataSource
{
  return YES;
}

- (void)selectItemAt:(NSInteger)selectedIndex
{
  if (_selectedIndex != selectedIndex) {
    //BOOL animated = _selectedIndex != NSNotFound; // Don't animate the initial value
    _selectedIndex = selectedIndex;
    dispatch_async(dispatch_get_main_queue(), ^{
      [self selectItemAtIndex:selectedIndex];
    });
  }
}

//#pragma mark - UIPickerViewDataSource protocol
//
- (NSInteger)numberOfItemsInComboBox:(__unused NSComboBox *)theComboBox
{
  return _items.count;
}

- (id)comboBox:(__unused NSComboBox *)aComboBox
objectValueForItemAtIndex:(NSInteger)index
{
  return _items[index][@"label"];
}

- (void)comboBoxSelectionDidChange:(__unused NSNotification *)notification
{
  _selectedIndex = [self indexOfSelectedItem];
  if (_onChange) {
    _onChange(@{
                @"newIndex": @(_selectedIndex),
                @"newValue": _items[_selectedIndex][@"value"]
                });
  }
}

@end
