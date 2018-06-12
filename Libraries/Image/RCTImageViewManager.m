/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTImageViewManager.h"

#import <AppKit/AppKit.h>

#import <React/RCTConvert.h>

#import "RCTImageLoader.h"
#import "RCTImageShadowView.h"
#import "RCTImageView.h"

@implementation RCTImageViewManager

RCT_EXPORT_MODULE()

- (RCTShadowView *)shadowView
{
  return [RCTImageShadowView new];
}

- (NSView *)view
{
  return [[RCTImageView alloc] initWithBridge:self.bridge];
}

RCT_EXPORT_VIEW_PROPERTY(capInsets, MSEdgeInsets)
RCT_REMAP_VIEW_PROPERTY(defaultSource, defaultImage, NSImage)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, RCTResizeMode)
RCT_EXPORT_VIEW_PROPERTY(blurRadius, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(onLoadStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onProgress, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPartialLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoadEnd, RCTDirectEventBlock)
RCT_REMAP_VIEW_PROPERTY(source, imageSources, NSArray<RCTImageSource *>);
RCT_CUSTOM_VIEW_PROPERTY(tintColor, NSColor, RCTImageView)
{
  // Default tintColor isn't nil - it's inherited from the superView - but we
  // want to treat a null json value for `tintColor` as meaning 'disable tint',
  // so we toggle `renderingMode` here instead of in `-[RCTImageView setTintColor:]`
  // TODO: tintColor
  //view.tintColor = [RCTConvert NSColor:json] ?: defaultView.tintColor;
  //view.renderingMode = json ? UIImageRenderingModeAlwaysTemplate : defaultView.renderingMode;
}

RCT_EXPORT_METHOD(getSize:(NSURLRequest *)request
                  successBlock:(RCTResponseSenderBlock)successBlock
                  errorBlock:(RCTResponseErrorBlock)errorBlock)
{
  [self.bridge.imageLoader getImageSizeForURLRequest:request
                                               block:^(NSError *error, CGSize size) {
                                                 if (error) {
                                                   errorBlock(error);
                                                 } else {
                                                   successBlock(@[@(size.width), @(size.height)]);
                                                 }
                                               }];
}

RCT_EXPORT_METHOD(prefetchImage:(NSURLRequest *)request
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (!request) {
    reject(@"E_INVALID_URI", @"Cannot prefetch an image for an empty URI", nil);
    return;
  }

  [self.bridge.imageLoader loadImageWithURLRequest:request
                                          callback:^(NSError *error, NSImage *image) {
                                            if (error) {
                                              reject(@"E_PREFETCH_FAILURE", nil, error);
                                              return;
                                            }
                                            resolve(@YES);
                                          }];
}

@end
