//
//  UIImageUtils.h
//  RCTTest
//
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


NSData *UIImagePNGRepresentation(NSImage *image);
NSData *UIImageJPEGRepresentation(NSImage *image);

void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);

void UIGraphicsPushContext(CGContextRef ctx);
void UIGraphicsPopContext();

CGContextRef UIGraphicsGetCurrentContext();

NSImage *UIGraphicsGetImageFromCurrentImageContext();

void UIGraphicsEndImageContext();
