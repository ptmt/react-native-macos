/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSFont+LineHeight.h"

@implementation NSFont (LineHeight)

// Taken from: https://github.com/bvanderveen/Thor/blob/0ea3cbd031df6c00fffc54a9b35de7ef787ea36f/Thor/Classes/NSFont%2BLineHeight.m#L5-L7
- (CGFloat)lineHeight
{
  return ceilf(self.ascender + ABS(self.descender) + self.leading);
}

@end
