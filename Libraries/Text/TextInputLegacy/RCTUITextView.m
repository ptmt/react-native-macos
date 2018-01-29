/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Cocoa/Cocoa.h>
#import "RCTUITextView.h"

#import <React/NSView+React.h>

CGRect UIEdgeInsetsSizeRect(CGRect rect, CGSize insets) {
//  rect.origin.x    += insets.left;
 //  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.width);
  rect.size.height -= (insets.height);
  return rect;
}


@implementation RCTUITextView
{
  NSTextField *_placeholderView;
  NSTextView *_detachedTextView;
}

static NSFont *defaultPlaceholderFont()
{
  return [NSFont systemFontOfSize:17];
}

static NSColor *defaultPlaceholderTextColor()
{
  // Default placeholder color from UITextField.
  return [NSColor colorWithRed:0 green:0 blue:0.0980392 alpha:0.22];
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _placeholderView = [[NSTextField alloc] initWithFrame:self.bounds];
//    _placeholderView.isAccessibilityElement = NO;
//    _placeholderView.numberOfLines = 0;
    [self addSubview:_placeholderView];
  }

  return self;
}


#pragma mark - Properties

- (void)setPlaceholderText:(NSString *)placeholderText
{
  _placeholderText = placeholderText;
  _placeholderView.stringValue = _placeholderText;
}

- (void)setPlaceholderTextColor:(NSColor *)placeholderTextColor
{
  _placeholderTextColor = placeholderTextColor;
  _placeholderView.textColor = _placeholderTextColor ?: defaultPlaceholderTextColor();
}

- (void)textDidChange
{
  _textWasPasted = NO;
  [self invalidatePlaceholderVisibility];
}

#pragma mark - Overrides

- (void)setFont:(NSFont *)font
{
  // [super setFont:font];
  [[super textStorage] setFont:font];
  _placeholderView.font = font ?: defaultPlaceholderFont();
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
  // [super setTextAlignment:textAlignment];
  // _placeholderView.textAlignment = textAlignment;
}

- (void)setText:(NSString *)text
{
  [self setString:text];
  [self textDidChange];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
  [self.textStorage setAttributedString:attributedText];
  [self textDidChange];
}

- (void)paste:(id)sender
{
  [super paste:sender];
  _textWasPasted = YES;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(__unused BOOL)animated
{
  // Turning off scroll animation.
  // This fixes the problem also known as "flaky scrolling".
  // [super setContentOffset:contentOffset animated:NO];
}

#pragma mark - Layout

- (void)layout
{
  [super layout];

  CGRect textFrame = UIEdgeInsetsSizeRect(self.bounds, self.textContainerInset);
  CGFloat placeholderHeight = [_placeholderView sizeThatFits:textFrame.size].height;
  textFrame.size.height = MIN(placeholderHeight, textFrame.size.height);
  _placeholderView.frame = textFrame;
}

- (CGSize)sizeThatFits:(CGSize)size
{
  NSRect rect = [super.layoutManager usedRectForTextContainer:super.textContainer];
  return CGSizeMake(MIN(rect.size.width, size.width), rect.size.height);
}

#pragma mark - Placeholder

- (void)invalidatePlaceholderVisibility
{
  BOOL isVisible = _placeholderText.length != 0 && self.string.length == 0;
  _placeholderView.hidden = !isVisible;
}

@end
