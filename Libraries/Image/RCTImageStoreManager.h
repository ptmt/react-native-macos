// Copyright 2004-present Facebook. All Rights Reserved.

#import <AppKit/AppKit.h>

#import <React/RCTBridge.h>
#import <React/RCTURLRequestHandler.h>

@interface RCTImageStoreManager : NSObject <RCTURLRequestHandler>

/**
 * Set and get cached image data asynchronously. It is safe to call these from any
 * thread. The callbacks will be called on an unspecified thread.
 */
- (void)removeImageForTag:(NSString *)imageTag withBlock:(void (^)(void))block;
- (void)storeImageData:(NSData *)imageData withBlock:(void (^)(NSString *imageTag))block;
- (void)getImageDataForTag:(NSString *)imageTag withBlock:(void (^)(NSData *imageData))block;

/**
 * Convenience method to store an image directly (image is converted to data
 * internally, so any metadata such as scale or orientation will be lost).
 */
- (void)storeImage:(NSImage *)image withBlock:(void (^)(NSString *imageTag))block;

@end

@interface RCTImageStoreManager (Deprecated)

/**
 * These methods are deprecated - use the data-based alternatives instead.
 */
- (NSString *)storeImage:(NSImage *)image __deprecated;
- (NSImage *)imageForTag:(NSString *)imageTag __deprecated;
- (void)getImageForTag:(NSString *)imageTag withBlock:(void (^)(NSImage *image))block __deprecated;

@end

@interface RCTBridge (RCTImageStoreManager)

@property (nonatomic, readonly) RCTImageStoreManager *imageStoreManager;

@end
