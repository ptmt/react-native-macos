/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTLinkingManager.h"

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>

static NSString *const kOpenURLNotification = @"RCTOpenURLNotification";

static void postNotificationWithURL(NSURL *URL, id sender)
{
  NSDictionary<NSString *, id> *payload = @{@"url": URL.absoluteString};
  [[NSNotificationCenter defaultCenter] postNotificationName:kOpenURLNotification
                                                      object:sender
                                                    userInfo:payload];
}

@implementation RCTLinkingManager

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
  [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleOpenURLNotification:)
                                               name:kOpenURLNotification
                                             object:nil];
}

- (void)stopObserving
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  NSString *argv = _bridge.launchOptions[@"argv"];
  return @{@"argv": RCTNullIfNil(argv)};
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"url"];
}

+ (BOOL)application:(NSApplication *)application
            openURL:(NSURL *)URL
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  postNotificationWithURL(URL, self);
  return YES;
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    [[NSApp mainWindow] makeKeyAndOrderFront:nil];
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSDictionary *payload = @{@"url": url};
    [self sendEventWithName:@"url" body:payload];
}

+ (BOOL)application:(NSApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
  restorationHandler:(void (^)(NSArray *))restorationHandler
{
  if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
    NSDictionary *payload = @{@"url": userActivity.webpageURL.absoluteString};
    [[NSNotificationCenter defaultCenter] postNotificationName:kOpenURLNotification
                                                        object:self
                                                      userInfo:payload];
  }
  return YES;
}

- (void)handleOpenURLNotification:(NSNotification *)notification
{
  [self sendEventWithName:@"url" body:notification.userInfo];
}

RCT_EXPORT_METHOD(openURL:(NSURL *)URL
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  // TODO: we should really return success/failure via a Promise reject/resolve here
  // Doesn't really matter what thread we call this on since it exits the app
  [[NSWorkspace sharedWorkspace] openURL:URL];
}


//TODO: implement canOpenURL or add different apis such as open File, launchApplication
RCT_EXPORT_METHOD(canOpenURL:(NSURL *)URL
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  if (RCTRunningInAppExtension()) {
    // Technically Today widgets can open urls, but supporting that would require
    // a reference to the NSExtensionContext
    resolve(@NO);
    return;
  }

  // TODO: on iOS9 this will fail if URL isn't included in the plist
  // we should probably check for that and reject in that case instead of
  // simply resolving with NO

  // This can be expensive, so we deliberately don't call on main thread
  BOOL canOpen = YES; // TODO: actual checking
  resolve(@(canOpen));
}

    /*
RCT_EXPORT_METHOD(getInitialURL:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  NSURL *initialURL = nil;
  if (self.bridge.launchOptions[UIApplicationLaunchOptionsURLKey]) {
    initialURL = self.bridge.launchOptions[UIApplicationLaunchOptionsURLKey];
  } else {
    NSDictionary *userActivityDictionary =
      self.bridge.launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
    if ([userActivityDictionary[UIApplicationLaunchOptionsUserActivityTypeKey] isEqual:NSUserActivityTypeBrowsingWeb]) {
      initialURL = ((NSUserActivity *)userActivityDictionary[@"UIApplicationLaunchOptionsUserActivityKey"]).webpageURL;
    }
  }
  resolve(RCTNullIfNil(initialURL.absoluteString));
}
*/
@end
