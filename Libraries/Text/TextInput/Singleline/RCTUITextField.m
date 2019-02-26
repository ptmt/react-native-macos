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
#import <objc/runtime.h>

#import "RCTBackedTextInputDelegateAdapter.h"
#import "RCTFieldEditor.h"

// The "field editor" is a NSTextView whose delegate is this NSTextField.
@interface NSTextField () <NSTextViewDelegate>
@end

@interface RCTUITextFieldCell : NSTextFieldCell
@property (nullable, assign) RCTUITextField *controlView;
@end

@interface RCTUITextField (RCTFieldEditor) <RCTFieldEditorDelegate>
- (RCTFieldEditor *)currentEditor;
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

    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.allowsEditingTextAttributes = NO;
    self.drawsBackground = NO;
    self.focusRingType = NSFocusRingTypeNone;
    self.bordered = NO;
    self.bezeled = NO;

    self.cell.scrollable = YES;
    self.cell.usesSingleLineMode = YES;
    object_setClass(self.cell, RCTUITextFieldCell.class);

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

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
  [super textViewDidChangeSelection:notification];
  [_textInputDelegateAdapter selectedTextRangeWasSet];
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
    // Move the cursor to the end of the current text. Note: Mouse clicks override this selection (which is intended).
    self.currentEditor.selectedRange = NSMakeRange(self.stringValue.length, 0);

    self.currentEditor.textContainerInset = (NSSize){_paddingInsets.left, _paddingInsets.top};
    [_textInputDelegateAdapter performSelector:@selector(textFieldDidFocus) withObject:nil afterDelay:0.0];
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

- (void)setPaddingInsets:(NSEdgeInsets)paddingInsets
{
  // Account for strange rendering offset. (NSTextView doesn't have this issue)
  paddingInsets.top -= 1;
  paddingInsets.left -= 2;

  _paddingInsets = paddingInsets;
}

- (void)selectAll:(nullable id)sender
{
  [self.currentEditor selectAll:sender];
}

@end

@implementation RCTUITextFieldCell
{
  RCTFieldEditor *_fieldEditor;
}

@dynamic controlView;

static inline CGRect NSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
  rect.origin.x    += insets.left;
  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.left + insets.right);
  rect.size.height -= (insets.top  + insets.bottom);
  return rect;
}

- (NSRect)drawingRectForBounds:(NSRect)bounds
{
  NSRect rect = [super drawingRectForBounds:bounds];
  return NSEdgeInsetsInsetRect(rect, self.controlView.paddingInsets);
}

- (NSTextView *)fieldEditorForView:(NSView *)controlView
{
  if (_fieldEditor == nil) {
    _fieldEditor = [RCTFieldEditor new];
  }
  return _fieldEditor;
}

- (NSText *)setUpFieldEditorAttributes:(NSTextView *)fieldEditor
{
  fieldEditor.font = self.font;
  fieldEditor.textColor = self.textColor;
  fieldEditor.backgroundColor = NSColor.clearColor;
  return fieldEditor;
}

@end
