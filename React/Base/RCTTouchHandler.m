/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTouchHandler.h"

#import <AppKit/AppKit.h>

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTUIManager.h"
#import "RCTUtils.h"
#import "NSView+React.h"

// TODO: this class behaves a lot like a module, and could be implemented as a
// module if we were to assume that modules and RootViews had a 1:1 relationship
@implementation RCTTouchHandler
{
  __weak RCTBridge *_bridge;

  /**
   * Arrays managed in parallel tracking native touch object along with the
   * native view that was touched, and the React touch data dictionary.
   * These must be kept track of because `UIKit` destroys the touch targets
   * if touches are canceled, and we have no other way to recover this info.
   */
  NSMutableOrderedSet *_nativeTouches;
  NSMutableArray *_reactTouches;
  NSMutableArray *_touchViews;

  BOOL _dispatchedInitialTouches;
  BOOL _recordingInteractionTiming;
  CFTimeInterval _mostRecentEnqueueJS;

  /*
   * Storing tag to dispatch mouseEnter and mouseLeave events
   */
  NSNumber *_currentMouseOverTag;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  RCTAssertParam(bridge);

  if ((self = [super initWithTarget:self action:@selector(handleGesture:)])) {

    _bridge = bridge;
    _dispatchedInitialTouches = NO;
    _nativeTouches = [NSMutableOrderedSet new];
    _reactTouches = [NSMutableArray new];
    _touchViews = [NSMutableArray new];

    // `cancelsTouchesInView` is needed in order to be used as a top level
    // event delegated recognizer. Otherwise, lower-level components not built
    // using RCT, will fail to recognize gestures.
    //self.cancelsTouchesInView = NO; TODO:
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithTarget:(id)target action:(SEL)action)

RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)coder)

typedef NS_ENUM(NSInteger, RCTTouchEventType) {
  RCTTouchEventTypeStart,
  RCTTouchEventTypeMove,
  RCTTouchEventTypeEnd,
  RCTTouchEventTypeCancel
};

#pragma mark - Bookkeeping for touch indices

- (void)_recordNewTouches:(NSSet *)touches
{
  for (NSEvent *touch in touches) {

    NSUInteger index = [_nativeTouches indexOfObjectPassingTest:^BOOL(id obj, __unused NSUInteger idx, __unused BOOL *stop) {
      return touch.eventNumber == ((NSEvent *)obj).eventNumber;
    }];

    RCTAssert(index == NSNotFound,
              @"Touch is already recorded. This is a critical bug.");

    // TODO: This is a highly disgusting workaround. Need to find out how to get right position to make a hit test.
    // At the moment, because the view is flipped we compensate the header's height manually.
    NSPoint touchLocation = CGPointMake([touch locationInWindow].x, (self.view.window.frame.size.height - 25 - [touch locationInWindow].y));

    // TODO: fix hardcoded components name.
    //
    // Check if item is becoming first responder to delete touch
    NSView *targetView = [self.view hitTest:touchLocation];

    if (![targetView.className isEqualToString:@"RCTText"] && ![targetView.className isEqualToString:@"RCTView"]) {
      self.state = NSGestureRecognizerStateEnded;
      return;
    }

    NSNumber *reactTag = [self.view reactTagAtPoint:CGPointMake(touchLocation.x, touchLocation.y)];

    NSLog(@"touchLocation: %f %f %@", touchLocation.x, touchLocation.y, reactTag);

    if (!reactTag) {// || !targetView.userInteractionEnabled) {
      return;
    }

    // Get new, unique touch identifier for the react touch
    const NSUInteger RCTMaxTouches = 11; // This is the maximum supported by iDevices
    NSInteger touchID = ([_reactTouches.lastObject[@"identifier"] integerValue] + 1) % RCTMaxTouches;
    for (NSDictionary *reactTouch in _reactTouches) {
      NSInteger usedID = [reactTouch[@"identifier"] integerValue];
      if (usedID == touchID) {
        // ID has already been used, try next value
        touchID ++;
      } else if (usedID > touchID) {
        // If usedID > touchID, touchID must be unique, so we can stop looking
        break;
      }
    }

    // Create touch
    NSMutableDictionary *reactTouch = [[NSMutableDictionary alloc] initWithCapacity:9];
    reactTouch[@"target"] = reactTag;
    reactTouch[@"identifier"] = @(touchID);
    reactTouch[@"touches"] = (id)kCFNull;        // We hijack this touchObj to serve both as an event
    reactTouch[@"changedTouches"] = (id)kCFNull; // and as a Touch object, so making this JIT friendly.

    // Add to arrays
    [_touchViews addObject:targetView];
    [_nativeTouches addObject:touch];
    [_reactTouches addObject:reactTouch];
  }
}

- (void)_recordRemovedTouches:(NSSet *)touches
{
  for (NSEvent *touch in touches) {
    NSUInteger index = [_nativeTouches indexOfObjectPassingTest:^BOOL(id obj, __unused NSUInteger idx, __unused BOOL *stop) {
      return touch.eventNumber == ((NSEvent *)obj).eventNumber;
    }];
    if(index == NSNotFound) {
      continue;
    }

    [_touchViews removeObjectAtIndex:index];
    [_nativeTouches removeObjectAtIndex:index];
    [_reactTouches removeObjectAtIndex:index];
  }
}

- (void)_updateReactTouchAtIndex:(NSInteger)touchIndex
{
  // TODO: actual coordinates
  NSEvent *nativeTouch = _nativeTouches[touchIndex];
 // CGPoint windowLocation = self.view.window.frame.origin;
  CGPoint rootViewLocation = [nativeTouch locationInWindow];//[self.view.window convertPoint:windowLocation toView:self.view];

 // NSView *touchView = _touchViews[touchIndex];
  CGPoint touchViewLocation = rootViewLocation;//[nativeTouch locatiion][nativeTouch.window convertPoint:windowLocation toView:touchView];

  NSMutableDictionary *reactTouch = _reactTouches[touchIndex];
  reactTouch[@"pageX"] = @(rootViewLocation.x);
  reactTouch[@"pageY"] = @(rootViewLocation.y);
  reactTouch[@"locationX"] = @(touchViewLocation.x);
  reactTouch[@"locationY"] = @(touchViewLocation.y);
  reactTouch[@"timestamp"] =  @(nativeTouch.timestamp * 1000); // in ms, for JS
}

/**
 * Constructs information about touch events to send across the serialized
 * boundary. This data should be compliant with W3C `Touch` objects. This data
 * alone isn't sufficient to construct W3C `Event` objects. To construct that,
 * there must be a simple receiver on the other side of the bridge that
 * organizes the touch objects into `Event`s.
 *
 * We send the data as an array of `Touch`es, the type of action
 * (start/end/move/cancel) and the indices that represent "changed" `Touch`es
 * from that array.
 */
- (void)_updateAndDispatchTouches:(NSSet *)touches
                        eventName:(NSString *)eventName
                  originatingTime:(__unused CFTimeInterval)originatingTime
{
  NSMutableArray *changedIndexes = [NSMutableArray new];
  for (NSEvent *touch in touches) {
    NSUInteger index = [_nativeTouches indexOfObjectPassingTest:^BOOL(id obj, __unused NSUInteger idx, __unused BOOL *stop) {
      return touch.eventNumber == ((NSEvent *)obj).eventNumber;
    }];
    if (index == NSNotFound) {
      continue;
    }

    [self _updateReactTouchAtIndex:index];
    [changedIndexes addObject:@(index)];
  }

  if (changedIndexes.count == 0) {
    return;
  }

  // Deep copy the touches because they will be accessed from another thread
  // TODO: would it be safer to do this in the bridge or executor, rather than trusting caller?
  NSMutableArray *reactTouches = [[NSMutableArray alloc] initWithCapacity:_reactTouches.count];
  for (NSDictionary *touch in _reactTouches) {
    [reactTouches addObject:[touch copy]];
  }
  eventName = RCTNormalizeInputEventName(eventName);
  [_bridge enqueueJSCall:@"RCTEventEmitter.receiveTouches"
                    args:@[eventName, reactTouches, changedIndexes]];
}

#pragma mark - Gesture Recognizer Delegate Callbacks

//static BOOL RCTAllTouchesAreCancelledOrEnded(NSSet *touches)
//{
//  for (NSEvent *touch in touches) {
//
//    if (touch.phase == NSTouchPhaseBegan ||
//        touch.phase == NSTouchPhaseMoved ||
//        touch.phase == NSTouchPhaseStationary) {
//      return NO;
//    }
//  }
//  return YES;
//}
//
//static BOOL RCTAnyTouchesChanged(NSSet *touches)
//{
//  for (NSEvent *touch in touches) {
//    if (touch.phase == NSTouchPhaseBegan ||
//        touch.phase == NSTouchPhaseMoved) {
//      return YES;
//    }
//  }
//  return NO;
//}

- (void)handleGesture:(__unused NSGestureRecognizer *)gestureRecognizer
{
  // If gesture just recognized, send all touches to JS as if they just began.
  if (self.state == NSGestureRecognizerStateBegan) {
    [self _updateAndDispatchTouches:_nativeTouches.set eventName:@"topTouchStart" originatingTime:0];

    // We store this flag separately from `state` because after a gesture is
    // recognized, its `state` changes immediately but its action (this
    // method) isn't fired until dependent gesture recognizers have failed. We
    // only want to send move/end/cancel touches if we've sent the touchStart.
    _dispatchedInitialTouches = YES;
  }

  // For the other states, we could dispatch the updates here but since we
  // specifically send info about which touches changed, it's simpler to
  // dispatch the updates from the raw touch methods below.
}

- (void)mouseDown:(NSEvent *)event
{
  [super mouseDown:event];

  // "start" has to record new touches before extracting the event.
  // "end"/"cancel" needs to remove the touch *after* extracting the event.
  NSSet *touches = [NSSet setWithObject:event];
  [self _recordNewTouches:touches];
  if (_dispatchedInitialTouches) {
    [self _updateAndDispatchTouches:touches eventName:@"touchStart" originatingTime:event.timestamp];
    self.state = NSGestureRecognizerStateChanged;
  } else {
    self.state = NSGestureRecognizerStateBegan;
  }
}

- (void)mouseDragged:(NSEvent *)event
{
  [super mouseDragged:event];

  NSSet *touches = [NSSet setWithObject:event];
  if (_dispatchedInitialTouches) {
    [self _updateAndDispatchTouches:touches eventName:@"touchMove" originatingTime:event.timestamp];
    self.state = NSGestureRecognizerStateChanged;
  }
}

- (void)mouseMoved:(NSEvent *)event
{
  NSPoint touchLocation = CGPointMake([event locationInWindow].x, (self.view.window.frame.size.height - 25 - [event locationInWindow].y));
  NSNumber *reactTag = [self.view reactTagAtPoint:CGPointMake(touchLocation.x, touchLocation.y)];
  if (reactTag == nil) {
    return;
  }
  if (_currentMouseOverTag != reactTag && _currentMouseOverTag > 0) {
    [_bridge enqueueJSCall:@"RCTEventEmitter.receiveEvent"
                        args:@[_currentMouseOverTag, @"topMouseLeave"]];
    [_bridge enqueueJSCall:@"RCTEventEmitter.receiveEvent"
                      args:@[reactTag, @"topMouseEnter"]];
    _currentMouseOverTag = reactTag;
  } else if (_currentMouseOverTag == 0) {
    [_bridge enqueueJSCall:@"RCTEventEmitter.receiveEvent"
                      args:@[reactTag, @"topMouseEnter"]];
    _currentMouseOverTag = reactTag;
  }

}

- (void)mouseUp:(NSEvent *)event
{
  [super mouseUp:event];

  NSSet *touches = [NSSet setWithObject:event];
  if (_dispatchedInitialTouches) {

    [self _updateAndDispatchTouches:touches eventName:@"touchEnd" originatingTime:event.timestamp];

    self.state = NSGestureRecognizerStateEnded;
  }
  [self _recordRemovedTouches:touches];
}

// Mouse move events https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/EventOverview/MouseTrackingEvents/MouseTrackingEvents.html

- (BOOL)canPreventGestureRecognizer:(__unused NSGestureRecognizer *)preventedGestureRecognizer
{
  return NO;
}

- (BOOL)canBePreventedByGestureRecognizer:(__unused NSGestureRecognizer *)preventingGestureRecognizer
{
  return NO;
}

- (void)reset
{
  _dispatchedInitialTouches = NO;
}

@end
