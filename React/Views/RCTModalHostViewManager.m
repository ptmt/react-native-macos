/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTModalHostViewManager.h"

#import "RCTBridge.h"
#import "RCTModalHostView.h"
#import "RCTTouchHandler.h"
#import "RCTShadowView.h"
#import "RCTUtils.h"

@interface RCTModalHostShadowView : RCTShadowView

@end

@implementation RCTModalHostShadowView

- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(NSInteger)atIndex
{
  [super insertReactSubview:subview atIndex:atIndex];
  if ([subview isKindOfClass:[RCTShadowView class]]) {
    ((RCTShadowView *)subview).size = RCTScreenSize();
  }
}

@end

@implementation RCTModalHostViewManager
{
  NSHashTable *_hostViews;
}

RCT_EXPORT_MODULE()

- (NSView *)view
{
  NSView *view = [[RCTModalHostView alloc] initWithBridge:self.bridge];
  if (_hostViews) {
    _hostViews = [NSHashTable weakObjectsHashTable];
  }
  [_hostViews addObject:view];
  return view;
}

- (RCTShadowView *)shadowView
{
  return [RCTModalHostShadowView new];
}

- (void)invalidate
{
  for (RCTModalHostView *hostView in _hostViews) {
    [hostView invalidate];
  }
  [_hostViews removeAllObjects];
}

RCT_EXPORT_VIEW_PROPERTY(animationType, NSString)
RCT_EXPORT_VIEW_PROPERTY(presentationType, NSString)
RCT_EXPORT_VIEW_PROPERTY(width, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(height, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(transparent, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onShow, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRequestClose, RCTDirectEventBlock)

@end
