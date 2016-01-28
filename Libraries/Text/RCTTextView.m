/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextView.h"

#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTText.h"
#import "RCTUtils.h"
#import "NSView+React.h"

@interface RCTUITextView : NSTextView

@property (nonatomic, strong) NSAttributedString *placeholderAttributedString;
@property (nonatomic, assign) BOOL textWasPasted;

@end

@implementation RCTUITextView
{
  BOOL _jsRequestingFirstResponder;
}

- (void)paste:(id)sender
{
  _textWasPasted = YES;
  [super paste:sender];
}

- (void)reactWillMakeFirstResponder
{
  _jsRequestingFirstResponder = YES;
}

- (BOOL)canBecomeFirstResponder
{
  return _jsRequestingFirstResponder;
}

- (void)reactDidMakeFirstResponder
{
  _jsRequestingFirstResponder = NO;
}

@end

@implementation RCTTextView
{
  RCTEventDispatcher *_eventDispatcher;
  NSString *_placeholder;
  RCTUITextView *_textView;
  NSTextView *_placeholderView;
  NSInteger _nativeEventCount;
  CGFloat _padding;
  RCTText *_richTextView;
  NSAttributedString *_pendingAttributedText;
  NSMutableArray<NSView *> *_subviews;
  BOOL _blockTextShouldChange;
  NSArray <NSValue *> * _previousSelectionRanges;
  NSScrollView *_scrollView;
  BOOL _jsRequestingFirstResponder;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  RCTAssertParam(eventDispatcher);

  if ((self = [super initWithFrame:CGRectZero])) {
    _contentInset = NSEdgeInsetsZero;
    _eventDispatcher = eventDispatcher;
    _placeholderTextColor = [self defaultPlaceholderTextColor];
    _jsRequestingFirstResponder = YES;
    _padding = 0;

    _textView = [[RCTUITextView alloc] initWithFrame:CGRectZero];
    _textView.backgroundColor = [NSColor clearColor];
//    _textView.scrollsToTop = NO;
//    _textView.scrollEnabled = NO;
    _textView.delegate = self;

    _scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
    //_scrollView.scrollsToTop = NO; TODO:
    [_scrollView addSubview:_textView];

    _previousSelectionRanges = _textView.selectedRanges;

    _subviews = [NSMutableArray new];
    [self addSubview:_scrollView];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (NSArray<NSView *> *)reactSubviews
{
  return _subviews;
}

- (void)insertReactSubview:(NSView *)subview atIndex:(NSInteger)index
{
  if ([subview isKindOfClass:[RCTText class]]) {
    if (_richTextView) {
      RCTLogError(@"Tried to insert a second <Text> into <TextInput> - there can only be one.");
    }
    _richTextView = (RCTText *)subview;
    [_subviews insertObject:_richTextView atIndex:index];
  } else {
    [_subviews insertObject:subview atIndex:index];
    [self addSubview:subview];
  }
}

- (void)removeReactSubview:(NSView *)subview
{
  if (_richTextView == subview) {
    [_subviews removeObject:_richTextView];
    _richTextView = nil;
  } else {
    [_subviews removeObject:subview];
    [subview removeFromSuperview];
  }
}

- (void)setMostRecentEventCount:(NSInteger)mostRecentEventCount
{
  _mostRecentEventCount = mostRecentEventCount;

  // Props are set after uiBlockToAmendWithShadowViewRegistry, which means that
  // at the time performTextUpdate is called, _mostRecentEventCount will be
  // behind _eventCount, with the result that performPendingTextUpdate will do
  // nothing. For that reason we call it again here after mostRecentEventCount
  // has been set.
  [self performPendingTextUpdate];
}

- (void)performTextUpdate
{
  if (_richTextView) {
    _pendingAttributedText = _richTextView.textStorage;
    [self performPendingTextUpdate];
  } else if (!self.text) {
    [_textView setString:@""];
  }
}

- (void)performPendingTextUpdate
{
  if (!_pendingAttributedText || _mostRecentEventCount < _nativeEventCount) {
    return;
  }

  if ([_textView.attributedString isEqualToAttributedString:_pendingAttributedText]) {
    _pendingAttributedText = nil; // Don't try again.
    return;
  }

  // When we update the attributed text, there might be pending autocorrections
  // that will get accepted by default. In order for this to not garble our text,
  // we temporarily block all textShouldChange events so they are not applied.
  _blockTextShouldChange = YES;

  NSArray <NSValue *> * selection = _textView.selectedRanges;
  //NSInteger oldTextLength = _textView.attributedString.length;

  [_textView.textStorage setAttributedString:_pendingAttributedText];
  _pendingAttributedText = nil;

    // maintain cursor position relative to the end of the old text
    // TODO:
    _textView.selectedRanges = selection;

  [_textView layout];

  [self _setPlaceholderVisibility];

  _blockTextShouldChange = NO;
}

- (void)updateFrames
{
  // Adjust the insets so that they are as close as possible to single-line
  // RCTTextField defaults, using the system defaults of font size 17 and a
  // height of 31 points.
  //
  // We apply the left inset to the frame since a negative left text-container
  // inset mysteriously causes the text to be hidden until the text view is
  // first focused.
  CGRect frame = self.frame;
  frame.origin.x += (_contentInset.left - 5);
  frame.size.width -= (_contentInset.left + _contentInset.right - 5);

  _textView.frame = frame;
  NSSize adjustedTextContainerInset = CGSizeMake(_padding, _padding);

  _textView.textContainerInset = adjustedTextContainerInset;
  _placeholderView.textContainerInset = adjustedTextContainerInset;
}


- (void)updateContentSize
{
  CGSize size = (CGSize){_scrollView.frame.size.width, INFINITY};
//  size.height = [_textView sizeThatFits:size].height;
//  _scrollView.contentSize = size;
  _textView.frame = (CGRect){CGPointZero, size};
}

- (void)updatePlaceholder
{
  if (_placeholder) {
    _placeholderView = [[NSTextView alloc] initWithFrame:self.bounds];
    _placeholderView.editable = NO;
    _placeholderView.backgroundColor = [NSColor clearColor];
    [_placeholderView.textStorage setAttributedString:
      [[NSAttributedString alloc] initWithString:_placeholder attributes:@{
        NSFontAttributeName : (_textView.font ? _textView.font : [self defaultPlaceholderFont]),
        NSForegroundColorAttributeName : _placeholderTextColor
      }]];

    [self addSubview:_placeholderView];
    [self _setPlaceholderVisibility];
  }
}

- (NSFont *)font
{
  return _textView.font;
}

- (void)setFont:(NSFont *)font
{
  _textView.font = font;
  [self updatePlaceholder];
}

- (NSColor *)textColor
{
  return _textView.textColor;
}

- (void)setTextColor:(NSColor *)textColor
{
  _textView.textColor = textColor;
}

- (void)setPlaceholder:(NSString *)placeholder
{
  _placeholder = placeholder;
  [self updatePlaceholder];
}

- (void)setPlaceholderTextColor:(NSColor *)placeholderTextColor
{
  if (placeholderTextColor) {
    _placeholderTextColor = placeholderTextColor;
  } else {
    _placeholderTextColor = [self defaultPlaceholderTextColor];
  }
  [self updatePlaceholder];
}

- (void)setPadding:(CGFloat )padding
{
 // NSLog(@"padding %@", padding);
  _padding = padding;
  [self updateFrames];
}

- (void)setContentInset:(NSEdgeInsets)contentInset
{
  _contentInset = contentInset;
  [self updateFrames];
}

- (NSString *)text
{
  return [_textView string];
}

- (BOOL)textView:(RCTUITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
  if (_blockTextShouldChange) {
    return NO;
  }

  if (textView.textWasPasted) {
    textView.textWasPasted = NO;
  } else {
    
    [_eventDispatcher sendTextEventWithType:RCTTextEventTypeKeyPress
                                   reactTag:self.reactTag
                                       text:nil
                                        key:text
                                 eventCount:_nativeEventCount];

    if (_blurOnSubmit && [text isEqualToString:@"\n"]) {

      // TODO: the purpose of blurOnSubmit on RCTextField is to decide if the
      // field should lose focus when return is pressed or not. We're cheating a
      // bit here by using it on RCTextView to decide if return character should
      // submit the form, or be entered into the field.
      //
      // The reason this is cheating is because there's no way to specify that
      // you want the return key to be swallowed *and* have the field retain
      // focus (which was what blurOnSubmit was originally for). For the case
      // where _blurOnSubmit = YES, this is still the correct and expected
      // behavior though, so we'll leave the don't-blur-or-add-newline problem
      // to be solved another day.

      [_eventDispatcher sendTextEventWithType:RCTTextEventTypeSubmit
                                     reactTag:self.reactTag
                                         text:self.text
                                          key:nil
                                   eventCount:_nativeEventCount];
      [self resignFirstResponder];
      return NO;
    }
  }

  if (_maxLength == nil) {
    return YES;
  }
  return NO;
//  NSUInteger allowedLength = _maxLength.integerValue - textView.text.length + range.length;
//  if (text.length > allowedLength) {
//    if (text.length > 1) {
//      // Truncate the input string so the result is exactly maxLength
//      NSString *limitedString = [text substringToIndex:allowedLength];
//      NSMutableString *newString = [textView string].mutableCopy;
//      [newString replaceCharactersInRange:range withString:limitedString];
//      [textView setString:newString];
//      // Collapse selection at end of insert to match normal paste behavior
////      UITextPosition *insertEnd = [textView positionFromPosition:textView.beginningOfDocument
////                                                          offset:(range.location + allowedLength)];
////      textView.selectedTextRange = [textView textRangeFromPosition:insertEnd toPosition:insertEnd];
//      [self textViewDidChange:textView];
//    }
//    return NO;
//  } else {
//    return YES;
//  }
}

- (void)textViewDidChangeSelection:(RCTUITextView *)textView
{
  if (_onSelectionChange &&
      textView.selectedRanges != _previousSelectionRanges &&
      ![textView.selectedRanges isEqual:_previousSelectionRanges]) {

    NSLog(@"_onSelectionChange is not implemented");
//    _previousSelectionRange = textView.selectedRanges;
//
//    UITextRange *selection = textView.selectedRanges;
//    NSInteger start = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selection.start];
//    NSInteger end = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selection.end];
//    _onSelectionChange(@{
//      @"selection": @{
//        @"start": @(start),
//        @"end": @(end),
//      },
//    });
  }
}

- (void)setText:(NSString *)text
{
  NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;
  if (eventLag == 0 && ![text isEqualToString:[_textView string]]) {
    NSArray <NSValue *> *previousRanges = [_textView selectedRanges];
    [_textView setString:text];
    [_textView setSelectedRanges:previousRanges];
    [self _setPlaceholderVisibility];
    [self updateContentSize];
  } else if (eventLag > RCTTextUpdateLagWarningThreshold) {
    RCTLogWarn(@"Native TextInput(%@) is %zd events ahead of JS - try to make your JS faster.", self.text, eventLag);
  }
}

- (void)_setPlaceholderVisibility
{
  if (_textView.string.length > 0) {
    [_placeholderView setHidden:YES];
  } else {
    [_placeholderView setHidden:NO];
  }
}

- (NSFont *)defaultPlaceholderFont
{
  return [NSFont systemFontOfSize:17];
}

- (NSColor *)defaultPlaceholderTextColor
{
  return [NSColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.098/255.0 alpha:0.22];
}

//- (void)setAutoCorrect:(BOOL)autoCorrect
//{
//  //_textView.autocorrectionType = (autoCorrect ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo);
//}

//- (BOOL)autoCorrect
//{
//  return _textView.autocorrectionType == UITextAutocorrectionTypeYes;
//}

- (void)textDidChange:(NSNotification *)aNotification
{

  _nativeEventCount++;
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeChange
                                 reactTag:self.reactTag
                                     text:[_textView string]
                                      key:nil
                               eventCount:_nativeEventCount];
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
  [self updateContentSize];
  [self _setPlaceholderVisibility];
  _nativeEventCount++;
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeEnd
                                 reactTag:self.reactTag
                                     text:[_textView string]
                                      key:nil
                               eventCount:_nativeEventCount];
}


- (void)textDidBeginEditing:(NSNotification *)aNotification
{
  //[self hidePlaceholder];
  if (_clearTextOnFocus) {
    [_textView setString:@""];
    //[self _setPlaceholderVisibility];
  }
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeFocus
                                 reactTag:self.reactTag
                                     text:[_textView string]
                                      key:nil
                               eventCount:_nativeEventCount];

  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeBlur
                                 reactTag:self.reactTag
                                     text:nil
                                      key:nil
                               eventCount:_nativeEventCount];
}

- (BOOL)isFirstResponder
{
  return [_textView acceptsFirstResponder]; //TODO:
}

- (BOOL)canBecomeFirstResponder
{
  return [_textView canBecomeFirstResponder];
}

- (void)reactWillMakeFirstResponder
{
  [_textView reactWillMakeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
  return [_textView becomeFirstResponder];
}

- (void)reactDidMakeFirstResponder
{
  [_textView reactDidMakeFirstResponder];
}

- (BOOL)resignFirstResponder
{
  [super resignFirstResponder];
  BOOL result = [_textView resignFirstResponder];
  if (result) {
    [_eventDispatcher sendTextEventWithType:RCTTextEventTypeBlur
                                   reactTag:self.reactTag
                                       text:[_textView string]
                                        key:nil
                                 eventCount:_nativeEventCount];
  }
  return result;
}

- (void)layout
{
  [super layout];
  [self updateFrames];
}

@end
