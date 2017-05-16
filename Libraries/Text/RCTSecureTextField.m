/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTSecureTextField.h"

#import "React/RCTConvert.h"
#import "React/RCTEventDispatcher.h"
#import "React/RCTUtils.h"
#import "React/NSView+React.h"

@implementation RCTSecureTextField
{
  RCTEventDispatcher *_eventDispatcher;
  NSMutableArray *_reactSubviews;
  BOOL _jsRequestingFirstResponder;
  NSInteger _nativeEventCount;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  if ((self = [super initWithFrame:CGRectZero])) {
    RCTAssert(eventDispatcher, @"eventDispatcher is a required parameter");
    _eventDispatcher = eventDispatcher;
    self.delegate = self;
    self.drawsBackground = NO;
    self.bordered = NO;
    self.bezeled = YES;

    _reactSubviews = [NSMutableArray new];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (void)setText:(NSString *)text
{
  NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;
  if (eventLag == 0 && ![text isEqualToString:[self stringValue]]) {
    //NSRange *selection = [self value]
    [self setStringValue:text];
    //self.selectedTextRange = selection; // maintain cursor position/selection - this is robust to out of bounds
  } else if (eventLag > RCTTextUpdateLagWarningThreshold) {
    RCTLogWarn(@"Native TextInput(%@) is %zd events ahead of JS - try to make your JS faster.", [self stringValue], eventLag);
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

- (BOOL)becomeFirstResponder
{
  _jsRequestingFirstResponder = YES;
  BOOL result = [super becomeFirstResponder];
  _jsRequestingFirstResponder = NO;
  return result;
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

- (BOOL)canBecomeFirstResponder
{
  return _jsRequestingFirstResponder;
}

@end
