/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <yoga/Yoga.h>

#import "RCTAssert.h"
#import "RCTShadowView+Layout.h"

static inline CGRect NSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
  rect.origin.x    += insets.left;
  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.left + insets.right);
  rect.size.height -= (insets.top  + insets.bottom);
  return rect;
}

RCTLayoutMetrics RCTLayoutMetricsFromYogaNode(YGNodeRef yogaNode)
{
  RCTLayoutMetrics layoutMetrics;

  CGRect frame = (CGRect){
    (CGPoint){
      RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetLeft(yogaNode)),
      RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetTop(yogaNode))
    },
    (CGSize){
      RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetWidth(yogaNode)),
      RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetHeight(yogaNode))
    }
  };

  NSEdgeInsets padding = (NSEdgeInsets){
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetPadding(yogaNode, YGEdgeTop)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetPadding(yogaNode, YGEdgeLeft)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetPadding(yogaNode, YGEdgeBottom)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetPadding(yogaNode, YGEdgeRight))
  };

  NSEdgeInsets borderWidth = (NSEdgeInsets){
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetBorder(yogaNode, YGEdgeTop)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetBorder(yogaNode, YGEdgeLeft)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetBorder(yogaNode, YGEdgeBottom)),
    RCTCoreGraphicsFloatFromYogaFloat(YGNodeLayoutGetBorder(yogaNode, YGEdgeRight))
  };

  NSEdgeInsets compoundInsets = (NSEdgeInsets){
    borderWidth.top + padding.top,
    borderWidth.left + padding.left,
    borderWidth.bottom + padding.bottom,
    borderWidth.right + padding.right
  };

  CGRect bounds = (CGRect){CGPointZero, frame.size};
  CGRect contentFrame = NSEdgeInsetsInsetRect(bounds, compoundInsets);

  layoutMetrics.frame = frame;
  layoutMetrics.borderWidth = borderWidth;
  layoutMetrics.contentFrame = contentFrame;
  layoutMetrics.displayType = RCTReactDisplayTypeFromYogaDisplayType(YGNodeStyleGetDisplay(yogaNode));
  layoutMetrics.layoutDirection = RCTUIKitLayoutDirectionFromYogaLayoutDirection(YGNodeLayoutGetDirection(yogaNode));

  return layoutMetrics;
}


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

CGFloat RCTCoreGraphicsFloatFromYogaValue(YGValue value, CGFloat baseFloatValue)
{
  switch (value.unit) {
    case YGUnitPoint:
      return RCTCoreGraphicsFloatFromYogaFloat(value.value);
    case YGUnitPercent:
      return RCTCoreGraphicsFloatFromYogaFloat(value.value) * baseFloatValue;
    case YGUnitAuto:
    case YGUnitUndefined:
      return baseFloatValue;
  }
}

YGDirection RCTYogaLayoutDirectionFromUIKitLayoutDirection(NSUserInterfaceLayoutDirection direction)
{
  switch (direction) {
    case NSUserInterfaceLayoutDirectionRightToLeft:
      return YGDirectionRTL;
    case NSUserInterfaceLayoutDirectionLeftToRight:
      return YGDirectionLTR;
  }
}

NSUserInterfaceLayoutDirection RCTUIKitLayoutDirectionFromYogaLayoutDirection(YGDirection direction)
{
  switch (direction) {
    case YGDirectionInherit:
    case YGDirectionLTR:
      return NSUserInterfaceLayoutDirectionLeftToRight;
    case YGDirectionRTL:
      return NSUserInterfaceLayoutDirectionRightToLeft;
  }
}

YGDisplay RCTYogaDisplayTypeFromReactDisplayType(RCTDisplayType displayType)
{
  switch (displayType) {
    case RCTDisplayTypeNone:
      return YGDisplayNone;
    case RCTDisplayTypeFlex:
      return YGDisplayFlex;
    case RCTDisplayTypeInline:
      RCTAssert(NO, @"RCTDisplayTypeInline cannot be converted to YGDisplay value.");
      return YGDisplayNone;
  }
}

RCTDisplayType RCTReactDisplayTypeFromYogaDisplayType(YGDisplay displayType)
{
  switch (displayType) {
    case YGDisplayFlex:
      return RCTDisplayTypeFlex;
    case YGDisplayNone:
      return RCTDisplayTypeNone;
  }
}
