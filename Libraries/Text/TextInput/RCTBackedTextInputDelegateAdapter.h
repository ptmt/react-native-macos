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

#pragma mark - RCTBackedTextFieldDelegateAdapter (for UITextField)

@interface RCTBackedTextFieldDelegateAdapter : NSObject

- (instancetype)initWithTextField:(NSTextField<RCTBackedTextInputViewProtocol> *)backedTextInput;

- (void)skipNextTextInputDidChangeSelectionEventWithTextRange:(NSRange *)textRange;
- (void)selectedTextRangeWasSet;

@end

#pragma mark - RCTBackedTextViewDelegateAdapter (for UITextView)

@interface RCTBackedTextViewDelegateAdapter : NSObject

- (instancetype)initWithTextView:(NSTextView<RCTBackedTextInputViewProtocol> *)backedTextInput;

- (void)skipNextTextInputDidChangeSelectionEventWithTextRange:(NSRange *)textRange;

@end
