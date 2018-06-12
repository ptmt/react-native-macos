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
#import <React/RCTUtils.h>

CGRect UIEdgeInsetsSizeRect(CGRect rect, CGSize insets) {
//  rect.origin.x    += insets.left;
 //  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.width);
  rect.size.height -= (insets.height);
  return rect;
}


#import "RCTBackedTextInputDelegateAdapter.h"

@implementation RCTUITextView
{
  NSTextField *_placeholderView;
  NSTextView *_detachedTextView;
  RCTBackedTextViewDelegateAdapter *_textInputDelegateAdapter;
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

    _textInputDelegateAdapter = [[RCTBackedTextViewDelegateAdapter alloc] initWithTextView:self];
  }

  return self;
}


- (NSString *)accessibilityLabel
{
  NSMutableString *accessibilityLabel = [NSMutableString new];

  NSString *superAccessibilityLabel = [super accessibilityLabel];
  if (superAccessibilityLabel.length > 0) {
    [accessibilityLabel appendString:superAccessibilityLabel];
  }

  if (self.placeholder.length > 0 && self.text.length == 0) {
    if (accessibilityLabel.length > 0) {
      [accessibilityLabel appendString:@" "];
    }
    [accessibilityLabel appendString:self.placeholder];
  }

  return accessibilityLabel;
}

#pragma mark - Properties

- (void)setPlaceholder:(NSString *)placeholder
{
  _placeholderText = placeholderText;
  _placeholderView.stringValue = _placeholderText;
}

- (void)setPlaceholderTextColor:(NSColor *)placeholderTextColor
{
  _placeholderColor = placeholderColor;
  _placeholderView.textColor = _placeholderColor ?: defaultPlaceholderColor();
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

#pragma mark - Overrides

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange notifyDelegate:(BOOL)notifyDelegate
{
  if (!notifyDelegate) {
    // We have to notify an adapter that following selection change was initiated programmatically,
    // so the adapter must not generate a notification for it.
    [_textInputDelegateAdapter skipNextTextInputDidChangeSelectionEventWithTextRange:selectedTextRange];
  }

  [super setSelectedTextRange:selectedTextRange];
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

- (CGSize)intrinsicContentSize
{
  // Returning size DOES contain `textContainerInset` (aka `padding`).
  return [self sizeThatFits:CGSizeMake(self.preferredMaxLayoutWidth, INFINITY)];
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
