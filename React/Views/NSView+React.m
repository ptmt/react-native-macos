/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSView+React.h"
#import <AppKit/AppKit.h>

#import <objc/runtime.h>

#import "RCTAssert.h"
#import "RCTLog.h"

@implementation NSView (React)

- (NSNumber *)reactTag
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setReactTag:(NSNumber *)reactTag
{
  objc_setAssociatedObject(self, @selector(reactTag), reactTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isReactRootView
{
  return RCTIsReactRootView(self.reactTag);
}

//- (NSNumber *)reactTagAtPoint:(CGPoint)point
//{
//  NSView *view = [self hitTest:point withEvent:nil];
//  while (view && !view.reactTag) {
//    view = view.superview;
//  }
//  return view.reactTag;
//}

- (void)insertReactSubview:(NSView *)subview atIndex:(NSInteger)atIndex
{
  [self addSubview:subview];
}

- (void)removeReactSubview:(NSView *)subview
{
  RCTAssert(subview.superview == self, @"%@ is a not a subview of %@", subview, self);
  [subview removeFromSuperview];
}

- (NSArray *)reactSubviews
{
  return self.subviews;
}

- (NSView *)reactSuperview
{
  return self.superview;
}

- (void)reactSetFrame:(CGRect)frame
{
  // These frames are in terms of anchorPoint = topLeft, but internally the
  // views are anchorPoint = center for easier scale and rotation animations.
  // Convert the frame so it works with anchorPoint = center.
  CGPoint position = {CGRectGetMidX(frame), CGRectGetMidY(frame)};
  CGRect bounds = {CGPointZero, frame.size};

  // Avoid crashes due to nan coords
  if (isnan(position.x) || isnan(position.y) ||
      isnan(bounds.origin.x) || isnan(bounds.origin.y) ||
      isnan(bounds.size.width) || isnan(bounds.size.height)) {
    RCTLogError(@"Invalid layout for (%@)%@. position: %d. bounds: %d",
                self.reactTag, self, NSStringFromCGPoint(position), NSStringFromCGRect(bounds));
    return;
  }

  self.layer.position = position;
  self.layer.bounds = bounds;
}

- (void)reactSetInheritedBackgroundColor:(NSColor *)inheritedBackgroundColor
{
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[inheritedBackgroundColor CGColor]];
  [self setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
  [self setLayer:viewLayer];
}

- (NSViewController *)reactViewController
{
  id responder = [self nextResponder];
  while (responder) {
    if ([responder isKindOfClass:[NSViewController class]]) {
      return responder;
    }
    responder = [responder nextResponder];
  }
  return nil;
}

- (void)reactAddControllerToClosestParent:(NSViewController *)controller
{
  if (!controller.parentViewController) {
    NSView *parentView = (NSView *)self.reactSuperview;
    while (parentView) {
      if (parentView.reactViewController) {
        [parentView.reactViewController addChildViewController:controller];
        //[controller didMoveToParentViewController:parentView.reactViewController];
        break;
      }
      parentView = (NSView *)parentView.reactSuperview;
    }
    return;
  }
}

/**
 * Responder overrides - to be deprecated.
 */
- (void)reactWillMakeFirstResponder {};
- (void)reactDidMakeFirstResponder {};
//- (BOOL)reactRespondsToTouch:(__unused UITouch *)touch
//{
//  return YES;
//}

@end
