/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextFieldManager.h"

#import <React/RCTBridge.h>
#import <React/RCTFont.h>
#import <React/RCTShadowView.h>

#import "RCTShadowTextField.h"
#import "RCTTextField.h"
#import "RCTSecureTextField.h"

@implementation RCTConvert(RCTTextField)

RCT_ENUM_CONVERTER(NSFocusRingType, (@{
    @"default": @(NSFocusRingTypeDefault),
    @"none": @(NSFocusRingTypeNone),
    @"exterior": @(NSFocusRingTypeExterior)
}), NSFocusRingTypeDefault, integerValue)

@end

@interface RCTTextFieldManager() <NSTextFieldDelegate>

@end

@implementation RCTTextFieldManager

RCT_EXPORT_MODULE()

- (RCTShadowView *)shadowView
{
  return [RCTShadowTextField new];
}

- (NSView *)view
{
    RCTTextField *textField = [[RCTTextField alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
    textField.delegate = self;
    return textField;
}

RCT_EXPORT_VIEW_PROPERTY(caretHidden, BOOL)
RCT_REMAP_VIEW_PROPERTY(editable, enabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(placeholder, NSString)
RCT_EXPORT_VIEW_PROPERTY(placeholderTextColor, NSColor)
RCT_EXPORT_VIEW_PROPERTY(selection, RCTTextSelection)
RCT_EXPORT_VIEW_PROPERTY(text, NSString)
RCT_EXPORT_VIEW_PROPERTY(maxLength, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(focusRingType, NSFocusRingType)
RCT_EXPORT_VIEW_PROPERTY(selectionColor, NSColor)
RCT_REMAP_VIEW_PROPERTY(textAlign, alignment, NSTextAlignment)
RCT_REMAP_VIEW_PROPERTY(color, textColor, NSColor)
RCT_CUSTOM_VIEW_PROPERTY(fontSize, NSNumber, RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withSize:json ?: @(defaultView.font.pointSize)];
}
RCT_CUSTOM_VIEW_PROPERTY(fontWeight, NSString, __unused RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withWeight:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontStyle, NSString, __unused RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withStyle:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontFamily, NSString, RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withFamily:json ?: defaultView.font.familyName];
}
RCT_EXPORT_VIEW_PROPERTY(mostRecentEventCount, NSInteger)

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(RCTShadowView *)shadowView
{
  NSNumber *reactTag = shadowView.reactTag;
  NSEdgeInsets padding = shadowView.paddingAsInsets;
  return ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTTextField *> *viewRegistry) {
    ((RCTTextField *)viewRegistry[reactTag]).contentInset = padding;
  };
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  RCTTextField *view = [[RCTTextField alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
  return @{
     @"ComponentHeight": @(view.intrinsicContentSize.height),
     @"ComponentWidth": @(view.intrinsicContentSize.width)
  };
}

@end

@interface RCTSecureTextFieldManager() <NSTextFieldDelegate>
@end

// TODO: extract common logic into one place
@implementation RCTSecureTextFieldManager

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  RCTTextField *view = [[RCTTextField alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
  return @{
           @"ComponentHeight": @(view.intrinsicContentSize.height),
           @"ComponentWidth": @(view.intrinsicContentSize.width)
           };
}

- (NSView *)view
{
  RCTSecureTextField *textField = [[RCTSecureTextField alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
  textField.delegate = self;
  return textField;
}

RCT_EXPORT_VIEW_PROPERTY(bezeled, BOOL)
RCT_REMAP_VIEW_PROPERTY(editable, enabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(text, NSString)
RCT_EXPORT_VIEW_PROPERTY(maxLength, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(selectionColor, NSColor)
RCT_REMAP_VIEW_PROPERTY(color, textColor, NSColor)
RCT_REMAP_VIEW_PROPERTY(textAlign, textAlignment, NSTextAlignment)
RCT_CUSTOM_VIEW_PROPERTY(fontSize, NSNumber, RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withSize:json ?: @(defaultView.font.pointSize)];
}
RCT_CUSTOM_VIEW_PROPERTY(fontWeight, NSString, __unused RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withWeight:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontStyle, NSString, __unused RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withStyle:json]; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontFamily, NSString, RCTTextField)
{
  view.font = [RCTFont updateFont:view.font withFamily:json ?: defaultView.font.familyName];
}
RCT_EXPORT_VIEW_PROPERTY(mostRecentEventCount, NSInteger)

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(RCTShadowView *)shadowView
{
  NSNumber *reactTag = shadowView.reactTag;
  NSEdgeInsets padding = shadowView.paddingAsInsets;
  return ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTTextField *> *viewRegistry) {
    viewRegistry[reactTag].contentInset = padding;
  };
}

@end
