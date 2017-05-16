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
#import <Foundation/Foundation.h>

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

#if RCT_DEV

- (RCTShadowView *)_DEBUG_reactShadowView
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)_DEBUG_setReactShadowView:(RCTShadowView *)shadowView
{
  // Use assign to avoid keeping the shadowView alive it if no longer exists
  objc_setAssociatedObject(self, @selector(_DEBUG_reactShadowView), shadowView, OBJC_ASSOCIATION_ASSIGN);
}

#endif

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

- (NSUserInterfaceLayoutDirection)reactLayoutDirection
{
  return [objc_getAssociatedObject(self, @selector(reactLayoutDirection)) integerValue];
}

- (void)setReactLayoutDirection:(NSUserInterfaceLayoutDirection)layoutDirection
{
  objc_setAssociatedObject(self, @selector(reactLayoutDirection), @(layoutDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)reactZIndex
{
  return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setReactZIndex:(NSInteger)reactZIndex
{
  objc_setAssociatedObject(self, @selector(reactZIndex), @(reactZIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray<NSView *> *)sortedReactSubviews
{
  NSArray *subviews = objc_getAssociatedObject(self, _cmd);
  if (!subviews) {
    // Check if sorting is required - in most cases it won't be
    BOOL sortingRequired = NO;
    for (NSView *subview in self.reactSubviews) {
      if (subview.reactZIndex != 0) {
        sortingRequired = YES;
        break;
      }
    }
    subviews = sortingRequired ? [self.reactSubviews sortedArrayUsingComparator:^NSComparisonResult(NSView *a, NSView *b) {
      if (a.reactZIndex > b.reactZIndex) {
        return NSOrderedDescending;
      } else {
        // ensure sorting is stable by treating equal zIndex as ascending so
        // that original order is preserved
        return NSOrderedAscending;
      }
    }] : self.reactSubviews;
    objc_setAssociatedObject(self, _cmd, subviews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return subviews;
}

// private method, used to reset sort
- (void)clearSortedSubviews
{
  objc_setAssociatedObject(self, @selector(sortedReactSubviews), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)didUpdateReactSubviews
{
  for (NSView *subview in self.sortedReactSubviews) {
    [self addSubview:subview];
  }
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

  // Avoid crashes due to nan coords
  if (isnan(position.x) || isnan(position.y) ||
      isnan(bounds.origin.x) || isnan(bounds.origin.y) ||
      isnan(bounds.size.width) || isnan(bounds.size.height)) {
    RCTLogError(@"Invalid layout for (%@)%@", self.reactTag, self);
    return;
  }

  self.frame = frame;

  // TODO: why position matters? It's only produce bugs
  // self.layer.position = position;
  self.layer.bounds = bounds;
}

- (void)reactSetInheritedBackgroundColor:(NSColor *)inheritedBackgroundColor
{
  if (![self wantsLayer]) {
    [self setWantsLayer:YES];
  }
  [self.layer setBackgroundColor:[inheritedBackgroundColor CGColor]];

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
  if (![self becomeFirstResponder]) {
    self.reactIsFocusNeeded = YES;
  }
}

- (void)reactFocusIfNeeded {
  if (self.reactIsFocusNeeded) {
    if ([self becomeFirstResponder]) {
      self.reactIsFocusNeeded = NO;
    }
  }
}

- (void)reactBlur {
  [self resignFirstResponder];
}

@end
