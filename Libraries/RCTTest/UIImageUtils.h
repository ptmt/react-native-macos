//
//  UIImageUtils.h
//  RCTTest
//
//  Created by Dmitriy Loktev on 10/19/15.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// TODO: move it to the right place
// https://github.com/BigZaphod/Chameleon/blob/84605ede274bd82b330d72dd6ac41e64eb925fd7/UIKit/Classes/UIImage.m
NSData *UIImagePNGRepresentation(NSImage *image);

void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);

void UIGraphicsPushContext(CGContextRef ctx);
void UIGraphicsPopContext();

CGContextRef UIGraphicsGetCurrentContext();

NSImage *UIGraphicsGetImageFromCurrentImageContext();

void UIGraphicsEndImageContext();