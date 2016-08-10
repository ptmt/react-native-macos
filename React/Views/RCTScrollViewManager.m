/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTScrollViewManager.h"

#import "RCTBridge.h"
#import "RCTScrollView.h"
#import "RCTUIManager.h"

@interface RCTNativeScrollView (Private)

- (NSArray *)calculateChildFramesData;

@end

@implementation RCTNativeScrollViewManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  return [[RCTNativeScrollView alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}

RCT_EXPORT_VIEW_PROPERTY(autoScrollToBottom, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showsHorizontalScrollIndicator, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showsVerticalScrollIndicator, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onScroll, RCTDirectEventBlock)

RCT_EXPORT_METHOD(getContentSize:(nonnull NSNumber *)reactTag
                  callback:(RCTResponseSenderBlock)callback)
{
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTNativeScrollView *> *viewRegistry) {

     RCTNativeScrollView *view = viewRegistry[reactTag];
     if (!view) {
       RCTLogError(@"Cannot find RCTNativeScrollView with tag #%@", reactTag);
       return;
     }

     CGSize size = view.contentSize;
     callback(@[@{
                  @"width" : @(size.width),
                  @"height" : @(size.height)
                  }]);
   }];
}

RCT_EXPORT_METHOD(calculateChildFrames:(nonnull NSNumber *)reactTag
                  callback:(RCTResponseSenderBlock)callback)
{
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTNativeScrollView *> *viewRegistry) {

     RCTNativeScrollView *view = viewRegistry[reactTag];
     if (!view || ![view isKindOfClass:[RCTNativeScrollView class]]) {
       RCTLogError(@"Cannot find RCTNativeScrollView with tag #%@", reactTag);
       return;
     }

     NSArray<NSDictionary *> *childFrames = [view calculateChildFramesData];
     if (childFrames) {
       callback(@[childFrames]);
     }
   }];
}

RCT_EXPORT_METHOD(scrollTo:(nonnull NSNumber *)reactTag
                  offsetX:(CGFloat)x
                  offsetY:(CGFloat)y
                  animated:(BOOL)animated)
{
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTNativeScrollView *> *viewRegistry){
     RCTNativeScrollView *view = viewRegistry[reactTag];

     if ([view conformsToProtocol:@protocol(RCTScrollableProtocol)]) {
       [(id<RCTScrollableProtocol>)view scrollToOffset:(CGPoint){x, y} animated:animated];
     } else {
       RCTLogError(@"tried to scrollTo: on non-RCTScrollableProtocol view %@ "
                   "with tag #%@", view, reactTag);
     }
   }];
}

@end
