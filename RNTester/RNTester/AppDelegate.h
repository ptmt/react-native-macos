/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <AppKit/AppKit.h>

@class RCTBridge;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSToolbarDelegate, NSWindowDelegate>

@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSArray<NSString *> *argv;
@property (assign, nonatomic) Class<NSWindowRestoration> restorationClass;
@property (nonatomic, readonly) RCTBridge *bridge;
@property (strong, nonatomic) NSURL *sourceURL;

@end
