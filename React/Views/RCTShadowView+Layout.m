/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTShadowView+Layout.h"

#import <yoga/Yoga.h>

/**
 * Yoga and CoreGraphics have different opinions about how "infinity" value
 * should be represented.
 * Yoga uses `NAN` which requires additional effort to compare all those values,
 * whereas GoreGraphics uses `GFLOAT_MAX` which can be easyly compared with
 * standard `==` operator.
 */

float RCTYogaFloatFromCoreGraphicsFloat(CGFloat value)
{
  if (value == CGFLOAT_MAX || isnan(value) || isinf(value)) {
    return YGUndefined;
  }

  return value;
}

CGFloat RCTCoreGraphicsFloatFromYogaFloat(float value)
{
  if (value == YGUndefined || isnan(value) || isinf(value)) {
    return CGFLOAT_MAX;
  }

  return value;
}

@implementation RCTShadowView (Layout)

#pragma mark - Computed Layout-Inferred Metrics

- (NSEdgeInsets)paddingAsInsets
{
  YGNodeRef yogaNode = self.yogaNode;
  return (NSEdgeInsets){
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetPadding(yogaNode, YGEdgeTop)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetPadding(yogaNode, YGEdgeLeft)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetPadding(yogaNode, YGEdgeBottom)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetPadding(yogaNode, YGEdgeRight))
  };
}

- (NSEdgeInsets)borderAsInsets
{
  YGNodeRef yogaNode = self.yogaNode;
  return (NSEdgeInsets){
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetBorder(yogaNode, YGEdgeTop)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetBorder(yogaNode, YGEdgeLeft)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetBorder(yogaNode, YGEdgeBottom)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetBorder(yogaNode, YGEdgeRight))
  };
}

- (NSEdgeInsets)compoundInsets
{
  NSEdgeInsets borderAsInsets = self.borderAsInsets;
  NSEdgeInsets paddingAsInsets = self.paddingAsInsets;

  return (NSEdgeInsets){
    borderAsInsets.top + paddingAsInsets.top,
    borderAsInsets.left + paddingAsInsets.left,
    borderAsInsets.bottom + paddingAsInsets.bottom,
    borderAsInsets.right + paddingAsInsets.right
  };
}

static inline CGRect NSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
  rect.origin.x    += insets.left;
  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.left + insets.right);
  rect.size.height -= (insets.top  + insets.bottom);
  return rect;
}

- (NSSize)availableSize
{
  return  NSEdgeInsetsInsetRect((CGRect){CGPointZero, self.frame.size}, self.compoundInsets).size;
}

- (CGRect)contentFrame
{
  CGRect bounds = (CGRect){CGPointZero, self.frame.size};
  return NSEdgeInsetsInsetRect(bounds, self.compoundInsets);
}

#pragma mark - Measuring

- (CGSize)sizeThatFitsMinimumSize:(CGSize)minimumSize maximumSize:(CGSize)maximumSize
{
  YGNodeRef clonnedYogaNode = YGNodeClone(self.yogaNode);
  YGNodeRef constraintYogaNode = YGNodeNewWithConfig([[self class] yogaConfig]);

  YGNodeInsertChild(constraintYogaNode, clonnedYogaNode, 0);

  YGNodeStyleSetMinWidth(constraintYogaNode, RCTYogaFloatFromCoreGraphicsFloat(minimumSize.width));
  YGNodeStyleSetMinHeight(constraintYogaNode, RCTYogaFloatFromCoreGraphicsFloat(minimumSize.height));
  YGNodeStyleSetMaxWidth(constraintYogaNode, RCTYogaFloatFromCoreGraphicsFloat(maximumSize.width));
  YGNodeStyleSetMaxHeight(constraintYogaNode, RCTYogaFloatFromCoreGraphicsFloat(maximumSize.height));

  YGNodeCalculateLayout(
    constraintYogaNode,
    YGUndefined,
    YGUndefined,
    self.layoutDirection
  );

  CGSize measuredSize = (CGSize){
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetWidth(constraintYogaNode)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetHeight(constraintYogaNode)),
  };

  YGNodeRemoveChild(constraintYogaNode, clonnedYogaNode);
  YGNodeFree(constraintYogaNode);
  YGNodeFree(clonnedYogaNode);

  return measuredSize;
}

#pragma mark - Dirty Propagation Control

- (void)dirtyLayout
{
  // The default implementaion does nothing.
}

- (void)clearLayout
{
  // The default implementaion does nothing.
}

@end
