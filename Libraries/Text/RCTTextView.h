/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import "RCTView.h"
#import "NSView+React.h"

@class RCTEventDispatcher;

@interface TextViewWithPlaceHolder : NSTextView

@property (nonatomic, strong) NSAttributedString *placeholderAttributedString;

@end

@interface RCTTextView : RCTView <NSTextViewDelegate, NSTextDelegate>

@property (nonatomic, assign) BOOL autoCorrect;
@property (nonatomic, assign) BOOL clearTextOnFocus;
@property (nonatomic, assign) BOOL selectTextOnFocus;
@property (nonatomic, assign) NSEdgeInsets contentInset;
@property (nonatomic, assign) BOOL automaticallyAdjustContentInsets;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSColor *placeholderTextColor;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, assign) NSInteger mostRecentEventCount;
@property (nonatomic, strong) NSNumber *maxLength;

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

@end
