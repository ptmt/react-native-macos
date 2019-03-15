/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import "RCTBridge.h"
#import "RCTRootView.h"

@interface RCTWindow : NSWindow

- (instancetype)initWithBridge:(RCTBridge *)bridge
                   contentRect:(NSRect)contentRect
                     styleMask:(NSWindowStyleMask)style
                         defer:(BOOL)defer NS_DESIGNATED_INITIALIZER;

@property (nullable, strong) RCTRootView *contentView;

@end
