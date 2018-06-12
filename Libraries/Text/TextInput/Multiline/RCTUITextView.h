/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import "RCTBackedTextInputViewProtocol.h"

#import "RCTBackedTextInputDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * Just regular UITextView... but much better!
 */

@interface RCTUITextView : NSTextView <RCTBackedTextInputViewProtocol>

- (instancetype)initWithFrame:(CGRect)frame textContainer:(nullable NSTextContainer *)textContainer NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@property (nonatomic, weak) id<RCTBackedTextInputDelegate> textInputDelegate;
// - (void)setText:(NSString *)text;
- (void)setAttributedText:(NSAttributedString *)attributedText;

@property (nonatomic, strong) NSAttributedString *placeholderAttributedString;
@property (nonatomic, assign) BOOL textWasPasted;
@property (nonatomic, copy, nullable) NSString *placeholderText;
@property (nonatomic, assign, nullable) NSColor *placeholderTextColor;
@property (nonatomic, assign) CGFloat preferredMaxLayoutWidth;

@end

NS_ASSUME_NONNULL_END
