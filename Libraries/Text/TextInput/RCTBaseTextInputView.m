/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTBaseTextInputView.h"

//#import <React/RCTAccessibilityManager.h>
#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUIManager.h>
#import <React/RCTUtils.h>
#import <React/NSView+React.h>

#import "NSLabel.h"
#import "RCTTextAttributes.h"
#import "RCTTextSelection.h"

@implementation RCTBaseTextInputView {
  __weak RCTBridge *_bridge;
  __weak RCTEventDispatcher *_eventDispatcher;
//  BOOL _hasInputAccesoryView;
  NSString *_Nullable _predictedText;
  NSInteger _nativeEventCount;
  NSLabel *_placeholderView;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  RCTAssertParam(bridge);

  if (self = [super initWithFrame:CGRectZero]) {
    _bridge = bridge;
    _eventDispatcher = bridge.eventDispatcher;
  }

  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)init)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)decoder)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)

- (NSView<RCTBackedTextInputViewProtocol> *)backedTextInputView
{
  RCTAssert(NO, @"-[RCTBaseTextInputView backedTextInputView] must be implemented in subclass.");
  return nil;
}

#pragma mark - RCTComponent

- (void)didUpdateReactSubviews
{
  // Do nothing.
}

#pragma mark - Properties

- (void)setTextAttributes:(RCTTextAttributes *)textAttributes
{
  _textAttributes = textAttributes;

  id<RCTBackedTextInputViewProtocol> backedTextInputView = self.backedTextInputView;
  backedTextInputView.font = _textAttributes.effectiveFont;
  backedTextInputView.textColor = _textAttributes.effectiveForegroundColor;
  backedTextInputView.textAlignment = _textAttributes.alignment;

  [self updatePlaceholderStyle];
}

- (void)setReactPaddingInsets:(NSEdgeInsets)reactPaddingInsets
{
  _reactPaddingInsets = reactPaddingInsets;
  // We apply `paddingInsets` as `backedTextInputView`'s `textContainerInset`.
  self.backedTextInputView.textContainerInset = reactPaddingInsets;
  [self updatePlaceholderFrame];
  [self setNeedsLayout:YES];
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
  _reactBorderInsets = reactBorderInsets;
  // We apply `borderInsets` as `backedTextInputView` layout offset.
  self.backedTextInputView.frame = NSEdgeInsetsInsetRect(self.bounds, reactBorderInsets);
  [self updatePlaceholderFrame];
  [self setNeedsLayout:YES];
}

- (NSAttributedString *)attributedText
{
  return self.backedTextInputView.attributedText;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
  NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;

  if (eventLag == 0 && ![attributedText isEqualToAttributedString:self.backedTextInputView.attributedText]) {
    NSRange selection = self.backedTextInputView.selectedTextRange;
    NSInteger oldTextLength = self.backedTextInputView.attributedText.string.length;

    self.backedTextInputView.attributedText = attributedText;
    [self updatePlaceholderVisibility];

    if (selection.length == 0) {
      // Maintaining a cursor position relative to the end of the old text.
      NSInteger offsetStart = selection.location;
//        [self.backedTextInputView offsetFromPosition:self.backedTextInputView.beginningOfDocument
//                                          toPosition:selection.start];
      NSInteger offsetFromEnd = oldTextLength - offsetStart;
      NSInteger newOffset = attributedText.string.length - offsetFromEnd;
//      UITextPosition *position =
//        [self.backedTextInputView positionFromPosition:self.backedTextInputView.beginningOfDocument
//                                                offset:newOffset];
      [self.backedTextInputView setSelectedTextRange:(NSRange){newOffset, 0}
                                      notifyDelegate:YES];
    }

    [self updateLocalData];
  } else if (eventLag > RCTTextUpdateLagWarningThreshold) {
    RCTLogWarn(@"Native TextInput(%@) is %lld events ahead of JS - try to make your JS faster.", self.backedTextInputView.attributedText.string, (long long)eventLag);
  }
}

- (RCTTextSelection *)selection
{
  id<RCTBackedTextInputViewProtocol> backedTextInputView = self.backedTextInputView;
  NSRange selectedTextRange = [backedTextInputView selectedTextRange];
  return [[RCTTextSelection new] initWithStart:selectedTextRange.location
                                           end:selectedTextRange.location + selectedTextRange.length];
}

- (void)setSelection:(RCTTextSelection *)selection
{
  if (!selection) {
    return;
  }

  id<RCTBackedTextInputViewProtocol> backedTextInputView = self.backedTextInputView;

  NSRange previousSelectedTextRange = [backedTextInputView selectedTextRange];
  NSRange selectedTextRange = (NSRange){selection.start, selection.end - selection.start};



  NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;
  if (eventLag == 0 && !NSEqualRanges(previousSelectedTextRange, selectedTextRange)) {
    [backedTextInputView setSelectedTextRange:selectedTextRange notifyDelegate:NO];
  } else if (eventLag > RCTTextUpdateLagWarningThreshold) {
    RCTLogWarn(@"Native TextInput(%@) is %lld events ahead of JS - try to make your JS faster.", backedTextInputView.attributedText.string, (long long)eventLag);
  }
}

#pragma mark - RCTBackedTextInputDelegate

- (BOOL)textInputShouldBeginEditing
{
  return YES;
}

- (void)textInputDidBeginEditing
{
  if (_clearTextOnFocus) {
    self.backedTextInputView.attributedText = [NSAttributedString new];
    [self updatePlaceholderVisibility];
  }

  if (_selectTextOnFocus) {
    [self.backedTextInputView selectAll:nil];
  }

  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeFocus
                                 reactTag:self.reactTag
                                     text:self.backedTextInputView.attributedText.string
                                      key:nil
                               eventCount:_nativeEventCount];
}

- (BOOL)textInputShouldEndEditing
{
  return YES;
}

- (void)textInputDidEndEditing
{
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeEnd
                                 reactTag:self.reactTag
                                     text:self.backedTextInputView.attributedText.string
                                      key:nil
                               eventCount:_nativeEventCount];

  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeBlur
                                 reactTag:self.reactTag
                                     text:self.backedTextInputView.attributedText.string
                                      key:nil
                               eventCount:_nativeEventCount];
}

- (BOOL)textInputShouldReturn
{
  // We send `submit` event here, in `textInputShouldReturn`
  // (not in `textInputDidReturn)`, because of semantic of the event:
  // `onSubmitEditing` is called when "Submit" button
  // (the blue key on onscreen keyboard) did pressed
  // (no connection to any specific "submitting" process).
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeSubmit
                                 reactTag:self.reactTag
                                     text:self.backedTextInputView.attributedText.string
                                      key:nil
                               eventCount:_nativeEventCount];

  return _blurOnSubmit;
}

- (void)textInputDidReturn
{
  // Does nothing.
}

- (BOOL)textInputShouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
  id<RCTBackedTextInputViewProtocol> backedTextInputView = self.backedTextInputView;

  if (!backedTextInputView.textWasPasted) {
    [_eventDispatcher sendTextEventWithType:RCTTextEventTypeKeyPress
                                   reactTag:self.reactTag
                                       text:nil
                                        key:text
                                 eventCount:_nativeEventCount];
  }

  if (_maxLength) {
    NSUInteger allowedLength = _maxLength.integerValue - backedTextInputView.attributedText.string.length + range.length;

    if (text.length > allowedLength) {
      // If we typed/pasted more than one character, limit the text inputted.
      if (text.length > 1) {
        // Truncate the input string so the result is exactly maxLength
        NSString *limitedString = [text substringToIndex:allowedLength];
        NSMutableAttributedString *newAttributedText = [backedTextInputView.attributedText mutableCopy];
        [newAttributedText replaceCharactersInRange:range withString:limitedString];
        backedTextInputView.attributedText = newAttributedText;
        _predictedText = newAttributedText.string;

        // Collapse selection at end of insert to match normal paste behavior.
        [backedTextInputView setSelectedTextRange:(NSRange){range.location + allowedLength, 0}
                                   notifyDelegate:YES];



        [self textInputDidChange];
      }

      return NO;
    }
  }

  if (range.location + range.length > _predictedText.length) {
    // _predictedText got out of sync in a bad way, so let's just force sync it.  Haven't been able to repro this, but
    // it's causing a real crash here: #6523822
    _predictedText = backedTextInputView.attributedText.string;
  }

  NSString *previousText = [_predictedText substringWithRange:range] ?: @"";

  // After clearing the text by replacing it with an empty string, `_predictedText`
  // still preserves the deleted text.
  // As the first character in the TextInput always comes with the range value (0, 0),
  // we should check the range value in order to avoid appending a character to the deleted string
  // (which caused the issue #18374)
  if (!NSEqualRanges(range, NSMakeRange(0, 0)) && _predictedText) {
    _predictedText = [_predictedText stringByReplacingCharactersInRange:range withString:text];
  } else {
    _predictedText = text;
  }

  if (_onTextInput) {
    _onTextInput(@{
      @"text": text,
      @"previousText": previousText,
      @"range": @{
        @"start": @(range.location),
        @"end": @(range.location + range.length)
      },
      @"eventCount": @(_nativeEventCount),
    });
  }

  return YES;
}

- (void)textInputDidChange
{
  [self updateLocalData];
  [self updatePlaceholderVisibility];

  id<RCTBackedTextInputViewProtocol> backedTextInputView = self.backedTextInputView;

  // Detect when `backedTextInputView` updates happend that didn't invoke `shouldChangeTextInRange`
  // (e.g. typing simplified chinese in pinyin will insert and remove spaces without
  // calling shouldChangeTextInRange).  This will cause JS to get out of sync so we
  // update the mismatched range.
  NSRange currentRange;
  NSRange predictionRange;
  if (findMismatch(backedTextInputView.attributedText.string, _predictedText, &currentRange, &predictionRange)) {
    NSString *replacement = [backedTextInputView.attributedText.string substringWithRange:currentRange];
    [self textInputShouldChangeTextInRange:predictionRange replacementText:replacement];
    // JS will assume the selection changed based on the location of our shouldChangeTextInRange, so reset it.
    [self textInputDidChangeSelection];
    _predictedText = backedTextInputView.attributedText.string;
  }

  _nativeEventCount++;

  if (_onChange) {
    _onChange(@{
       @"text": self.attributedText.string,
       @"target": self.reactTag,
       @"eventCount": @(_nativeEventCount),
    });
  }
}

- (void)textInputDidChangeSelection
{
  if (!_onSelectionChange) {
    return;
  }

  RCTTextSelection *selection = self.selection;

  _onSelectionChange(@{
    @"selection": @{
      @"start": @(selection.start),
      @"end": @(selection.end),
    },
  });
}

- (void)updateLocalData
{
//  [self enforceTextAttributesIfNeeded];

  [_bridge.uiManager setLocalData:[self.backedTextInputView.attributedText copy]
                          forView:self];
}

#pragma mark - Layout (in UIKit terms, with all insets)

- (CGSize)intrinsicContentSize
{
  CGSize size = self.backedTextInputView.intrinsicContentSize;
  size.width += _reactBorderInsets.left + _reactBorderInsets.right;
  size.height += _reactBorderInsets.top + _reactBorderInsets.bottom;
  // Returning value DOES include border and padding insets.
  return size;
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGFloat compoundHorizontalBorderInset = _reactBorderInsets.left + _reactBorderInsets.right;
  CGFloat compoundVerticalBorderInset = _reactBorderInsets.top + _reactBorderInsets.bottom;

  size.width -= compoundHorizontalBorderInset;
  size.height -= compoundVerticalBorderInset;

  // Note: `paddingInsets` was already included in `backedTextInputView` size
  // because it was applied as `textContainerInset`.
  CGSize fittingSize = [self.backedTextInputView sizeThatFits:size];

  fittingSize.width += compoundHorizontalBorderInset;
  fittingSize.height += compoundVerticalBorderInset;

  // Returning value DOES include border and padding insets.
  return fittingSize;
}

#pragma mark - Accessibility

- (NSView *)reactAccessibilityElement
{
  return self.backedTextInputView;
}

#pragma mark - Focus Control

- (void)reactFocus
{
  [self.backedTextInputView reactFocus];
}

- (void)reactBlur
{
  [self.backedTextInputView reactBlur];
}

- (void)didMoveToWindow
{
  [self.backedTextInputView reactFocusIfNeeded];
}

#pragma mark - Custom Input Accessory View

//- (void)didSetProps:(NSArray<NSString *> *)changedProps
//{
//  [self invalidateInputAccessoryView];
//}
//
//- (void)invalidateInputAccessoryView
//{
//#if !TARGET_OS_TV
//  NSView<RCTBackedTextInputViewProtocol> *textInputView = self.backedTextInputView;
//  UIKeyboardType keyboardType = textInputView.keyboardType;
//
//  // These keyboard types (all are number pads) don't have a "Done" button by default,
//  // so we create an `inputAccessoryView` with this button for them.
//  BOOL shouldHaveInputAccesoryView =
//    (
//      keyboardType == UIKeyboardTypeNumberPad ||
//      keyboardType == UIKeyboardTypePhonePad ||
//      keyboardType == UIKeyboardTypeDecimalPad ||
//      keyboardType == UIKeyboardTypeASCIICapableNumberPad
//    ) &&
//    textInputView.returnKeyType == UIReturnKeyDone;
//
//  if (_hasInputAccesoryView == shouldHaveInputAccesoryView) {
//    return;
//  }
//
//  _hasInputAccesoryView = shouldHaveInputAccesoryView;
//
//  if (shouldHaveInputAccesoryView) {
//    UIToolbar *toolbarView = [[UIToolbar alloc] init];
//    [toolbarView sizeToFit];
//    UIBarButtonItem *flexibleSpace =
//      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
//                                                    target:nil
//                                                    action:nil];
//    UIBarButtonItem *doneButton =
//      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//                                                    target:self
//                                                    action:@selector(handleInputAccessoryDoneButton)];
//    toolbarView.items = @[flexibleSpace, doneButton];
//    textInputView.inputAccessoryView = toolbarView;
//  }
//  else {
//    textInputView.inputAccessoryView = nil;
//  }
//
//  // We have to call `reloadInputViews` for focused text inputs to update an accessory view.
//  if (textInputView.isFirstResponder) {
//    [textInputView reloadInputViews];
//  }
//#endif
//}
//
//- (void)handleInputAccessoryDoneButton
//{
//  if ([self textInputShouldReturn]) {
//    [self.backedTextInputView endEditing:YES];
//  }
//}

#pragma mark - Helpers

static BOOL findMismatch(NSString *first, NSString *second, NSRange *firstRange, NSRange *secondRange)
{
  NSInteger firstMismatch = -1;
  for (NSUInteger ii = 0; ii < MAX(first.length, second.length); ii++) {
    if (ii >= first.length || ii >= second.length || [first characterAtIndex:ii] != [second characterAtIndex:ii]) {
      firstMismatch = ii;
      break;
    }
  }

  if (firstMismatch == -1) {
    return NO;
  }

  NSUInteger ii = second.length;
  NSUInteger lastMismatch = first.length;
  while (ii > firstMismatch && lastMismatch > firstMismatch) {
    if ([first characterAtIndex:(lastMismatch - 1)] != [second characterAtIndex:(ii - 1)]) {
      break;
    }
    ii--;
    lastMismatch--;
  }

  *firstRange = NSMakeRange(firstMismatch, lastMismatch - firstMismatch);
  *secondRange = NSMakeRange(firstMismatch, ii - firstMismatch);
  return YES;
}

#pragma mark - Placeholder

- (NSLabel *)placeholderView
{
  if (_placeholderView == nil) {
    _placeholderView = [[NSLabel alloc] initWithFrame:NSZeroRect];
    [self updatePlaceholderStyle];
    [self addSubview:_placeholderView positioned:NSWindowBelow relativeTo:self.backedTextInputView];
  }
  return _placeholderView;
}

- (NSString *)placeholder
{
  return _placeholderView.text;
}

- (void)setPlaceholder:(NSString *)placeholder
{
  if (placeholder) {
    // Use "self" to ensure "placeholderView" exists.
    self.placeholderView.text = placeholder;
    [self updatePlaceholderFrame];
  } else if (_placeholderView) {
    [_placeholderView removeFromSuperview];
    _placeholderView = nil;
  }
}

- (NSColor *)placeholderColor
{
  return _placeholderView.textColor;
}

- (void)setPlaceholderColor:(NSColor *)color
{
  // Use "self" to ensure "placeholderView" exists.
  self.placeholderView.textColor = color ?: _textAttributes.effectiveForegroundColor;
}

- (void)updatePlaceholderStyle
{
  if (_placeholderView && _textAttributes) {
    _placeholderView.font = _textAttributes.effectiveFont;
    _placeholderView.textColor = _textAttributes.effectiveForegroundColor;
    _placeholderView.alignment = _textAttributes.alignment;
  }
}

- (void)updatePlaceholderFrame
{
  if (_placeholderView) {
    NSEdgeInsets insets = self.reactCompoundInsets;
    CGFloat maxWidth = self.bounds.size.width - (insets.left + insets.right);
    if (maxWidth != _placeholderView.preferredMaxLayoutWidth) {
      _placeholderView.preferredMaxLayoutWidth = maxWidth;
    }
    NSRect bounds = (NSRect){NSZeroPoint, _placeholderView.intrinsicContentSize};
    _placeholderView.frame = NSOffsetRect(bounds, insets.left, insets.top - 1);
  }
}

- (void)updatePlaceholderVisibility
{
  if (_placeholderView) {
    BOOL hidden = _placeholderView.text.length == 0 || self.attributedText.length > 0;
    _placeholderView.hidden = hidden;
  }
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame:frame];
  [self updatePlaceholderFrame];
}

@end
