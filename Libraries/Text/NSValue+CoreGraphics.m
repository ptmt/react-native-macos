/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSValue+CoreGraphics.h"

@implementation NSValue (CoreGraphics)

// Taken from: https://github.com/dbainbridge/mapbox-osx/blob/3461e73eddd397c415c873d317d346d1d351787a/Map/src/NSValue%2BiOS.m#L32-L35
+ (NSValue *)valueWithCGSize:(CGSize)size
{
  return [NSValue valueWithSize:NSSizeFromCGSize(size)];
}

@end
