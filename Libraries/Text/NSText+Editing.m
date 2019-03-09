/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSText+Editing.h"

@implementation NSText (Editing)

- (BOOL)endEditing:(BOOL)force
{
  if (self != self.window.firstResponder) {
    return YES;
  }
  if (force || [self.delegate textShouldEndEditing:self]) {
    [self.window makeFirstResponder:nil];
    return YES;
  }
  return NO;
}

@end
