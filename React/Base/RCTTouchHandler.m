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
#import "RCTTouchEvent.h"
#import "RCTLog.h"
#import "RCTUIManager.h"
#import "RCTUtils.h"
#import "NSView+React.h"

@interface RCTTouchHandler () <NSGestureRecognizerDelegate>
@end

// TODO: this class behaves a lot like a module, and could be implemented as a
// module if we were to assume that modules and RootViews had a 1:1 relationship
@implementation RCTTouchHandler
{
  __weak RCTBridge *_bridge;
  __weak RCTEventDispatcher *_eventDispatcher;

  /**
   * Arrays managed in parallel tracking native touch object along with the
   * native view that was touched, and the React touch data dictionary.
   * These must be kept track of because `UIKit` destroys the touch targets
   * if touches are canceled, and we have no other way to recover this info.
   */
  NSMutableOrderedSet<NSEvent *> *_nativeTouches;
  NSMutableArray<NSMutableDictionary *> *_reactTouches;
  NSMutableArray<NSView *> *_touchViews;

  uint16_t _coalescingKey;
  
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

  if ((self = [super initWithTarget:nil action:NULL])) {
    _bridge = bridge;
    _eventDispatcher = [bridge moduleForClass:[RCTEventDispatcher class]];

    _nativeTouches = [NSMutableOrderedSet new];
    _reactTouches = [NSMutableArray new];
    _touchViews = [NSMutableArray new];

    // `cancelsTouchesInView` and `delaysTouches*` are needed in order to be used as a top level
    // event delegated recognizer. Otherwise, lower-level components not built
    // using RCT, will fail to recognize gestures.
    
    self.delegate = self;
  }

  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithTarget:(id)target action:(SEL)action)

- (void)attachToView:(NSView *)view
{
  RCTAssert(self.view == nil, @"RCTTouchHandler already has attached view.");

  [view addGestureRecognizer:self];
}

- (void)detachFromView:(NSView *)view
{
  RCTAssertParam(view);
  RCTAssert(self.view == view, @"RCTTouchHandler attached to another view.");

  [view removeGestureRecognizer:self];
}

#pragma mark - Bookkeeping for touch indices

- (void)_recordNewTouches:(NSSet<NSEvent *> *)touches
{
  for (NSEvent *touch in touches) {

    NSUInteger index = [_nativeTouches indexOfObjectPassingTest:^BOOL(id obj, __unused NSUInteger idx, __unused BOOL *stop) {
      return touch.eventNumber == ((NSEvent *)obj).eventNumber;
    }];

    RCTAssert(index == NSNotFound,
              @"Touch is already recorded. This is a critical bug.");

    NSPoint touchLocation = [touch locationInWindow];

    if ([[self.view window].className isEqualToString:@"_NSPopoverWindow"]) {
      // adjust touchLocation if our view placed inside custom PopoverWindow
      NSPoint rootOrigin = [self.view window].contentView.frame.origin;
      touchLocation = NSMakePoint(touchLocation.x - rootOrigin.x, touchLocation.y - rootOrigin.y);
    } else if (self.view.superview) {
      // if our view has a superview, adjust the window coordinates to view coordinates.
      touchLocation = [touch.window.contentView convertPoint:touchLocation toView:self.view.superview];
    }

    // TODO: get rid of explicit comparison
    //
    // Check if item is becoming first responder to delete touch
    NSView *targetView = [self.view hitTest:touchLocation];

    if (![targetView.className isEqualToString:@"RCTView"] &&
        ![targetView.className isEqualToString:@"RCTTextView"] &&
        ![targetView.className isEqualToString:@"RCTImageView"] &&
        ![targetView.className isEqualToString:@"ARTSurfaceView"]) {
      self.state = NSGestureRecognizerStateEnded;
      return;
    }

    NSNumber *reactTag = [self.view reactTagAtPoint:CGPointMake(touchLocation.x, touchLocation.y)];

    if (!reactTag) {
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

- (void)_recordRemovedTouches:(NSSet<NSEvent *> *)touches
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

- (void)_updateReactTouchAtIndex:(NSInteger)touchIndex withNativeTouch:(NSEvent *)nativeTouch
{
  CGPoint location = [nativeTouch locationInWindow];
  CGPoint flippedLocation = CGPointMake(location.x, self.view.window.frame.size.height - location.y);

  // adjust touchLocation if our view placed inside custom PopoverWindow
  if ([[self.view window].className isEqualToString:@"_NSPopoverWindow"]) {
    NSPoint rootOrigin = [self.view window].contentView.frame.origin;
    flippedLocation = NSMakePoint(flippedLocation.x - rootOrigin.x, flippedLocation.y - rootOrigin.y);
  }

  NSMutableDictionary *reactTouch = _reactTouches[touchIndex];
  reactTouch[@"pageX"] = @(RCTSanitizeNaNValue(flippedLocation.x, @"touchEvent.pageX"));
  reactTouch[@"pageY"] = @(RCTSanitizeNaNValue(flippedLocation.y, @"touchEvent.pageY"));
  reactTouch[@"locationX"] = @(RCTSanitizeNaNValue(flippedLocation.x, @"touchEvent.locationX"));
  reactTouch[@"locationY"] = @(RCTSanitizeNaNValue(flippedLocation.y, @"touchEvent.locationY"));
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
- (void)_updateAndDispatchTouches:(NSSet<NSEvent *> *)touches
                        eventName:(NSString *)eventName
{
  NSMutableArray *changedIndexes = [NSMutableArray new];
  for (NSEvent *touch in touches) {
    NSUInteger index = [_nativeTouches indexOfObjectPassingTest:^BOOL(id obj, __unused NSUInteger idx, __unused BOOL *stop) {
      return touch.eventNumber == ((NSEvent *)obj).eventNumber;
    }];
    if (index == NSNotFound) {
      continue;
    }

    [self _updateReactTouchAtIndex:index withNativeTouch:touch];
    [changedIndexes addObject:@(index)];
  }

  if (changedIndexes.count == 0) {
    return;
  }

  // Deep copy the touches because they will be accessed from another thread
  // TODO: would it be safer to do this in the bridge or executor, rather than trusting caller?
  NSMutableArray<NSDictionary *> *reactTouches =
  [[NSMutableArray alloc] initWithCapacity:_reactTouches.count];
  for (NSDictionary *touch in _reactTouches) {
    [reactTouches addObject:[touch copy]];
  }

  BOOL canBeCoalesced = [eventName isEqualToString:@"touchMove"];

  // We increment `_coalescingKey` twice here just for sure that
  // this `_coalescingKey` will not be reused by ahother (preceding or following) event
  // (yes, even if coalescing only happens (and makes sense) on events of the same type).

  if (!canBeCoalesced) {
    _coalescingKey++;
  }

  RCTTouchEvent *event = [[RCTTouchEvent alloc] initWithEventName:eventName
                                                         reactTag:self.view.reactTag
                                                     reactTouches:reactTouches
                                                   changedIndexes:changedIndexes
                                                    coalescingKey:_coalescingKey];

  if (!canBeCoalesced) {
    _coalescingKey++;
  }
  [_eventDispatcher sendEvent:event];
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

- (void)handleGesture
{
  // If gesture just recognized, send all touches to JS as if they just began.
  if (self.state == NSGestureRecognizerStateBegan) {
    [self _updateAndDispatchTouches:_nativeTouches.set eventName:@"topTouchStart"];
    
    // We store this flag separately from `state` because after a gesture is
    // recognized, its `state` changes immediately but its action (this
    // method) isn't fired until dependent gesture recognizers have failed. We
    // only want to send move/end/cancel touches if we've sent the touchStart.
    _dispatchedInitialTouches = YES;
  }
}

#pragma mark - `UIResponder`-ish touch-delivery methods

- (void)mouseDown:(NSEvent *)event
{
  [super mouseDown:event];

  // "start" has to record new touches *before* extracting the event.
  // "end"/"cancel" needs to remove the touch *after* extracting the event.
  NSSet *touches = [NSSet setWithObject:event];
  [self _recordNewTouches:touches];

  [self _updateAndDispatchTouches:touches eventName:@"touchStart"];

  if (self.state == NSGestureRecognizerStatePossible) {
    self.state = NSGestureRecognizerStateBegan;
  } else if (self.state == NSGestureRecognizerStateBegan) {
    self.state = NSGestureRecognizerStateChanged;
  }
  [self handleGesture];
}

- (void)mouseDragged:(NSEvent *)event
{
  [super mouseDragged:event];
  
  NSSet *touches = [NSSet setWithObject:event];
  if (_dispatchedInitialTouches) {
    [self _updateAndDispatchTouches:touches eventName:@"touchMove"];
    self.state = NSGestureRecognizerStateChanged;
  }
}

- (void)mouseMoved:(NSEvent *)event
{
  NSPoint touchLocation = [event locationInWindow];
  NSNumber *reactTag = [self.view reactTagAtPoint:touchLocation];
  if (reactTag == nil) {
    return;
  }
  if (_currentMouseOverTag != reactTag && _currentMouseOverTag.intValue > 0) {
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
    
    [self _updateAndDispatchTouches:touches eventName:@"touchEnd"];
    
    self.state = NSGestureRecognizerStateEnded;
  }
  [self _recordRemovedTouches:touches];
}


- (BOOL)canPreventGestureRecognizer:(__unused NSGestureRecognizer *)preventedGestureRecognizer
{
  return NO;
}

- (BOOL)canBePreventedByGestureRecognizer:(NSGestureRecognizer *)preventingGestureRecognizer
{
  // We fail in favour of other external gesture recognizers.
  // iOS will ask `delegate`'s opinion about this gesture recognizer little bit later.
  // return ![preventingGestureRecognizer.view isDescendantOfView:self.view];
  return NO;
}

- (void)reset
{
  if (_nativeTouches.count != 0) {
    [self _updateAndDispatchTouches:_nativeTouches.set eventName:@"touchCancel"];

    [_nativeTouches removeAllObjects];
    [_reactTouches removeAllObjects];
    [_touchViews removeAllObjects];
  }
}

#pragma mark - Other

- (void)cancel
{
  self.enabled = NO;
  self.enabled = YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(__unused NSGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(NSGestureRecognizer *)otherGestureRecognizer
{
  // Same condition for `failure of` as for `be prevented by`.
  return [self canBePreventedByGestureRecognizer:otherGestureRecognizer];
}

@end
