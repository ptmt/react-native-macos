/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTXCAssetImageLoader.h"

#import <libkern/OSAtomic.h>

#import "RCTUtils.h"

@implementation RCTXCAssetImageLoader

RCT_EXPORT_MODULE()

- (BOOL)canLoadImageURL:(NSURL *)requestURL
{
  return RCTIsXCAssetURL(requestURL);
}

 - (RCTImageLoaderCancellationBlock)loadImageForURL:(NSURL *)imageURL
                                               size:(CGSize)size
                                              scale:(CGFloat)scale
                                         resizeMode:(RCTResizeMode)resizeMode
                                    progressHandler:(RCTImageLoaderProgressBlock)progressHandler
                                  completionHandler:(RCTImageLoaderCompletionBlock)completionHandler
{
  __block volatile uint32_t cancelled = 0;
  dispatch_async(dispatch_get_main_queue(), ^{

    if (cancelled) {
      return;
    }
    NSString *imageName = RCTBundlePathForURL(imageURL);
    NSImage *image = [self loadImageForName:imageName];
    if (image) {
      if (progressHandler) {
        progressHandler(1, 1);
      }
      completionHandler(nil, image);
    } else {
      NSString *message = [NSString stringWithFormat:@"Could not find image named %@", imageName];
      completionHandler(RCTErrorWithMessage(message), nil);
    }
  });

  return ^{
    OSAtomicOr32Barrier(1, &cancelled);
  };
}

- (NSImage *)loadImageForName:(NSString *)imageName
{
  NSImage *image = nil;
  NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
  if (currentBundle != [NSBundle mainBundle]) {
    image = [currentBundle imageForResource:imageName];
  }
  
  return image == nil ? [NSImage imageNamed:imageName] : image;
}

@end
