// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JSBase.h>
#import <AppKit/AppKit.h>

#import <React/RCTDefines.h>

#if RCT_DEV

@interface RCTInspectorDevServerHelper : NSObject

+ (void)connectWithBundleURL:(NSURL *)bundleURL;
+ (void)disableDebugger;
+ (void)attachDebugger:(NSString *)owner
         withBundleURL:(NSURL *)bundleURL
              withView:(NSViewController *)view;
@end

#endif
