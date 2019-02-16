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

// The "field editor" is a NSTextView whose delegate is this NSTextField.
@interface NSTextField () <NSTextViewDelegate>
@end

@implementation RCTUITextField {
  RCTBackedTextFieldDelegateAdapter *_textInputDelegateAdapter;
}

@dynamic font, alignment; // NSTextField provides these properties

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_textDidChange)
                                                 name:NSControlTextDidChangeNotification
                                               object:self];

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

- (void)setPaddingInsets:(NSEdgeInsets)paddingInsets
{
  _paddingInsets = paddingInsets;
  [self setNeedsLayout:YES];
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

//- (CGRect)textRectForBounds:(CGRect)bounds
//{
//  return NSEdgeInsetsInsetRect([super textRectForBounds:bounds], _textContainerInset);
//}

//- (CGRect)editingRectForBounds:(CGRect)bounds
//{
//  return [self textRectForBounds:bounds];
//}

#pragma mark - Overrides

- (NSRange)selectedTextRange
{
  return self.currentEditor.selectedRange;
}

- (void)setSelectedTextRange:(NSRange)selectedTextRange notifyDelegate:(BOOL)notifyDelegate
{
  if (!notifyDelegate) {
    // We have to notify an adapter that following selection change was initiated programmatically,
    // so the adapter must not generate a notification for it.
    [_textInputDelegateAdapter skipNextTextInputDidChangeSelectionEventWithTextRange:selectedTextRange];
  }

  self.currentEditor.selectedRange = selectedTextRange;
  [_textInputDelegateAdapter selectedTextRangeWasSet];
}

- (void)paste:(id)sender
{
  [self.currentEditor paste:sender];
  _textWasPasted = YES;
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)range replacementString:(NSString *)string
{
  if ([super textView:textView shouldChangeTextInRange:range replacementString:string]) {
    return [_textInputDelegateAdapter shouldChangeTextInRange:range replacementText:string];
  }
  return NO;
}

- (void)textDidEndEditing:(NSNotification *)notification
{
  [super textDidEndEditing:notification];
  if (self.currentEditor == nil) {
    [_textInputDelegateAdapter textFieldDidBlur];
  }
}

- (BOOL)becomeFirstResponder
{
  if ([super becomeFirstResponder]) {
    [_textInputDelegateAdapter textFieldDidFocus];
    return YES;
  }
  return NO;
}

#pragma mark - RCTBackedTextInputViewProtocol

- (NSString *)text
{
  return self.stringValue;
}

- (void)setText:(NSString *)text
{
  self.stringValue = text;
}

- (NSAttributedString *)attributedText
{
  return self.attributedStringValue;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
  self.attributedStringValue = attributedText;
}

@end
