/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ARTSurfaceView.h"

#import "ARTNode.h"
#import "RCTLog.h"
#import "UIImageUtils.h"

@implementation ARTSurfaceView

- (BOOL)isFlipped
{
  return YES;
}

- (void)invalidate
{
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  for (ARTNode *node in self.subviews) {
    [node renderTo:context];
  }
}

- (void)reactSetInheritedBackgroundColor:(NSColor *)inheritedBackgroundColor
{
  [self setWantsLayer:YES];
  self.layer.backgroundColor = [inheritedBackgroundColor CGColor];
}

@end
