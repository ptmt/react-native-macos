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
#import <QuartzCore/CoreAnimation.h>

#import <objc/runtime.h>

#import "RCTAssert.h"
#import "RCTLog.h"
#import "RCTShadowView.h"

@implementation NSView (React)

- (NSNumber *)reactTag
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setReactTag:(NSNumber *)reactTag
{
  objc_setAssociatedObject(self, @selector(reactTag), reactTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)nativeID
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setNativeID:(NSNumber *)nativeID
{
  objc_setAssociatedObject(self, @selector(nativeID), nativeID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isReactRootView
{
  return RCTIsReactRootView(self.reactTag);
}

- (NSNumber *)reactTagAtPoint:(CGPoint)point
{
  NSView *view = [self hitTest:point];
  while (view && !view.reactTag) {
    view = view.superview;
  }
  return view.reactTag;
}

- (NSArray<NSView *> *)reactSubviews
{
  return objc_getAssociatedObject(self, _cmd);
}

- (NSView *)reactSuperview
{
  return self.superview;
}

- (void)insertReactSubview:(NSView *)subview atIndex:(NSInteger)atIndex
{
  // We access the associated object directly here in case someone overrides
  // the `reactSubviews` getter method and returns an immutable array.
  NSMutableArray *subviews = objc_getAssociatedObject(self, @selector(reactSubviews));
  if (!subviews) {
    subviews = [NSMutableArray new];
    objc_setAssociatedObject(self, @selector(reactSubviews), subviews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  [subviews insertObject:subview atIndex:atIndex];
}

- (void)removeReactSubview:(NSView *)subview
{
  // We access the associated object directly here in case someone overrides
  // the `reactSubviews` getter method and returns an immutable array.
  NSMutableArray *subviews = objc_getAssociatedObject(self, @selector(reactSubviews));
  [subviews removeObject:subview];
  [subview removeFromSuperview];
}

#pragma mark - Display

- (YGDisplay)reactDisplay
{
  return self.isHidden ? YGDisplayNone : YGDisplayFlex;
}

- (void)setReactDisplay:(YGDisplay)display
{
  self.hidden = display == YGDisplayNone;
}

#pragma mark - Layout Direction

- (NSUserInterfaceLayoutDirection)reactLayoutDirection
{
  return [objc_getAssociatedObject(self, @selector(reactLayoutDirection)) integerValue];
}

- (void)setReactLayoutDirection:(NSUserInterfaceLayoutDirection)layoutDirection
{
  objc_setAssociatedObject(self, @selector(reactLayoutDirection), @(layoutDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - zIndex

- (NSInteger)reactZIndex
{
  return self.layer.zPosition;
}

- (void)setReactZIndex:(NSInteger)reactZIndex
{
  self.layer.zPosition = reactZIndex;
}

- (NSArray<NSView *> *)reactZIndexSortedSubviews
{
  // Check if sorting is required - in most cases it won't be.
  BOOL sortingRequired = NO;
  for (NSView *subview in self.subviews) {
    if (subview.reactZIndex != 0) {
      sortingRequired = YES;
      break;
    }
  }
  return sortingRequired ? [self.reactSubviews sortedArrayUsingComparator:^NSComparisonResult(NSView *a, NSView *b) {
    if (a.reactZIndex > b.reactZIndex) {
      return NSOrderedDescending;
    } else {
      // Ensure sorting is stable by treating equal zIndex as ascending so
      // that original order is preserved.
      return NSOrderedAscending;
    }
  }] : self.subviews;
}

- (void)didUpdateReactSubviews
{
  for (NSView *subview in self.reactSubviews) {
    [self addSubview:subview];
  }
}

- (void)didSetProps:(__unused NSArray<NSString *> *)changedProps
{
  // The default implementation does nothing.
}

- (void)reactSetFrame:(CGRect)frame
{
//  if ([self respondsToSelector:@selector(respondsToLiveResizing)]) {
//
//  } else {
//    NSLog(@"%@", self.reactTag);
//  }
  // These frames are in terms of anchorPoint = topLeft, but internally the
  // views are anchorPoint = center for easier scale and rotation animations.
  // Convert the frame so it works with anchorPoint = center.
  CGPoint position = {CGRectGetMidX(frame), CGRectGetMidY(frame)};
  CGRect bounds = {CGPointZero, frame.size};
  CGPoint anchor = {0.5, 0.5};
  
  // Avoid crashes due to nan coords
  if (isnan(position.x) || isnan(position.y) ||
      isnan(bounds.origin.x) || isnan(bounds.origin.y) ||
      isnan(bounds.size.width) || isnan(bounds.size.height)) {
    RCTLogError(@"Invalid layout for (%@)%@", self.reactTag, self);
    return;
  }

  self.frame = frame;
  
  // TODO: why position matters? It's only produce bugs
  // OSX requires position and anchor point to rotate from center
  self.layer.position = position;
  self.layer.bounds = bounds;
  self.layer.anchorPoint = anchor;
}

- (NSViewController *)reactViewController
{
  id responder = [self nextResponder];
  if (responder == nil) {
    NSView *rootCandidate = self.reactSuperview;
    return rootCandidate.reactViewController;
  }
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
 * Focus manipulation.
 */
- (BOOL)reactIsFocusNeeded
{
  return [(NSNumber *)objc_getAssociatedObject(self, @selector(reactIsFocusNeeded)) boolValue];
}

- (void)setReactIsFocusNeeded:(BOOL)isFocusNeeded
{
  objc_setAssociatedObject(self, @selector(reactIsFocusNeeded), @(isFocusNeeded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)reactFocus {
  if (![self.window makeFirstResponder:self]) {
    self.reactIsFocusNeeded = YES;
  }
}

- (void)reactFocusIfNeeded {
  if (self.reactIsFocusNeeded) {
    if ([self.window makeFirstResponder:self]) {
      self.reactIsFocusNeeded = NO;
    }
  }
}

- (void)reactBlur {
  if (self == self.window.firstResponder) {
    [self.window makeFirstResponder:nil];
  }
}

#pragma mark - Layout

- (NSEdgeInsets)reactBorderInsets
{
  CGFloat borderWidth = self.layer.borderWidth;
  return NSEdgeInsetsMake(borderWidth, borderWidth, borderWidth, borderWidth);
}

- (NSEdgeInsets)reactPaddingInsets
{
  return NSEdgeInsetsZero;
}

- (NSEdgeInsets)reactCompoundInsets
{
  NSEdgeInsets borderInsets = self.reactBorderInsets;
  NSEdgeInsets paddingInsets = self.reactPaddingInsets;

  return NSEdgeInsetsMake(
    borderInsets.top + paddingInsets.top,
    borderInsets.left + paddingInsets.left,
    borderInsets.bottom + paddingInsets.bottom,
    borderInsets.right + paddingInsets.right
  );
}

static inline CGRect NSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
  rect.origin.x    += insets.left;
  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.left + insets.right);
  rect.size.height -= (insets.top  + insets.bottom);
  return rect;
}

- (CGRect)reactContentFrame
{
  return NSEdgeInsetsInsetRect(self.bounds, self.reactCompoundInsets);
}

#pragma mark - Accessiblity

- (NSView *)reactAccessibilityElement
{
  return self;
}

#pragma mark - Interaction

- (NSView *)reactHitTest:(NSPoint)point
{
  NSView *view = [self hitTest:point];
  while (view && !view.reactTag) {
    view = view.superview;
  }
  return view;
}

#pragma mark - UIKit parity

+ (void)performWithoutAnimation:(void (^)(void))actionsWithoutAnimation
{
  [CATransaction begin];
  [CATransaction setValue:(id)kCFBooleanTrue
                   forKey:kCATransactionDisableActions];
  actionsWithoutAnimation();
  [CATransaction commit];
}

@end
