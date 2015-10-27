/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>
#import "RCTImageComponent.h"
#import "RCTImageLoader.h" // - for UIViewContentMode. TODO: move it to UIImageUtils

@class RCTBridge;

@interface RCTImageView : NSImageView <RCTImageComponent>

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign) NSEdgeInsets capInsets;
@property (nonatomic, strong) NSImage *defaultImage;
//@property (nonatomic, assign) NSImageRenderingMode renderingMode;
@property (nonatomic, assign) UIViewContentMode contentMode;
@property (nonatomic, copy) NSString *src;

@end
