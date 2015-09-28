/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

typedef NS_ENUM(NSUInteger, RCTFPSGraphPosition) {
  RCTFPSGraphPositionLeft = 1,
  RCTFPSGraphPositionRight = 2
};

@interface RCTFPSGraph : NSView

- (instancetype)initWithFrame:(CGRect)frame graphPosition:(RCTFPSGraphPosition)position name:(NSString *)name color:(NSColor *)color NS_DESIGNATED_INITIALIZER;

- (void)onTick:(NSTimeInterval)timestamp;

@end
