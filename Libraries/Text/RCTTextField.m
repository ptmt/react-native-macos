/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextField.h"

#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import "NSView+React.h"
#import "RCTText.h"


//
//@implementation TextFieldCellWithPaddings
//
//- (id)init
//{
//  self = [super init];
//  if (self) {
////    self.bordered = NO;
////    self.drawsBackground = NO;
//  }
//  return self;
//}
//
////- (NSRect)titleRectForBounds:(NSRect)theRect
////{
////  //NSRect titleFrame = [super titleRectForBounds:theRect];
////
////  //NSSize titleSize = [[self attributedStringValue] size];
////  //titleFrame.origin.y = theRect.origin.y + (theRect.size.height - titleSize.height) / 2.0;
////  return UIEdgeInsetsInsetRect(theRect, ((RCTTextField *)[self controlView]).contentInset);
////}
//
//- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//  NSRect titleRect = [self titleRectForBounds:cellFrame];
//  [[self attributedStringValue] drawInRect:titleRect];
//}
//
//
////- (NSRect)drawingRectForBounds:(NSRect)rect
////{
////  NSRect rectInset = UIEdgeInsetsInsetRect(rect, _contentInset);
////  return [super drawingRectForBounds:rectInset];
////}
//
//// Required methods
//- (id)initWithCoder:(NSCoder *)decoder {
//  return [super initWithCoder:decoder];
//}
//- (id)initImageCell:(NSImage *)image {
//  return [super initImageCell:image];
//}
//- (id)initTextCell:(NSString *)string {
//  return [super initTextCell:string];
//}
//@end

@implementation RCTTextField
{
  RCTEventDispatcher *_eventDispatcher;
  BOOL _jsRequestingFirstResponder;
  NSInteger _nativeEventCount;
  NSString * _placeholderString;
  BOOL _submitted;
  NSRange _previousSelectionRange;

}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  if ((self = [super initWithFrame:CGRectZero])) {
    RCTAssert(eventDispatcher, @"eventDispatcher is a required parameter");
    self.delegate = self;
    self.drawsBackground = NO;
    self.bordered = NO;
    self.bezeled = YES;

    _eventDispatcher = eventDispatcher;
    _previousSelectionRange = self.currentEditor.selectedRange;

    [self addObserver:self forKeyPath:@"selectedTextRange" options:0 context:nil];
  }
  return self;
}

- (void)dealloc
{
  [self removeObserver:self forKeyPath:@"selectedTextRange"];
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (void)sendKeyValueForString:(NSString *)string
{
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeKeyPress
                                 reactTag:self.reactTag
                                     text:nil
                                      key:string
                               eventCount:_nativeEventCount];
}

// This method is overridden for `onKeyPress`. The manager
// will not send a keyPress for text that was pasted.
- (void)paste:(id)sender
{
  _textWasPasted = YES;
  [[super currentEditor] paste:sender];
}

- (void)setText:(NSString *)text
{
  NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;
  if (eventLag == 0 && ![text isEqualToString:[self stringValue]]) {
    [self setStringValue:text];
    // TODO: maintain cursor position
  } else if (eventLag > RCTTextUpdateLagWarningThreshold) {
    RCTLogWarn(@"Native TextInput(%@) is %zd events ahead of JS - try to make your JS faster.", [self stringValue], eventLag);
  }
}

- (void)setPlaceholderTextColor:(NSColor *)placeholderTextColor
{
  if (placeholderTextColor != nil && ![_placeholderTextColor isEqual:placeholderTextColor]) {
    _placeholderTextColor = placeholderTextColor;
    [self updatePlaceholder];
  }
}

- (void)updatePlaceholder
{
  if (_placeholderTextColor && _placeholderString) {
    NSAttributedString *attrString = [[NSAttributedString alloc]
                                      initWithString:_placeholderString attributes: @{
                                        NSForegroundColorAttributeName: _placeholderTextColor,
                                        NSFontAttributeName: [self font]
                                      }];
    [self setPlaceholderAttributedString:attrString];
  }
}

- (void)setPlaceholder:(NSString *)placeholder
{
  if (placeholder != nil && ![_placeholderString isEqual:placeholder]) {
    _placeholderString = placeholder;
    [self updatePlaceholder];
  }
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
  if (backgroundColor) {
    [self setDrawsBackground:YES];
    [self.cell setBackgroundColor:backgroundColor];
  }
}

- (void)textDidChange:(NSNotification *)aNotification
{
  _nativeEventCount++;
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeChange
                                 reactTag:self.reactTag
                                     text:[self stringValue]
                                      key:nil
                               eventCount:_nativeEventCount];

  // selectedTextRange observer isn't triggered when you type even though the
  // cursor position moves, so we send event again here.
  [self sendSelectionEvent];
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
  _nativeEventCount++;
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeEnd
                                 reactTag:self.reactTag
                                     text:[self stringValue]
                                      key:nil
                               eventCount:_nativeEventCount];
}
- (void)textFieldSubmitEditingWithString:(NSString *)key
{
  _submitted = YES;
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeSubmit
                                 reactTag:self.reactTag
                                     text:[self stringValue]
                                      key:key
                               eventCount:_nativeEventCount];
}

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
  if (_selectTextOnFocus) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self selectAll:nil];
    });
  }
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeFocus
                                 reactTag:self.reactTag
                                     text:[self stringValue]
                                      key:nil
                               eventCount:_nativeEventCount];
}

- (BOOL)textFieldShouldEndEditing:(RCTTextField *)textField
{
//  if (_submitted) {
//    _submitted = NO;
//    return _blurOnSubmit;
//  }
  return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(RCTTextField *)textField
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([keyPath isEqualToString:@"selectedTextRange"]) {
    [self sendSelectionEvent];
  }
}

- (void)sendSelectionEvent
{
  if (_onSelectionChange &&
      (self.currentEditor.selectedRange.location != _previousSelectionRange.location ||
      self.currentEditor.selectedRange.length != _previousSelectionRange.length)) {

    _previousSelectionRange = self.currentEditor.selectedRange;

    NSRange selection = self.currentEditor.selectedRange;
    NSInteger start = selection.location;
    NSInteger end = selection.location + selection.length;
    _onSelectionChange(@{
      @"selection": @{
        @"start": @(start),
        @"end": @(end),
      },
    });
  }
}

-(BOOL)becomeFirstResponder
{
  BOOL success = [super becomeFirstResponder];
  if (success)
  {
    NSTextView* textField = (NSTextView*) [self currentEditor];
    if( [textField respondsToSelector: @selector(setInsertionPointColor:)] ) {
      [textField setInsertionPointColor:[self selectionColor]];
    }
    [self updatePlaceholder];
  }
  return success;
}

- (BOOL)canBecomeFirstResponder
{
  return _jsRequestingFirstResponder;
}

- (void)reactWillMakeFirstResponder
{
  _jsRequestingFirstResponder = YES;
}

- (void)reactDidMakeFirstResponder
{
  _jsRequestingFirstResponder = NO;
}

- (BOOL)resignFirstResponder
{
  BOOL result = [super resignFirstResponder];
  if (result)
  {
    [_eventDispatcher sendTextEventWithType:RCTTextEventTypeBlur
                                   reactTag:self.reactTag
                                       text:[self stringValue]
                                        key:nil
                                 eventCount:_nativeEventCount];
  }
  return result;
}

@end
