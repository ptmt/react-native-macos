/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTBackedTextInputDelegateAdapter.h"
#import "RCTUITextView.h"

#pragma mark - RCTBackedTextFieldDelegateAdapter (for NSTextField)

static void *TextFieldSelectionObservingContext = &TextFieldSelectionObservingContext;

@interface RCTBackedTextFieldDelegateAdapter () <NSTextFieldDelegate>
@end

@implementation RCTBackedTextFieldDelegateAdapter {
  __weak NSTextField<RCTBackedTextInputViewProtocol> *_backedTextInputView;
  BOOL _textDidChangeIsComing;
  NSRange _previousSelectedTextRange;
}

- (instancetype)initWithTextField:(NSTextField<RCTBackedTextInputViewProtocol> *)backedTextInputView
{
  if (self = [super init]) {
    _backedTextInputView = backedTextInputView;
    backedTextInputView.delegate = self;


  }

  return self;
}







#pragma mark - NSTextFieldDelegate

- (BOOL)control:(__unused NSControl *)control textShouldBeginEditing:(__unused NSText *)fieldEditor
{
  return [_backedTextInputView.textInputDelegate textInputShouldBeginEditing];
}

- (void)textFieldDidFocus
{
  [_backedTextInputView.textInputDelegate textInputDidBeginEditing];
}

- (BOOL)control:(__unused NSControl *)control textShouldEndEditing:(__unused NSText *)fieldEditor
{
  return [_backedTextInputView.textInputDelegate textInputShouldEndEditing];
}

- (void)textFieldDidBlur
{
  if (_textDidChangeIsComing) {
    // iOS does't call `textViewDidChange:` delegate method if the change was happened because of autocorrection
    // which was triggered by losing focus. So, we call it manually.
    _textDidChangeIsComing = NO;
    [_backedTextInputView.textInputDelegate textInputDidChange];
  }

  [_backedTextInputView.textInputDelegate textInputDidEndEditing];
}

- (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
  BOOL result = [_backedTextInputView.textInputDelegate textInputShouldChangeTextInRange:range replacementText:text];
  if (result) {
    _textDidChangeIsComing = YES;
  }
  return result;
}

//- (BOOL)textFieldShouldReturn:(__unused NSTextField *)textField
//{
//  return [_backedTextInputView.textInputDelegate textInputShouldReturn];
//}

#pragma mark - UIControlEventEditing* Family Events

- (void)controlTextDidChange:(NSNotification *)notification
{
  _textDidChangeIsComing = NO;
  [_backedTextInputView.textInputDelegate textInputDidChange];

  // `selectedTextRangeWasSet` isn't triggered during typing.
  [self textFieldProbablyDidChangeSelection];
}






#pragma mark - UIKeyboardInput (private UIKit protocol)

// This method allows us to detect a [Backspace] `keyPress`
// even when there is no more text in the `UITextField`.
//- (BOOL)keyboardInputShouldDelete:(__unused UITextField *)textField
//{
//  [_backedTextInputView.textInputDelegate textInputShouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@""];
//  return YES;
//}

#pragma mark - Public Interface

- (void)skipNextTextInputDidChangeSelectionEventWithTextRange:(NSRange)textRange
{
  _previousSelectedTextRange = textRange;
}

- (void)selectedTextRangeWasSet
{
  [self textFieldProbablyDidChangeSelection];
}

#pragma mark - Generalization

- (void)textFieldProbablyDidChangeSelection
{
  if (NSEqualRanges(_backedTextInputView.selectedTextRange, _previousSelectedTextRange)) {
    return;
  }

  _previousSelectedTextRange = _backedTextInputView.selectedTextRange;
  [_backedTextInputView.textInputDelegate textInputDidChangeSelection];
}

@end

#pragma mark - RCTBackedTextViewDelegateAdapter (for UITextView)

@interface RCTBackedTextViewDelegateAdapter () <NSTextViewDelegate>
@end

@implementation RCTBackedTextViewDelegateAdapter {
  __unsafe_unretained NSTextView<RCTBackedTextInputViewProtocol> *_backedTextInputView;
  BOOL _textDidChangeIsComing;
  NSRange _previousSelectedTextRange;
}

- (instancetype)initWithTextView:(NSTextView<RCTBackedTextInputViewProtocol> *)backedTextInputView
{
  if (self = [super init]) {
    _backedTextInputView = backedTextInputView;
    backedTextInputView.delegate = self;
  }

  return self;
}

#pragma mark - NSTextViewDelegate

- (BOOL)textShouldBeginEditing:(__unused NSText *)text
{
  return [_backedTextInputView.textInputDelegate textInputShouldBeginEditing];
}

- (void)textDidBeginEditing:(__unused NSNotification *)notification
{
  [_backedTextInputView.textInputDelegate textInputDidBeginEditing];
}

- (BOOL)textShouldEndEditing:(__unused NSText *)text
{
  return [_backedTextInputView.textInputDelegate textInputShouldEndEditing];
}

- (void)textDidEndEditing:(__unused NSNotification *)notification
{
  if (_textDidChangeIsComing) {
    // iOS does't call `textViewDidChange:` delegate method if the change was happened because of autocorrection
    // which was triggered by losing focus. So, we call it manually.
    _textDidChangeIsComing = NO;
    [_backedTextInputView.textInputDelegate textInputDidChange];
  }

  [_backedTextInputView.textInputDelegate textInputDidEndEditing];
}

- (BOOL)textView:(__unused NSTextView *)textView shouldChangeTextInRange:(NSRange)range replacementString:(NSString *)text
{
  // Custom implementation of `textInputShouldReturn` and `textInputDidReturn` pair for `NSTextView`.
  if (!_backedTextInputView.textWasPasted && [text isEqualToString:@"\n"]) {
    if ([_backedTextInputView.textInputDelegate textInputShouldReturn]) {
      [_backedTextInputView.textInputDelegate textInputDidReturn];
      [_backedTextInputView endEditing:NO];
      return NO;
    }
  }

  BOOL result = [_backedTextInputView.textInputDelegate textInputShouldChangeTextInRange:range replacementText:text];
  if (result) {
    _textDidChangeIsComing = YES;
  }
  return result;
}

- (void)textDidChange:(__unused NSNotification *)notification
{
  _textDidChangeIsComing = NO;
  [_backedTextInputView.textInputDelegate textInputDidChange];
}

- (void)textViewDidChangeSelection:(__unused NSNotification *)notification
{
  if (_backedTextInputView == _backedTextInputView.window.firstResponder) {
    [self textViewProbablyDidChangeSelection];
  }
}

#pragma mark - Public Interface

- (void)skipNextTextInputDidChangeSelectionEventWithTextRange:(NSRange)textRange
{
  _previousSelectedTextRange = textRange;
}

#pragma mark - Generalization

- (void)textViewProbablyDidChangeSelection
{
  if (NSEqualRanges(_backedTextInputView.selectedTextRange, _previousSelectedTextRange)) {
    return;
  }

  _previousSelectedTextRange = _backedTextInputView.selectedTextRange;
  [_backedTextInputView.textInputDelegate textInputDidChangeSelection];
}

@end
