/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextFieldManager.h"

#import "RCTBridge.h"
#import "RCTShadowView.h"
#import "RCTSparseArray.h"
#import "RCTTextField.h"
#import "RCTSecureTextField.h"

@interface RCTTextFieldManager() <NSTextFieldDelegate>

@end

@implementation RCTTextFieldManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  RCTTextField *textField = [[RCTTextField alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
  textField.delegate = self;
  return textField;
}

- (BOOL)textField:(RCTTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
  if (textField.maxLength == nil || [string isEqualToString:@"\n"]) {  // Make sure forms can be submitted via return
    return YES;
  }
  return YES;
}

RCT_EXPORT_VIEW_PROPERTY(caretHidden, BOOL)
RCT_EXPORT_VIEW_PROPERTY(autoCorrect, BOOL)
RCT_REMAP_VIEW_PROPERTY(editable, enabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(placeholder, NSString)
RCT_EXPORT_VIEW_PROPERTY(placeholderTextColor, NSColor)
RCT_EXPORT_VIEW_PROPERTY(text, NSString)
RCT_EXPORT_VIEW_PROPERTY(maxLength, NSNumber)
//RCT_EXPORT_VIEW_PROPERTY(clearButtonMode, NSTextFieldViewMode)
//RCT_REMAP_VIEW_PROPERTY(clearTextOnFocus, clearsOnBeginEditing, BOOL)
RCT_EXPORT_VIEW_PROPERTY(selectTextOnFocus, BOOL)
RCT_REMAP_VIEW_PROPERTY(color, textColor, NSColor)
//RCT_REMAP_VIEW_PROPERTY(autoCapitalize, autocapitalizationType, UITextAutocapitalizationType)
RCT_REMAP_VIEW_PROPERTY(textAlign, textAlignment, NSTextAlignment)
RCT_CUSTOM_VIEW_PROPERTY(fontSize, CGFloat, RCTTextField)
{
  view.font = [RCTConvert NSFont:view.font withSize:json ?: @(defaultView.font.pointSize)];
}
RCT_CUSTOM_VIEW_PROPERTY(fontWeight, NSString, __unused RCTTextField)
{
  view.font = [RCTConvert NSFont:view.font withWeight:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontStyle, NSString, __unused RCTTextField)
{
  view.font = [RCTConvert NSFont:view.font withStyle:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontFamily, NSString, RCTTextField)
{
  view.font = [RCTConvert NSFont:view.font withFamily:json ?: defaultView.font.familyName];
}
RCT_EXPORT_VIEW_PROPERTY(mostRecentEventCount, NSInteger)

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(RCTShadowView *)shadowView
{
  NSNumber *reactTag = shadowView.reactTag;
  NSEdgeInsets padding = shadowView.paddingAsInsets;
  return ^(__unused RCTUIManager *uiManager, RCTSparseArray *viewRegistry) {
    ((RCTTextField *)viewRegistry[reactTag]).contentInset = padding;
  };
}

@end

@interface RCTSecureTextFieldManager() <NSTextFieldDelegate>

@end


@implementation RCTSecureTextFieldManager

RCT_EXPORT_MODULE()


- (NSView *)view
{
  RCTSecureTextField *textField = [[RCTSecureTextField alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
  textField.delegate = self;
  return textField;
}

@end