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
    _textInputDelegateAdapter = [[RCTBackedTextViewDelegateAdapter alloc] initWithTextView:self];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (NSString *)accessibilityLabel
{
  NSMutableString *accessibilityLabel = [NSMutableString new];

  NSString *superAccessibilityLabel = [super accessibilityLabel];
  if (superAccessibilityLabel.length > 0) {
    [accessibilityLabel appendString:superAccessibilityLabel];
  }

  return accessibilityLabel;
}

- (NSAttributedString *)attributedText
{
  return self.textStorage;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
  [self.textStorage setAttributedString:attributedText];
}

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

#pragma mark - Overrides

- (BOOL)becomeFirstResponder
{
  if ([super becomeFirstResponder]) {
    // Move the cursor to the end of the current text. Note: Mouse clicks override this selection (which is intended).
    self.selectedRange = NSMakeRange(self.textStorage.length, 0);

    [_textInputDelegateAdapter performSelector:@selector(textViewDidFocus) withObject:nil afterDelay:0.0];
    return YES;
  }
  return NO;
}

- (void)keyDown:(NSEvent *)event
{
  // Intercept "tab" key for focus control.
  if (event.keyCode == 48) {
    if (event.modifierFlags & NSShiftKeyMask) {
      [self.window selectPreviousKeyView:nil];
    } else {
      [self.window selectNextKeyView:nil];
    }
  } else {
    [super keyDown:event];
  }
}

- (void)paste:(id)sender
{
  _textWasPasted = YES;
  [super paste:sender];
}

- (void)didChangeText
{
  [super didChangeText];

  _textWasPasted = NO;
  [self invalidateIntrinsicContentSize];
}

@end
