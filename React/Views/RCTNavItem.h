/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import "RCTComponent.h"

@interface RCTNavItem : NSView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSImage *leftButtonIcon;
@property (nonatomic, copy) NSString *leftButtonTitle;
@property (nonatomic, strong) NSImage *rightButtonIcon;
@property (nonatomic, copy) NSString *rightButtonTitle;
@property (nonatomic, strong) NSImage *backButtonIcon;
@property (nonatomic, copy) NSString *backButtonTitle;
@property (nonatomic, assign) BOOL navigationBarHidden;
@property (nonatomic, assign) BOOL shadowHidden;
@property (nonatomic, strong) NSColor *tintColor;
@property (nonatomic, strong) NSColor *barTintColor;
@property (nonatomic, strong) NSColor *titleTextColor;
@property (nonatomic, assign) BOOL translucent;

@property (nonatomic, readonly) NSBarButtonItem *backButtonItem;
@property (nonatomic, readonly) UIBarButtonItem *leftButtonItem;
@property (nonatomic, readonly) UIBarButtonItem *rightButtonItem;

@property (nonatomic, copy) RCTBubblingEventBlock onNavLeftButtonTap;
@property (nonatomic, copy) RCTBubblingEventBlock onNavRightButtonTap;

@end
