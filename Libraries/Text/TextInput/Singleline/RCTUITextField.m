/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTUITextField.h"

#import <React/RCTUtils.h>
#import <React/NSView+React.h>

#import "RCTBackedTextInputDelegateAdapter.h"

@implementation RCTUITextField {
  RCTBackedTextFieldDelegateAdapter *_textInputDelegateAdapter;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {

    _textInputDelegateAdapter = [[RCTBackedTextFieldDelegateAdapter alloc] initWithTextField:self];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_textDidChange
{
  _textWasPasted = NO;
}

#pragma mark - Properties

- (void)setTextContainerInset:(NSEdgeInsets)textContainerInset
{
  _textContainerInset = textContainerInset;
  [self setNeedsLayout:YES];
}

- (void)setPlaceholder:(NSString *)placeholder
{
  if (placeholder != nil && ![_placeholder isEqual:placeholder]) {
    _placeholder = placeholder;
    [self updatePlaceholder];
  }
}

- (void)setPlaceholderColor:(NSColor *)placeholderColor
{
  _placeholderColor = placeholderColor;
  [self _updatePlaceholder];
}

- (void)_updatePlaceholder
{
  if (self.placeholder == nil) {
    return;
  }

  NSMutableDictionary *attributes = [NSMutableDictionary new];
  if (_placeholderColor) {
    [attributes setObject:_placeholderColor forKey:NSForegroundColorAttributeName];
  }
  
  

  self.placeholderAttributedString = [[NSAttributedString alloc] initWithString:self.placeholder
                                                               attributes:attributes];
}

- (BOOL)isEditable
{
  return self.isEnabled;
}

- (void)setEditable:(BOOL)editable
{
  self.enabled = editable;
}

#pragma mark - Caret Manipulation

//- (CGRect)caretRectForPosition:(UITextPosition *)position
//{
//  if (_caretHidden) {
//    return CGRectZero;
//  }
//
//  return [super caretRectForPosition:position];
//}

#pragma mark - Positioning Overrides

static inline CGRect NSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
  rect.origin.x    += insets.left;
  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.left + insets.right);
  rect.size.height -= (insets.top  + insets.bottom);
  return rect;
}

//- (CGRect)textRectForBounds:(CGRect)bounds
//{
//  return NSEdgeInsetsInsetRect([super textRectForBounds:bounds], _textContainerInset);
//}

//- (CGRect)editingRectForBounds:(CGRect)bounds
//{
//  return [self textRectForBounds:bounds];
//}

#pragma mark - Overrides

- (void)setSelectedTextRange:(NSRange)selectedTextRange
{
  [[super currentEditor] setSelectedRange:selectedTextRange];
  [_textInputDelegateAdapter selectedTextRangeWasSet];
}

- (void)setSelectedTextRange:(NSRange)selectedTextRange notifyDelegate:(BOOL)notifyDelegate
{
  if (!notifyDelegate) {
    // We have to notify an adapter that following selection change was initiated programmatically,
    // so the adapter must not generate a notification for it.
    [_textInputDelegateAdapter skipNextTextInputDidChangeSelectionEventWithTextRange:selectedTextRange];
  }

  [[super currentEditor] setSelectedRange:selectedTextRange];
}

- (void)paste:(id)sender
{
  [[super currentEditor] paste:sender];
  _textWasPasted = YES;
}

#pragma mark - Layout

- (CGSize)contentSize
{
  // Returning size DOES contain `textContainerInset` (aka `padding`).
  return self.intrinsicContentSize;
}

- (CGSize)intrinsicContentSize
{
  // Note: `placeholder` defines intrinsic size for `<TextInput>`.
  NSString *text = self.placeholder ?: @"";
  CGSize size = [text sizeWithAttributes:@{NSFontAttributeName: self.font}];
  size = CGSizeMake(RCTCeilPixelValue(size.width), RCTCeilPixelValue(size.height));
  size.width += _textContainerInset.left + _textContainerInset.right;
  size.height += _textContainerInset.top + _textContainerInset.bottom;
  // Returning size DOES contain `textContainerInset` (aka `padding`).
  return size;
}

- (CGSize)sizeThatFits:(CGSize)size
{
  // All size values here contain `textContainerInset` (aka `padding`).
  CGSize intrinsicSize = self.intrinsicContentSize;
  return CGSizeMake(MIN(size.width, intrinsicSize.width), MIN(size.height, intrinsicSize.height));
}

@end
