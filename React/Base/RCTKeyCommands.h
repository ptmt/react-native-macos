/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

@interface RCTKeyCommands : NSObject

+ (instancetype)sharedInstance;

/**
 * Register a keyboard command. UIKeyModifierFlags
 */
//- (void)registerKeyCommandWithInput:(NSString *)input
//             //         modifierFlags:(NSKeyM)flags
//                             action:(void (^)(NS *command))block;
//
///**
// * Unregister a keyboard command.
// */
//- (void)unregisterKeyCommandWithInput:(NSString *)input
//                        modifierFlags:(UIKeyModifierFlags)flags;
//
///**
// * Check if a command is registered.
// */
//- (BOOL)isKeyCommandRegisteredForInput:(NSString *)input
//                         modifierFlags:(UIKeyModifierFlags)flags;

@end
