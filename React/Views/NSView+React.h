/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import <React/RCTComponent.h>
#import <yoga/YGEnums.h>

@class RCTShadowView;

@interface NSView (React) <RCTComponent>

/**
 * RCTComponent interface.
 */
- (NSArray<NSView *> *)reactSubviews NS_REQUIRES_SUPER;
- (NSView *)reactSuperview NS_REQUIRES_SUPER;
- (void)insertReactSubview:(NSView *)subview atIndex:(NSInteger)atIndex NS_REQUIRES_SUPER;
- (void)removeReactSubview:(NSView *)subview NS_REQUIRES_SUPER;

/**
 * The native id of the view, used to locate view from native codes
 */
@property (nonatomic, copy) NSString *nativeID;

/**
 * Layout direction of the view.
 * Internally backed to `semanticContentAttribute` property.
 * Defaults to `LeftToRight` in case of ambiguity.
 */
@property (nonatomic, assign) NSUserInterfaceLayoutDirection reactLayoutDirection;

/**
 * Yoga `display` style property. Can be `flex` or `none`.
 * Defaults to `flex`.
 * May be used to temporary hide the view in a very efficient way.
 */
@property (nonatomic, assign) YGDisplay reactDisplay;

/**
 * The z-index of the view.
 */
@property (nonatomic, assign) NSInteger reactZIndex;

/**
 * Subviews sorted by z-index. Note that this method doesn't do any caching (yet)
 * and sorts all the views each call.
 */
- (NSArray<NSView *> *)reactZIndexSortedSubviews;

/**
 * Updates the subviews array based on the reactSubviews. Default behavior is
 * to insert the sortedReactSubviews into the UIView.
 */
- (void)didUpdateReactSubviews;

/**
 * Called each time props have been set.
 * The default implementation does nothing.
 */
- (void)didSetProps:(NSArray<NSString *> *)changedProps;

/**
 * Used by the UIIManager to set the view frame.
 * May be overriden to disable animation, etc.
 */
- (void)reactSetFrame:(CGRect)frame;

/**
 * This method finds and returns the containing view controller for the view.
 */
- (NSViewController *)reactViewController;

/**
 * This method attaches the specified controller as a child of the
 * the owning view controller of this view. Returns NO if no view
 * controller is found (which may happen if the view is not currently
 * attached to the view hierarchy).
 */
- (void)reactAddControllerToClosestParent:(NSViewController *)controller;

/**
 * Focus manipulation.
 */
- (void)reactFocus;
- (void)reactFocusIfNeeded;
- (void)reactBlur;

/**
 * Useful properties for computing layout.
 */
@property (nonatomic, readonly) NSEdgeInsets reactBorderInsets;
@property (nonatomic, readonly) NSEdgeInsets reactPaddingInsets;
@property (nonatomic, readonly) NSEdgeInsets reactCompoundInsets;
@property (nonatomic, readonly) CGRect reactContentFrame;

/**
 * The (sub)view which represents this view in terms of accessibility.
 * ViewManager will apply all accessibility properties directly to this view.
 * May be overriten in view subclass which needs to be accessiblitywise
 * transparent in favour of some subview.
 * Defaults to `self`.
 */
@property (nonatomic, readonly) NSView *reactAccessibilityElement;

/*
 * UIKit replacement
 */
@property (nonatomic, assign) BOOL clipsToBounds;

- (NSView *)reactHitTest:(NSPoint)point;

+ (void)performWithoutAnimation:(void (^)(void))actionsWithoutAnimation;

@end
