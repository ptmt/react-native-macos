/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTWindow.h"

#import "RCTMouseEvent.h"
#import "RCTTouchEvent.h"
#import "NSView+React.h"

@implementation RCTWindow
{
  RCTBridge *_bridge;

  NSMutableDictionary *_mouseInfo;
  NSView *_hoveredView;
  NSView *_clickedView;
  NSEventType _clickType;
  uint16_t _coalescingKey;

  BOOL _inContentView;
  BOOL _enabled;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag)

- (instancetype)initWithBridge:(RCTBridge *)bridge
                   contentRect:(NSRect)contentRect
                     styleMask:(NSWindowStyleMask)style
                         defer:(BOOL)defer
{
  self = [super initWithContentRect:contentRect
                          styleMask:style
                            backing:NSBackingStoreBuffered
                              defer:defer];

  if (self) {
    _bridge = bridge;

    _mouseInfo = [NSMutableDictionary new];
    _mouseInfo[@"changedTouches"] = @[]; // Required for "mouseMove" events
    _mouseInfo[@"identifier"] = @0; // Required for "touch*" events

    self.initialFirstResponder = nil;
    self.autorecalculatesKeyViewLoop = YES;

    // The owner must set "contentView" manually.
    super.contentView = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_javaScriptDidLoad:)
                                                 name:RCTJavaScriptDidLoadNotification
                                               object:bridge];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_bridgeWillReload:)
                                                 name:RCTBridgeWillReloadNotification
                                               object:bridge];
  }

  return self;
}

@dynamic contentView;

- (void)sendEvent:(NSEvent *)event
{
  [super sendEvent:event];

  // Avoid sending JS events too early.
  if (_enabled == NO) {
    return;
  }

  NSEventType type = event.type;

  if (type == NSEventTypeMouseEntered) {
    if (event.trackingArea.owner == self.contentView) {
      _inContentView = YES;
    }
    return;
  }

  if (type == NSEventTypeMouseExited) {
    if (event.trackingArea.owner == self.contentView) {
      _inContentView = NO;

      if (_clickedView) {
        if (_clickType == NSEventTypeLeftMouseDown) {
          [self _sendTouchEvent:@"touchCancel"];
        }
        _clickedView = nil;
        _clickType = 0;
      }

      [self _setHoveredView:nil];
    }
    return;
  }

  if (type != NSEventTypeMouseMoved &&
      type != NSEventTypeLeftMouseDragged &&
      type != NSEventTypeLeftMouseUp &&
      type != NSEventTypeLeftMouseDown &&
      type != NSEventTypeRightMouseUp &&
      type != NSEventTypeRightMouseDown) {
    return;
  }

  NSView *targetView = [self.contentView reactHitTest:event.locationInWindow];
  [self _readMouseEvent:event withTarget:targetView];

  if (_clickedView) {
    if (type == NSEventTypeLeftMouseDragged) {
      if (_clickType == NSEventTypeLeftMouseDown) {
        [self _sendTouchEvent:@"touchMove"];
      }
      return;
    }
  } else {
    if (type == NSEventTypeMouseMoved) {
      if (_inContentView == NO) {
        return; // Ignore "mouseMove" events outside the "contentView"
      }

      [self _setHoveredView:targetView];
      return;
    }

    if (targetView == nil) {
      return;
    }

    if (type == NSEventTypeLeftMouseDown || type == NSEventTypeRightMouseDown) {
      // When the "firstResponder" is a NSTextView, "mouseUp" and "mouseDragged" events are swallowed,
      // so we should skip tracking of "mouseDown" events in order to avoid corrupted state.
      if ([self.firstResponder isKindOfClass:NSTextView.class]) {
        NSView *clickedView = [self.contentView hitTest:event.locationInWindow];
        NSView *fieldEditor = (NSView *)self.firstResponder;
        if ([clickedView isDescendantOf:fieldEditor]) {
          return;
        }

        // Blur the field editor when clicking outside it.
        [self makeFirstResponder:nil];
      }

      if (type == NSEventTypeLeftMouseDown) {
        [self _sendTouchEvent:@"touchStart"];
      }

      _clickedView = targetView;
      _clickType = type;
      return;
    }
  }

  if (type == NSEventTypeLeftMouseUp) {
    if (_clickType == NSEventTypeLeftMouseDown) {
      [self _sendTouchEvent:@"touchEnd"];
      _clickedView = nil;
      _clickType = 0;
    }

    // Update the "hoveredView" now, instead of waiting for the next "mouseMove" event.
    [self _setHoveredView:targetView];
    return;
  }

  if (type == NSEventTypeRightMouseUp) {
    if (_clickType == NSEventTypeRightMouseDown) {
      // Right clicks must end in the same React "ancestor chain" they started in.
      if ([_clickedView isDescendantOf:targetView]) {
        [self _sendMouseEvent:@"contextMenu"];
      }
      _clickedView = nil;
      _clickType = 0;
    }

    // Update the "hoveredView" now, instead of waiting for the next "mouseMove" event.
    [self _setHoveredView:targetView];
    return;
  }
}

#pragma mark - Private methods

static inline BOOL hasFlag(NSUInteger flags, NSUInteger flag) {
  return (flags & flag) == flag;
}

- (void)_readMouseEvent:(NSEvent *)event withTarget:(NSView *)view
{
  CGPoint absoluteLocation = event.locationInWindow;
  CGPoint relativeLocation = [self.contentView convertPoint:absoluteLocation toView:view];

  _mouseInfo[@"pageX"] = @(RCTSanitizeNaNValue(absoluteLocation.x, @"touchData.pageX"));
  _mouseInfo[@"pageY"] = @(RCTSanitizeNaNValue(absoluteLocation.y, @"touchData.pageY"));
  _mouseInfo[@"locationX"] = @(RCTSanitizeNaNValue(relativeLocation.x, @"touchData.locationX"));
  _mouseInfo[@"locationY"] = @(RCTSanitizeNaNValue(relativeLocation.x, @"touchData.locationY"));
  _mouseInfo[@"timestamp"] = @(event.timestamp * 1000); // in ms, for JS
  _mouseInfo[@"target"] = view.reactTag;

  NSUInteger flags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
  _mouseInfo[@"altKey"] = @(hasFlag(flags, NSEventModifierFlagOption));
  _mouseInfo[@"ctrlKey"] = @(hasFlag(flags, NSEventModifierFlagControl));
  _mouseInfo[@"metaKey"] = @(hasFlag(flags, NSEventModifierFlagCommand));
  _mouseInfo[@"shiftKey"] = @(hasFlag(flags, NSEventModifierFlagShift));
}

- (void)_setHoveredView:(NSView *)view
{
  if (_hoveredView && !(view && view == _hoveredView)) {
    _mouseInfo[@"target"] = _hoveredView.reactTag;
    _hoveredView = nil;

    [self _sendMouseEvent:@"mouseOut"];
  }

  if (view) {
    _mouseInfo[@"target"] = view.reactTag;

    if (_hoveredView == nil) {
      _hoveredView = view;
      [self _sendMouseEvent:@"mouseOver"];
    }

    [self _sendMouseEvent:@"mouseMove"];
  }
}

- (void)_sendMouseEvent:(NSString *)eventName
{
  RCTMouseEvent *event = [[RCTMouseEvent alloc] initWithEventName:eventName
                                                           target:_mouseInfo[@"target"]
                                                         userInfo:_mouseInfo
                                                    coalescingKey:_coalescingKey];

  if (![eventName isEqualToString:@"mouseMove"]) {
    _coalescingKey++;
  }

  [_bridge.eventDispatcher sendEvent:event];
}

- (void)_sendTouchEvent:(NSString *)eventName
{
  RCTTouchEvent *event = [[RCTTouchEvent alloc] initWithEventName:eventName
                                                         reactTag:self.contentView.reactTag
                                                     reactTouches:@[_mouseInfo]
                                                   changedIndexes:@[@0]
                                                    coalescingKey:_coalescingKey];

  if (![eventName isEqualToString:@"touchMove"]) {
    _coalescingKey++;
  }

  [_bridge.eventDispatcher sendEvent:event];
}

- (void)_javaScriptDidLoad:(__unused NSNotification *)notification
{
  _enabled = YES;
}

- (void)_bridgeWillReload:(__unused NSNotification *)notification
{
  _enabled = NO;
}

@end
