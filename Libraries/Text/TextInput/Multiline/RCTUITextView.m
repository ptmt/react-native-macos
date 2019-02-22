/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTUITextView.h"

#import <React/RCTUtils.h>
#import <React/NSView+React.h>

#import "RCTBackedTextInputDelegateAdapter.h"

@implementation RCTUITextView
{
  RCTBackedTextViewDelegateAdapter *_textInputDelegateAdapter;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange)
                                                 name:NSControlTextDidChangeNotification
                                               object:self];

    _textInputDelegateAdapter = [[RCTBackedTextViewDelegateAdapter alloc] initWithTextView:self];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)accessibilityLabel
{
  NSMutableString *accessibilityLabel = [NSMutableString new];

  NSString *superAccessibilityLabel = [super accessibilityLabel];
  if (superAccessibilityLabel.length > 0) {
    [accessibilityLabel appendString:superAccessibilityLabel];
  }

  return accessibilityLabel;
}

#pragma mark - Properties

- (void)textDidChange
{
  _textWasPasted = NO;
}

#pragma mark - Overrides

- (NSString *)text
{
  return self.string;
}

- (void)setText:(NSString *)text
{
  [self setString:text];
  [self textDidChange];
}

- (NSAttributedString *)attributedText
{
  return self.textStorage;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
  [self.textStorage setAttributedString:attributedText];
  [self textDidChange];
}

#pragma mark - Overrides

- (NSRange)selectedTextRange
{
  return self.selectedRange;
}

- (void)setSelectedTextRange:(NSRange)selectedTextRange notifyDelegate:(BOOL)notifyDelegate
{
  if (!notifyDelegate) {
    // We have to notify an adapter that following selection change was initiated programmatically,
    // so the adapter must not generate a notification for it.
    [_textInputDelegateAdapter skipNextTextInputDidChangeSelectionEventWithTextRange:selectedTextRange];
  }
  [super setSelectedRange:selectedTextRange];
}

- (BOOL)becomeFirstResponder
{
  if ([super becomeFirstResponder]) {
    [_textInputDelegateAdapter performSelector:@selector(textViewDidFocus) withObject:nil afterDelay:0.0];
    return YES;
  }
  return NO;
}

- (void)paste:(id)sender
{
  [super paste:sender];
  _textWasPasted = YES;
}

//- (void)setContentOffset:(CGPoint)contentOffset animated:(__unused BOOL)animated
//{
//  // Turning off scroll animation.
//  // This fixes the problem also known as "flaky scrolling".
//  [super setContentOffset:contentOffset animated:NO];
//}

#pragma mark - Padding

- (void)setPaddingInsets:(NSEdgeInsets)paddingInsets
{
  _paddingInsets = paddingInsets;
  self.textContainerInset = (NSSize){paddingInsets.left, paddingInsets.top};
}

@end

@implementation NSTextView (EditingControl)

- (BOOL)endEditing:(BOOL)force
{
  if (self != self.window.firstResponder) {
    return YES;
  }
  if (force || [self.delegate textShouldEndEditing:self]) {
    [self.window makeFirstResponder:nil];
    return YES;
  }
  return NO;
}

@end
