/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextView.h"

#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUIManager.h>
#import <React/RCTUtils.h>
#import <React/NSView+React.h>

#import "RCTShadowText.h"
#import "RCTText.h"
#import "RCTTextSelection.h"
#import "RCTUITextView.h"

@implementation RCTTextView
{
  RCTBridge *_bridge;
  RCTEventDispatcher *_eventDispatcher;

  RCTUITextView *_textView;
  RCTText *_richTextView;
  NSAttributedString *_pendingAttributedText;
  
  NSUInteger _previousTextLength;
  CGFloat _previousContentHeight;
  NSString *_predictedText;
  BOOL _blockTextShouldChange;
  BOOL _nativeUpdatesInFlight;
  NSInteger _nativeEventCount;
  CGFloat _padding;
  
  NSArray <NSValue *> * _previousSelectionRanges;
  NSScrollView *_scrollView;

  BOOL _jsRequestingFirstResponder;

  CGSize _previousContentSize;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  RCTAssertParam(bridge);

  if (self = [super initWithFrame:CGRectZero]) {
    _contentInset = NSEdgeInsetsZero;
    _bridge = bridge;
    _eventDispatcher = bridge.eventDispatcher;
    _blurOnSubmit = NO;

    _textView = [[RCTUITextView alloc] initWithFrame:self.bounds];
//    _textView.autoresizingMask = NSViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textView.backgroundColor = [NSColor clearColor];
    _textView.textColor = [NSColor blackColor];
    // This line actually removes 5pt (default value) left and right padding in UITextView.
    _textView.textContainer.lineFragmentPadding = 0;
    
    _textView.delegate = self;
    _textView.drawsBackground = NO;
    _textView.focusRingType = NSFocusRingTypeDefault;

    [self addSubview:_textView];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

#pragma mark - RCTComponent

- (void)insertReactSubview:(NSView *)subview atIndex:(NSInteger)index
{
  [super insertReactSubview:subview atIndex:index];

  if ([subview isKindOfClass:[RCTText class]]) {
    if (_richTextView) {
      RCTLogError(@"Tried to insert a second <Text> into <TextInput> - there can only be one.");
    }
    _richTextView = (RCTText *)subview;

    // If this <TextInput> is in rich text editing mode, and the child <Text> node providing rich text
    // styling has a backgroundColor, then the attributedText produced by the child <Text> node will have an
    // NSBackgroundColor attribute. We need to forward this attribute to the text view manually because the text view
    // always has a clear background color in `initWithBridge:`.
    //
    // TODO: This should be removed when the related hack in -performPendingTextUpdate is removed.
    if (subview.layer.backgroundColor) {
      NSMutableDictionary<NSString *, id> *attrs = [_textView.typingAttributes mutableCopy];
      attrs[NSBackgroundColorAttributeName] = (__bridge id _Nullable)(subview.layer.backgroundColor);
      _textView.typingAttributes = attrs;
    }

    [self performTextUpdate];
  }
}

- (void)removeReactSubview:(NSView *)subview
{
  [super removeReactSubview:subview];
  if (_richTextView == subview) {
    _richTextView = nil;
    [self performTextUpdate];
  }
}

- (void)didUpdateReactSubviews
{
  // Do nothing, as we don't allow non-text subviews.
}

#pragma mark - Routine

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

static NSAttributedString *removeReactTagFromString(NSAttributedString *string)
{
  if (string.length == 0) {
    return string;
  } else {
    NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
    [mutableString removeAttribute:RCTReactTagAttributeName range:NSMakeRange(0, mutableString.length)];
    return mutableString;
  }
}

- (void)performTextUpdate
{
  if (_richTextView) {
    _pendingAttributedText = _richTextView.textStorage;
    [self performPendingTextUpdate];
  } else if (!self.text) {
    _textView.text = @"";
  }
}

- (void)performPendingTextUpdate
{
  if (!_pendingAttributedText || _mostRecentEventCount < _nativeEventCount || _nativeUpdatesInFlight) {
    return;
  }
  
  // The underlying <Text> node that produces _pendingAttributedText has a react tag attribute on it that causes the
  // -isEqualToAttributedString: comparison below to spuriously fail. We don't want that comparison to fail unless it
  // needs to because when the comparison fails, we end up setting attributedText on the text view, which clears
  // autocomplete state for CKJ text input.
  //
  // TODO: Kill this after we finish passing all style/attribute info into JS.
  _pendingAttributedText = removeReactTagFromString(_pendingAttributedText);
  
  if ([_textView.attributedString isEqualToAttributedString:_pendingAttributedText]) {
    _pendingAttributedText = nil; // Don't try again.
    return;
  }
  
  // When we update the attributed text, there might be pending autocorrections
  // that will get accepted by default. In order for this to not garble our text,
  // we temporarily block all textShouldChange events so they are not applied.
  _blockTextShouldChange = YES;
  
//  UITextRange *selection = _textView.selectedTextRange;
 //  NSInteger oldTextLength = _textView.attributedString.length;
  
  [_textView setAttributedText:_pendingAttributedText];
  _predictedText = _pendingAttributedText.string;
  _pendingAttributedText = nil;
  
//  if (selection.empty) {
//    // maintain cursor position relative to the end of the old text
//    NSInteger start = [_textView offsetFromPosition:_textView.beginningOfDocument toPosition:selection.start];
//    NSInteger offsetFromEnd = oldTextLength - start;
//    NSInteger newOffset = _textView.attributedText.length - offsetFromEnd;
//    UITextPosition *position = [_textView positionFromPosition:_textView.beginningOfDocument offset:newOffset];
//    _textView.selectedTextRange = [_textView textRangeFromPosition:position toPosition:position];
//  }
  
  [_textView layoutSubtreeIfNeeded];
  
  [self invalidateContentSize];
  
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
  frame.origin.y += (_contentInset.top + 2);
  frame.size.width -= (_contentInset.left + _contentInset.right - 5);
  _textView.frame = frame;

  NSSize adjustedTextContainerInset = CGSizeMake(_padding, _padding);
  _textView.textContainerInset = adjustedTextContainerInset;
}

- (void)setFont:(NSFont *)font
{
  _font = font;
  [_textView setFont:font];
}

- (NSColor *)textColor
{
  return _textView.textColor;
}

- (void)setTextColor:(NSColor *)textColor
{
  _textView.textColor = textColor;
}


- (void)setPadding:(CGFloat)padding
{
  _padding = padding;
  [self updateFrames];
}

- (void)setContentInset:(NSEdgeInsets)contentInset
{
  _contentInset = contentInset;
  [self updateFrames];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
  if (backgroundColor) {
    [_textView setDrawsBackground:YES];
    [_textView setBackgroundColor:backgroundColor];
  }
}

- (NSString *)text
{
  return [_textView string];
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)range replacementString:(NSString *)text
{
  if (_blockTextShouldChange) {
    return NO;
  }

  if (_textView.textWasPasted) {
    _textView.textWasPasted = NO;
  } else {
    [_eventDispatcher sendTextEventWithType:RCTTextEventTypeKeyPress
                                   reactTag:self.reactTag
                                       text:[_textView string]
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
      [_textView resignFirstResponder];
      return NO;
    }
  }

  // So we need to track that there is a native update in flight just in case JS manages to come back around and update
  // things /before/ UITextView can update itself asynchronously.  If there is a native update in flight, we defer the
  // JS update when it comes in and apply the deferred update once textViewDidChange fires with the native update applied.
  if (_blockTextShouldChange) {
    return NO;
  }

  if (_maxLength) {
    NSUInteger allowedLength = _maxLength.integerValue - textView.string.length + range.length;
    if (text.length > allowedLength) {
      // If we typed/pasted more than one character, limit the text inputted
      if (text.length > 1) {
        // Truncate the input string so the result is exactly maxLength
        NSString *limitedString = [text substringToIndex:allowedLength];
        NSMutableString *newString = textView.string.mutableCopy;
        [newString replaceCharactersInRange:range withString:limitedString];
        textView.string = newString;
        _predictedText = newString;

        // Collapse selection at end of insert to match normal paste behavior
//        UITextPosition *insertEnd = [textView positionFromPosition:textView.beginningOfDocument
//                                                            offset:(range.location + allowedLength)];
//        textView.selectedTextRange = [textView textRangeFromPosition:insertEnd toPosition:insertEnd];

        [self textViewDidChange:textView];
      }
      return NO;
    }
  }

  _nativeUpdatesInFlight = YES;

  if (range.location + range.length > _predictedText.length) {
    // _predictedText got out of sync in a bad way, so let's just force sync it.  Haven't been able to repro this, but
    // it's causing a real crash here: #6523822
    _predictedText = textView.string;
  }

  NSString *previousText = [_predictedText substringWithRange:range];
  if (_predictedText) {
    _predictedText = [_predictedText stringByReplacingCharactersInRange:range withString:text];
  } else {
    _predictedText = text;
  }

  if (_onTextInput) {
    _onTextInput(@{
      @"text": text,
      @"previousText": previousText ?: @"",
      @"range": @{
        @"start": @(range.location),
        @"end": @(range.location + range.length)
      },
      @"eventCount": @(_nativeEventCount),
    });
  }

  return YES;
}

- (void)textViewDidChangeSelection:(__unused NSNotification *)notification
{
  if (_onSelectionChange &&
      _textView.selectedRanges != _previousSelectionRanges &&
      ![_textView.selectedRanges isEqual:_previousSelectionRanges]) {

    _previousSelectionRanges = _textView.selectedRanges;

    NSRange selection = _textView.selectedRanges.firstObject.rangeValue;

    // TODO: support multiple ranges
    _onSelectionChange(@{
      @"selection": @{
        @"start": @(selection.location),
        @"end": @(selection.location + selection.length),
      },
    });
  }
}

- (void)setText:(NSString *)text
{
  NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;
  if (eventLag == 0 && ![text isEqualToString:[_textView string]]) {
    NSArray <NSValue *> *previousRanges = [_textView selectedRanges];
    [_textView setString:text];
    [_textView setSelectedRanges:previousRanges];
    // [self updatePlaceholderVisibility];
    [self invalidateContentSize];
  } else if (eventLag > RCTTextUpdateLagWarningThreshold) {
    RCTLogWarn(@"Native TextInput(%@) is %zd events ahead of JS - try to make your JS faster.", self.text, eventLag);
  }
}

- (void)updatePlaceholderVisibility
{
}

- (NSString *)placeholder
{
  return _textView.placeholderText;
}

- (void)setPlaceholder:(NSString *)placeholder
{
  _textView.placeholderText = placeholder;
}

- (NSColor *)placeholderTextColor
{
  return _textView.placeholderTextColor;
}

- (void)setPlaceholderTextColor:(NSColor *)placeholderTextColor
{
  _textView.placeholderTextColor = placeholderTextColor;
}

- (NSFont *)defaultPlaceholderFont
{
  return [NSFont systemFontOfSize:17];
}

- (NSColor *)defaultPlaceholderTextColor
{
  return [NSColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.098/255.0 alpha:0.22];
}

- (void)textDidChange:(__unused NSNotification *)notification
{
  if (_clearTextOnFocus) {
    [_textView setString:@""];
    [self updatePlaceholderVisibility];
  }

  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeFocus
                                 reactTag:self.reactTag
                                     text:nil
                                      key:nil
                               eventCount:_nativeEventCount];
}

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

- (void)textViewDidChange:(NSTextView *)textView
{
  // Detect when textView updates happend that didn't invoke `shouldChangeTextInRange`
  // (e.g. typing simplified chinese in pinyin will insert and remove spaces without
  // calling shouldChangeTextInRange).  This will cause JS to get out of sync so we
  // update the mismatched range.
  NSRange currentRange;
  NSRange predictionRange;
  if (findMismatch(textView.string, _predictedText, &currentRange, &predictionRange)) {
    NSString *replacement = [textView.string substringWithRange:currentRange];
    [self textView:textView shouldChangeTextInRange:predictionRange replacementString:replacement];
    // JS will assume the selection changed based on the location of our shouldChangeTextInRange, so reset it.
    [self textViewDidChangeSelection:(NSNotification *)textView];
    _predictedText = textView.string;
  }

  _nativeUpdatesInFlight = NO;
  _nativeEventCount++;

  if (!self.reactTag || !_onChange) {
    return;
  }

  // When the context size increases, iOS updates the contentSize twice; once
  // with a lower height, then again with the correct height. To prevent a
  // spurious event from being sent, we track the previous, and only send the
  // update event if it matches our expectation that greater text length
  // should result in increased height. This assumption is, of course, not
  // necessarily true because shorter text might include more linebreaks, but
  // in practice this works well enough.
  NSUInteger textLength = textView.string.length;
  NSTextContainer* textContainer = [textView textContainer];
  NSLayoutManager* layoutManager = [textView layoutManager];
  [layoutManager ensureLayoutForTextContainer: textContainer];
  CGSize contentSize = [layoutManager usedRectForTextContainer: textContainer].size;
  CGFloat contentHeight = contentSize.height;
  if (textLength >= _previousTextLength) {
    contentHeight = MAX(contentHeight, _previousContentHeight);
  }
  _previousTextLength = textLength;
  _previousContentHeight = contentHeight;
  _onChange(@{
    @"text": self.text,
    @"contentSize": @{
      @"height": @(contentHeight),
      @"width": @(contentSize.width)
    },
    @"target": self.reactTag,
    @"eventCount": @(_nativeEventCount),
  });
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
  if (_nativeUpdatesInFlight) {
    // iOS does't call `textViewDidChange:` delegate method if the change was happened because of autocorrection
    // which was triggered by loosing focus. So, we call it manually.
    [self textViewDidChange:_textView];
    //_nativeEventCount++;
  }

  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeEnd
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


- (void)textDidBeginEditing:(NSNotification *)aNotification
{
  if (_clearTextOnFocus) {
    [_textView setString:@""];
  }
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeFocus
                                 reactTag:self.reactTag
                                     text:[_textView string]
                                      key:nil
                               eventCount:_nativeEventCount];
}


#pragma mark - Focus control deledation

- (void)reactFocus
{
  [_textView reactFocus];
}

- (void)reactBlur
{
  [_textView reactBlur];
}

- (void)didMoveToWindow
{
  [_textView reactFocusIfNeeded];
}

#pragma mark - Content size

- (CGSize)contentSize
{
  // Returning value does NOT include insets.
  CGSize contentSize = self.intrinsicContentSize;
  contentSize.width -= _contentInset.left + _contentInset.right;
  contentSize.height -= _contentInset.top + _contentInset.bottom;
  return contentSize;
}

- (void)invalidateContentSize
{
  CGSize contentSize = self.contentSize;

  if (CGSizeEqualToSize(_previousContentSize, contentSize)) {
    return;
  }
  _previousContentSize = contentSize;

  [_bridge.uiManager setIntrinsicContentSize:contentSize forView:self];

  if (_onContentSizeChange) {
    _onContentSizeChange(@{
      @"contentSize": @{
        @"height": @(contentSize.height),
        @"width": @(contentSize.width),
      },
      @"target": self.reactTag,
    });
  }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
  // Calling `sizeThatFits:` is probably more expensive method to compute
  // content size compare to direct access `_textView.contentSize` property,
  // but seems `sizeThatFits:` returns more reliable and consistent result.
  // Returning value DOES include insets.
  return [self sizeThatFits:CGSizeMake(self.bounds.size.width, INFINITY)];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  // return [_textView sizeThatFits:size];
  return _textView.frame.size;
}

- (void)layout
{
  [super layout];
  [self invalidateContentSize];
}

//
//#pragma mark - UIScrollViewDelegate
//
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//  if (_onScroll) {
//    CGPoint contentOffset = scrollView.contentOffset;
//    CGSize contentSize = scrollView.contentSize;
//    CGSize size = scrollView.bounds.size;
//    UIEdgeInsets contentInset = scrollView.contentInset;
//
//    _onScroll(@{
//      @"contentOffset": @{
//        @"x": @(contentOffset.x),
//        @"y": @(contentOffset.y)
//      },
//      @"contentInset": @{
//        @"top": @(contentInset.top),
//        @"left": @(contentInset.left),
//        @"bottom": @(contentInset.bottom),
//        @"right": @(contentInset.right)
//      },
//      @"contentSize": @{
//        @"width": @(contentSize.width),
//        @"height": @(contentSize.height)
//      },
//      @"layoutMeasurement": @{
//        @"width": @(size.width),
//        @"height": @(size.height)
//      },
//      @"zoomScale": @(scrollView.zoomScale ?: 1),
//    });
//  }
//}

@end
