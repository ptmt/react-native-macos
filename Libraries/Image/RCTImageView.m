/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTImageView.h"

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTImageLoader.h"
#import "RCTImageUtils.h"
#import "RCTUtils.h"

#import "NSView+React.h"

/**
 * Determines whether an image of `currentSize` should be reloaded for display
 * at `idealSize`.
 */
static BOOL RCTShouldReloadImageForSizeChange(CGSize currentSize, CGSize idealSize)
{
  static const CGFloat upscaleThreshold = 1.2;
  static const CGFloat downscaleThreshold = 0.5;

  CGFloat widthMultiplier = idealSize.width / currentSize.width;
  CGFloat heightMultiplier = idealSize.height / currentSize.height;

  return widthMultiplier > upscaleThreshold || widthMultiplier < downscaleThreshold ||
    heightMultiplier > upscaleThreshold || heightMultiplier < downscaleThreshold;
}

@interface RCTImageView ()

@property (nonatomic, copy) RCTDirectEventBlock onLoadStart;
@property (nonatomic, copy) RCTDirectEventBlock onProgress;
@property (nonatomic, copy) RCTDirectEventBlock onError;
@property (nonatomic, copy) RCTDirectEventBlock onLoad;
@property (nonatomic, copy) RCTDirectEventBlock onLoadEnd;

@end

@implementation RCTImageView
{
  RCTBridge *_bridge;
  CGSize _targetSize;

  /**
   * A block that can be invoked to cancel the most recent call to -reloadImage,
   * if any.
   */
  RCTImageLoaderCancellationBlock _reloadImageCancellationBlock;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  if ((self = [super initWithFrame:NSZeroRect])) {
    _bridge = bridge;
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)init)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(NSRect)frameRect)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)coder)

- (void)updateImage
{
  NSImage *image = self.image;
  if (!image) {
    return;
  }

  // Apply rendering mode
//  if (_renderingMode != image.renderingMode) {
//    image = [image imageWithRenderingMode:_renderingMode];
//  }

  // Applying capInsets of 0 will switch the "resizingMode" of the image to "tile" which is undesired
  // TODO:
//  if (!NSEdgeInsetsEqualToEdgeInsets(NSEdgeInsetsZero, _capInsets)) {
//    image = [image resizableImageWithCapInsets:_capInsets];
//  }

  // Apply trilinear filtering to smooth out mis-sized images
  self.layer.minificationFilter = kCAFilterTrilinear;
  self.layer.magnificationFilter = kCAFilterTrilinear;

  super.image = image;
}

- (void)setImage:(NSImage *)image
{
  image = image ?: _defaultImage;
  if (image != super.image) {
    super.image = image;
    [self updateImage];
  }
}

// TODO: Replace it with proper mechanism
static inline BOOL UIEdgeInsetsEqualToEdgeInsets(NSEdgeInsets insets1, NSEdgeInsets insets2) {
  return CGRectEqualToRect(CGRectMake(insets1.left, insets1.top, insets1.right, insets1.bottom),
                           CGRectMake(insets2.left, insets2.top, insets2.right, insets2.bottom));
}

- (void)setCapInsets:(NSEdgeInsets)capInsets
{
  if (!UIEdgeInsetsEqualToEdgeInsets(_capInsets, capInsets)) {
    _capInsets = capInsets;
    [self updateImage];
  }
}

//- (void)setRenderingMode:(UIImageRenderingMode)renderingMode
//{
//  if (_renderingMode != renderingMode) {
//    _renderingMode = renderingMode;
//    [self updateImage];
//  }
//}

- (void)setSrc:(NSString *)src
{
  if (![src isEqual:_src]) {
    _src = [src copy];
    [self reloadImage];
  }
}

+ (BOOL)srcNeedsReload:(NSString *)src
{
  return
    [src hasPrefix:@"http://"] ||
    [src hasPrefix:@"https://"] ||
    [src hasPrefix:@"assets-library://"] ||
    [src hasPrefix:@"ph://"];
}

- (void)setContentMode:(UIViewContentMode)mode
{
  // TODO: move it to NSView?
    if (mode != _contentMode) {
      _contentMode = mode;
      switch(_contentMode) {
        case UIViewContentModeScaleToFill:
          _layer.contentsGravity = kCAGravityResize;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeScaleAspectFit:
          _layer.contentsGravity = kCAGravityResizeAspect;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeScaleAspectFill:
          _layer.contentsGravity = kCAGravityResizeAspectFill;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeRedraw:
          _layer.needsDisplayOnBoundsChange = YES;
          break;

        case UIViewContentModeCenter:
          _layer.contentsGravity = kCAGravityCenter;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeTop:
          _layer.contentsGravity = kCAGravityTop;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeBottom:
          _layer.contentsGravity = kCAGravityBottom;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeLeft:
          _layer.contentsGravity = kCAGravityLeft;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeRight:
          _layer.contentsGravity = kCAGravityRight;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeTopLeft:
          _layer.contentsGravity = kCAGravityTopLeft;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeTopRight:
          _layer.contentsGravity = kCAGravityTopRight;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeBottomLeft:
          _layer.contentsGravity = kCAGravityBottomLeft;
          _layer.needsDisplayOnBoundsChange = NO;
          break;

        case UIViewContentModeBottomRight:
          _layer.contentsGravity = kCAGravityBottomRight;
          _layer.needsDisplayOnBoundsChange = NO;
          break;
      }
      if ([RCTImageView srcNeedsReload:_src]) {
        [self reloadImage];
      }
    }
}

- (void)cancelImageLoad
{
  RCTImageLoaderCancellationBlock previousCancellationBlock = _reloadImageCancellationBlock;
  if (previousCancellationBlock) {
    previousCancellationBlock();
    _reloadImageCancellationBlock = nil;
  }
}

- (void)clearImage
{
  [self cancelImageLoad];
  [self.layer removeAnimationForKey:@"contents"];
  self.image = nil;
}

- (void)reloadImage
{
  [self cancelImageLoad];

  if (_src && self.frame.size.width > 0 && self.frame.size.height > 0) {
    if (_onLoadStart) {
      _onLoadStart(nil);
    }

    RCTImageLoaderProgressBlock progressHandler = nil;
    if (_onProgress) {
      progressHandler = ^(int64_t loaded, int64_t total) {
        _onProgress(@{
          @"loaded": @((double)loaded),
          @"total": @((double)total),
        });
      };
    }

    _reloadImageCancellationBlock = [_bridge.imageLoader loadImageWithTag:_src
                                                                     size:self.bounds.size
                                                                    scale:RCTScreenScale()
                                                               resizeMode:self.contentMode
                                                            progressBlock:progressHandler
                                                          completionBlock:^(NSError *error, NSImage *image) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (image.reactKeyframeAnimation) {
          [self.layer addAnimation:image.reactKeyframeAnimation forKey:@"contents"];
        } else {
          [self.layer removeAnimationForKey:@"contents"];
          self.image = image;
        }
        if (error) {
          if (_onError) {
            _onError(@{ @"error": error.localizedDescription });
          }
        } else {
          if (_onLoad) {
            _onLoad(nil);
          }
        }
        if (_onLoadEnd) {
           _onLoadEnd(nil);
        }
      });
    }];
  } else {
    [self clearImage];
  }
}

- (void)reactSetFrame:(CGRect)frame
{
  [super reactSetFrame:frame];

  if (!self.image || self.image == _defaultImage) {
    _targetSize = frame.size;
    [self reloadImage];
  } else if ([RCTImageView srcNeedsReload:_src]) {
    CGSize imageSize = self.image.size;
    // TODO: replace 1.0 with real scale
    CGSize idealSize = RCTTargetSize(imageSize, 1.0, frame.size, RCTScreenScale(), self.contentMode, YES);

    if (RCTShouldReloadImageForSizeChange(imageSize, idealSize)) {
      if (RCTShouldReloadImageForSizeChange(_targetSize, idealSize)) {
        RCTLogInfo(@"[PERF IMAGEVIEW] Reloading image %@ as size %f %f", _src, idealSize.height, idealSize.width);

        // If the existing image or an image being loaded are not the right size, reload the asset in case there is a
        // better size available.
        _targetSize = idealSize;
        [self reloadImage];
      }
    } else {
      // Our existing image is good enough.
      [self cancelImageLoad];
      _targetSize = imageSize;
    }
  }
}

//- (void)didMoveToWindow
//{
//  [super did];
//
//  if (!self.window) {
//    // Don't keep self alive through the asynchronous dispatch, if the intention was to remove the view so it would
//    // deallocate.
//    __weak typeof(self) weakSelf = self;
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//      __strong typeof(self) strongSelf = weakSelf;
//      if (!strongSelf) {
//        return;
//      }
//
//      // If we haven't been re-added to a window by this run loop iteration, clear out the image to save memory.
//      if (!strongSelf.window) {
//        [strongSelf clearImage];
//      }
//    });
//  } else if (!self.image || self.image == _defaultImage) {
//    [self reloadImage];
//  }
//}

@end
