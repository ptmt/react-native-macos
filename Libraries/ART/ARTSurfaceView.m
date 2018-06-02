/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ARTSurfaceView.h"

#import <React/RCTLog.h>

#import "ARTNode.h"

@implementation ARTSurfaceView

- (BOOL)isFlipped
{
  return YES;
}

- (void)insertReactSubview:(NSView *)subview atIndex:(NSInteger)atIndex
{
    [super insertReactSubview:subview atIndex:atIndex];
    [self addSubview:subview];
    [self invalidate];
}

- (void)removeReactSubview:(NSView *)subview
{
    [super removeReactSubview:subview];
    [self invalidate];
}


- (void)didUpdateReactSubviews
{
  // Do nothing, as subviews are inserted by insertReactSubview:
}

- (void)invalidate
{
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef context = [NSGraphicsContext currentContext].CGContext;
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
