/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTSecureTextField.h"

#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import "NSView+React.h"

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

- (void)setBackgroundColor:(NSString *)backgroundColor
{
  if (backgroundColor) {
    [self setDrawsBackground:YES];
    [self.cell setBackgroundColor:backgroundColor];
  }
}

- (NSArray *)reactSubviews
{
  // TODO: do we support subviews of textfield in React?
  // In any case, we should have a better approach than manually
  // maintaining array in each view subclass like this
  return _reactSubviews;
}

- (void)removeReactSubview:(NSView *)subview
{
  // TODO: this is a bit broken - if the TextField inserts any of
  // its own views below or between React's, the indices won't match
  [_reactSubviews removeObject:subview];
  [subview removeFromSuperview];
}

- (void)insertReactSubview:(NSView *)view atIndex:(NSInteger)atIndex
{
  // TODO: this is a bit broken - if the TextField inserts any of
  // its own views below or between React's, the indices won't match
  [_reactSubviews insertObject:view atIndex:atIndex];
  [super addSubview:view];
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

- (NSView *)findNextKeyView:(NSView *)view visisted:(NSMutableSet *)visited
{
  if ([view canBecomeKeyView]) {
    return view;
  }
  [visited addObject:view];

  if ([view subviews] && [view subviews].count > 0) {
    int length = (int) [view subviews].count;
    for (int i=length - 1; i >= 0; i--) {
      if (![visited containsObject:view.subviews[i]] && view.subviews[i].canBecomeKeyView) {
        return view.subviews[i];
      }
      if (![visited containsObject:view.subviews[i]] && view.subviews[i].subviews.count > 0) {
        NSView *found = [self findNextKeyView:view.subviews[i] visisted:visited];
        if (found) {
          return found;
        }
      }
    }
  }

  if ([view superview] && ![visited containsObject:[view superview]]) {
    return [self findNextKeyView:[view superview] visisted:visited];
  } else {
    return nil;
  }
  
}

- (BOOL)becomeFirstResponder
{
  BOOL success = [super becomeFirstResponder];
  if (success)
  {
    NSMutableSet *visitedViews = [NSMutableSet new];
    [visitedViews addObject:self];
    NSTextView* textField = (NSTextView*) [self currentEditor];
    textField.nextKeyView = [self nextKeyView]; //[self findNextKeyView:[self superview] visisted:visitedViews];
    if( [textField respondsToSelector: @selector(setInsertionPointColor:)] ) {
      [textField setInsertionPointColor:[self selectionColor]];
    }
  }
  return success;
}


@end
