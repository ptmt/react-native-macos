/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTSinglelineTextInputView.h"

#import <React/RCTBridge.h>

#import "RCTUITextField.h"

@implementation RCTSinglelineTextInputView
{
  RCTUITextField *_backedTextInputView;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  if (self = [super initWithBridge:bridge]) {
    // `blurOnSubmit` defaults to `true` for <TextInput multiline={false}> by design.
    self.blurOnSubmit = YES;

    _backedTextInputView = [[RCTUITextField alloc] initWithFrame:self.bounds];
    _backedTextInputView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _backedTextInputView.textInputDelegate = self;

    [self addSubview:_backedTextInputView];
  }

  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)coder)

- (id<RCTBackedTextInputViewProtocol>)backedTextInputView
{
  return _backedTextInputView;
}

static inline CGRect NSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
  rect.origin.x    += insets.left;
  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.left + insets.right);
  rect.size.height -= (insets.top  + insets.bottom);
  return rect;
}

- (void)setReactBorderInsets:(NSEdgeInsets)reactBorderInsets
{
  // We apply `borderInsets` as `backedTextInputView` layout offset.
  self.backedTextInputView.frame = NSEdgeInsetsInsetRect(self.bounds, reactBorderInsets);

  [super setReactBorderInsets:reactBorderInsets];
}

@end
