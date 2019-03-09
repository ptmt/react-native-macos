/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSBezierPath+CGPath.h"

@implementation NSBezierPath (CGPath)

// Taken from: https://stackoverflow.com/a/1956021/2228559
- (CGPathRef)CGPath
{
  CGPathRef path = NULL;

  NSInteger numElements = self.elementCount;
  if (numElements > 0) {
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    BOOL didClosePath = YES;

    for (NSInteger i = 0; i < numElements; i++) {
      NSPoint p[3];
      switch ([self elementAtIndex:i associatedPoints:p]) {
        case NSMoveToBezierPathElement:
          CGPathMoveToPoint(mutablePath, NULL, p[0].x, p[0].y);
          break;

        case NSLineToBezierPathElement:
          CGPathAddLineToPoint(mutablePath, NULL, p[0].x, p[0].y);
          didClosePath = NO;
          break;

        case NSCurveToBezierPathElement:
          CGPathAddCurveToPoint(mutablePath, NULL, p[0].x, p[0].y, p[1].x, p[1].y, p[2].x, p[2].y);
          didClosePath = NO;
          break;

        case NSClosePathBezierPathElement:
          CGPathCloseSubpath(mutablePath);
          didClosePath = YES;
          break;
      }
    }

    // Be sure the path is closed or Quartz may not do valid hit detection.
    if (!didClosePath) {
      CGPathCloseSubpath(mutablePath);
    }

    path = CGPathCreateCopy(path);
    CGPathRelease(mutablePath);
  }

  return path;
}

@end
