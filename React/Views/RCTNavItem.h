/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import <React/RCTComponent.h>

@interface RCTNavItem : NSView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSImage *titleImage;
@property (nonatomic, strong) NSImage *leftButtonIcon;
@property (nonatomic, copy) NSString *leftButtonTitle;
@property (nonatomic, assign) UIBarButtonSystemItem leftButtonSystemIcon;
@property (nonatomic, strong) UIImage *rightButtonIcon;
@property (nonatomic, copy) NSString *rightButtonTitle;
@property (nonatomic, assign) UIBarButtonSystemItem rightButtonSystemIcon;
@property (nonatomic, strong) UIImage *backButtonIcon;
@property (nonatomic, copy) NSString *backButtonTitle;
@property (nonatomic, assign) BOOL navigationBarHidden;
@property (nonatomic, assign) BOOL shadowHidden;
@property (nonatomic, strong) NSColor *tintColor;
@property (nonatomic, strong) NSColor *barTintColor;
@property (nonatomic, strong) NSColor *titleTextColor;
@property (nonatomic, assign) BOOL translucent;
#if !TARGET_OS_TV
@property (nonatomic, assign) UIBarStyle barStyle;
#endif

// @property (nonatomic, readonly) UIImageView *titleImageView;
// @property (nonatomic, readonly) UIBarButtonItem *backButtonItem;
// @property (nonatomic, readonly) UIBarButtonItem *leftButtonItem;
// @property (nonatomic, readonly) UIBarButtonItem *rightButtonItem;

@property (nonatomic, copy) RCTBubblingEventBlock onLeftButtonPress;
@property (nonatomic, copy) RCTBubblingEventBlock onRightButtonPress;

@end
