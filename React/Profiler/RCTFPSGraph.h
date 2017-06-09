/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import <React/RCTDefines.h>

#if RCT_DEV

@interface RCTFPSGraph : NSView

@property (nonatomic, assign, readonly) NSUInteger FPS;
@property (nonatomic, assign, readonly) NSUInteger maxFPS;
@property (nonatomic, assign, readonly) NSUInteger minFPS;

- (instancetype)initWithFrame:(CGRect)frame
                        color:(NSColor *)color NS_DESIGNATED_INITIALIZER;

- (void)onTick:(NSTimeInterval)timestamp;

@end

#endif
