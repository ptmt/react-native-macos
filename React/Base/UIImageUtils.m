//
//  UIImageUtils.m
//  RCTTest
//
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "UIImageUtils.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NSData *UIImagePNGRepresentation(NSImage *image)
{
  CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
  CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);

  NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:maskRef];

  NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                              [NSNumber numberWithBool:YES], NSImageProgressive, nil]];
  return pngData;
}

NSData *UIImageJPEGRepresentation(NSImage *image)
{
  //  CFMutableDataRef data = CFDataCreateMutable(NULL, 0);
  //  CGImageDestinationRef dest = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, NULL);
  //  CGImageDestinationAddImage(dest, image.CGImage, NULL);
  //  CGImageDestinationFinalize(dest);
  //  CFRelease(dest);
  CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
  CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);

  NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:maskRef];

  NSData *jpgData = [newRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                              [NSNumber numberWithBool:YES], NSImageProgressive, nil]];
  return jpgData;
}



static NSMutableArray *contextStack = nil;
static NSMutableArray *imageContextStack = nil;


void UIGraphicsPushContext(CGContextRef ctx)
{
  if (!contextStack) {
    contextStack = [[NSMutableArray alloc] initWithCapacity:1];
  }

  if ([NSGraphicsContext currentContext]) {
    [contextStack addObject:[NSGraphicsContext currentContext]];
  }

  [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:(void *)ctx flipped:YES]];
}

void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale)
{
  if (scale == 0.f) {
    scale = [NSScreen mainScreen].backingScaleFactor ?: 1;
  }

  const size_t width = size.width * scale;
  const size_t height = size.height * scale;

  if (width > 0 && height > 0) {
    if (!imageContextStack) {
      imageContextStack = [[NSMutableArray alloc] initWithCapacity:1];
    }

    [imageContextStack addObject:[NSNumber numberWithFloat:scale]];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, colorSpace, (opaque? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst));
    CGContextConcatCTM(ctx, CGAffineTransformMake(1, 0, 0, -1, 0, height));
    CGContextScaleCTM(ctx, scale, scale);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsPushContext(ctx);
    CGContextRelease(ctx);
  }
}


CGContextRef UIGraphicsGetCurrentContext()
{
  return [[NSGraphicsContext currentContext] graphicsPort];
}

NSImage *UIGraphicsGetImageFromCurrentImageContext()
{
  if ([imageContextStack lastObject]) {
    CGImageRef theCGImage = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext());
    NSImage *image = [[NSImage alloc]
                      initWithCGImage:theCGImage
                      size:NSSizeFromCGSize(CGSizeMake(CGImageGetWidth(theCGImage), CGImageGetHeight(theCGImage) ))];
    CGImageRelease(theCGImage);
    return image;
  } else {
    return nil;
  }
}

void UIGraphicsPopContext()
{
  if ([contextStack lastObject]) {
    [NSGraphicsContext setCurrentContext:[contextStack lastObject]];
    [contextStack removeLastObject];
  }
}


void UIGraphicsEndImageContext()
{
  if ([imageContextStack lastObject]) {
    [imageContextStack removeLastObject];
    UIGraphicsPopContext();
  }
}
