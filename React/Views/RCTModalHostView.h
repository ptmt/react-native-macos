/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import <React/RCTInvalidating.h>
#import <React/RCTModalHostViewManager.h>
#import <React/RCTView.h>

@class RCTBridge;
@class RCTModalHostViewController;

@protocol RCTModalHostViewInteractor;

@interface RCTModalHostView : NSView <RCTInvalidating, NSWindowDelegate>

@property (nonatomic, copy) NSString *animationType;
@property (nonatomic, copy) NSString *presentationType;
@property (nonatomic, copy) NSView *containerView;
@property (nonatomic, copy) NSNumber *width;
@property (nonatomic, copy) NSNumber *height;
@property (nonatomic, assign, getter=isTransparent) BOOL transparent;

@property (nonatomic, copy) RCTDirectEventBlock onShow;
@property (nonatomic, copy) RCTDirectEventBlock onRequestClose;

@property (nonatomic, weak) id<RCTModalHostViewInteractor> delegate;

@property (nonatomic, copy) NSArray<NSString *> *supportedOrientations;
@property (nonatomic, copy) RCTDirectEventBlock onOrientationChange;

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

@end

@protocol RCTModalHostViewInteractor <NSObject>

- (void)presentModalHostView:(RCTModalHostView *)modalHostView withViewController:(RCTModalHostViewController *)viewController animated:(BOOL)animated;
- (void)dismissModalHostView:(RCTModalHostView *)modalHostView withViewController:(RCTModalHostViewController *)viewController animated:(BOOL)animated;

@end
