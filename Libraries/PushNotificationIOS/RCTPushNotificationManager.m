/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTPushNotificationManager.h"

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0

#define UIUserNotificationTypeAlert UIRemoteNotificationTypeAlert
#define UIUserNotificationTypeBadge UIRemoteNotificationTypeBadge
#define UIUserNotificationTypeSound UIRemoteNotificationTypeSound
#define UIUserNotificationTypeNone  UIRemoteNotificationTypeNone
#define UIUserNotificationType      UIRemoteNotificationType

#endif

NSString *const RCTLocalNotificationReceived = @"LocalNotificationReceived";
NSString *const RCTRemoteNotificationReceived = @"RemoteNotificationReceived";
NSString *const RCTRemoteNotificationsRegistered = @"RemoteNotificationsRegistered";

@implementation RCTConvert (NSUserNotification)

+ (NSUserNotification *)NSUserNotification:(id)json
{
  NSDictionary<NSString *, id> *details = [self NSDictionary:json];
  NSUserNotification *notification = [NSUserNotification new];
  notification.deliveryDate = [RCTConvert NSDate:details[@"fireDate"]] ?: [NSDate date];
  notification.informativeText = [RCTConvert NSString:details[@"alertBody"]];
  notification.soundName = [RCTConvert NSString:details[@"soundName"]] ?: NSUserNotificationDefaultSoundName;
  notification.userInfo = [RCTConvert NSDictionary:details[@"userInfo"]];
  if (details[@"title"]) {
    notification.title = [RCTConvert NSString:details[@"title"]];
  }
  return notification;
}

@end

@implementation RCTPushNotificationManager

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
  // We're only overriding this to ensure the module gets created at startup
  // TODO (t11106126): Remove once we have more declarative control over module setup.
  return [super init];
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;

  // TODO: if we add an explicit "startObserving" method, we can take this out
  // of the application startup path

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleLocalNotificationReceived:)
                                               name:RCTLocalNotificationReceived
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRemoteNotificationReceived:)
                                               name:RCTRemoteNotificationReceived
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRemoteNotificationsRegistered:)
                                               name:RCTRemoteNotificationsRegistered
                                             object:nil];

  [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  NSDictionary<NSString *, id> *initialNotification =
    [_bridge.launchOptions[NSApplicationLaunchUserNotificationKey] copy];
  return @{@"initialNotification": RCTNullIfNil(initialNotification)};
}

+ (void)didRegisterUserNotificationSettings
{
  if ([NSApplication instancesRespondToSelector:@selector(registerForRemoteNotifications)]) {
    //[[NSApplication sharedApplication] registerForRemoteNotifications];
  }
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  NSMutableString *hexString = [NSMutableString string];
  NSUInteger deviceTokenLength = deviceToken.length;
  const unsigned char *bytes = deviceToken.bytes;
  for (NSUInteger i = 0; i < deviceTokenLength; i++) {
    [hexString appendFormat:@"%02x", bytes[i]];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTRemoteNotificationsRegistered
                                                      object:self
                                                    userInfo:@{@"deviceToken" : [hexString copy]}];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)notification
{
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTRemoteNotificationReceived
                                                      object:self
                                                    userInfo:notification];
}

+ (void)didReceiveLocalNotification:(NSUserNotification*)notification
{
  NSMutableDictionary *details = [NSMutableDictionary new];
  if (notification.informativeText) {
    details[@"alertBody"] = notification.informativeText;
  }
  if (notification.userInfo) {
    details[@"userInfo"] = RCTJSONClean(notification.userInfo);
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTLocalNotificationReceived
                                                      object:self
                                                    userInfo:details];
}

- (void)handleLocalNotificationReceived:(NSNotification *)notification
{
  [_bridge.eventDispatcher sendDeviceEventWithName:@"localNotificationReceived"
                                              body:notification.userInfo];
}

- (void)handleRemoteNotificationReceived:(NSNotification *)notification
{
  [_bridge.eventDispatcher sendDeviceEventWithName:@"remoteNotificationReceived"
                                              body:notification.userInfo];
}

- (void)handleRemoteNotificationsRegistered:(NSNotification *)notification
{
  [_bridge.eventDispatcher sendDeviceEventWithName:@"remoteNotificationsRegistered"
                                              body:notification.userInfo];
}


- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
  [center removeDeliveredNotification: notification];
  [_bridge.eventDispatcher sendDeviceEventWithName:@"localNotificationClicked"
                                              body:notification.userInfo];
}

/**
 * Update the application icon badge number on the home screen
 */
RCT_EXPORT_METHOD(setApplicationIconBadgeNumber:(NSInteger)number)
{
  RCTSharedApplication().dockTile.badgeLabel = @(number);
}

/**
 * Get the current application icon badge number on the home screen
 */
RCT_EXPORT_METHOD(getApplicationIconBadgeNumber:(RCTResponseSenderBlock)callback)
{
  callback(@[RCTSharedApplication().dockTile.badgeLabel]);
}

RCT_EXPORT_METHOD(requestPermissions:(NSDictionary *)permissions)
{
  if (RCTRunningInAppExtension()) {
    return;
  }
//
//  UIUserNotificationType types = UIUserNotificationTypeNone;
//  if (permissions) {
//    if ([RCTConvert BOOL:permissions[@"alert"]]) {
//      types |= UIUserNotificationTypeAlert;
//    }
//    if ([RCTConvert BOOL:permissions[@"badge"]]) {
//      types |= UIUserNotificationTypeBadge;
//    }
//    if ([RCTConvert BOOL:permissions[@"sound"]]) {
//      types |= UIUserNotificationTypeSound;
//    }
//  } else {
//    types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
//  }
//
//  UIApplication *app = RCTSharedApplication();
//  if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
//    UIUserNotificationSettings *notificationSettings =
//      [UIUserNotificationSettings settingsForTypes:(NSUInteger)types categories:nil];
//    [app registerUserNotificationSettings:notificationSettings];
//  } else {
//    [app registerForRemoteNotificationTypes:(NSUInteger)types];
//  }
}

RCT_EXPORT_METHOD(abandonPermissions)
{
  [RCTSharedApplication() unregisterForRemoteNotifications];
}

RCT_EXPORT_METHOD(checkPermissions:(RCTResponseSenderBlock)callback)
{
  callback(@[@{@"alert": @YES, @"badge": @YES, @"sound": @YES}]);
//  if (RCTRunningInAppExtension()) {
//    callback(@[@{@"alert": @NO, @"badge": @NO, @"sound": @NO}]);
//    return;
//  }
//
//  NSUInteger types = 0;
//  if ([NSApplication instancesRespondToSelector:@selector(currentUserNotificationSettings)]) {
//    types = [RCTSharedApplication() currentUserNotificationSettings].types;
//  } else {
//
//#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
//
//    types = [RCTSharedApplication() enabledRemoteNotificationTypes];
//
//#endif
//
//  }
//
//  callback(@[@{
//    @"alert": @((types & UIUserNotificationTypeAlert) > 0),
//    @"badge": @((types & UIUserNotificationTypeBadge) > 0),
//    @"sound": @((types & UIUserNotificationTypeSound) > 0),
//  }]);
}

RCT_EXPORT_METHOD(presentLocalNotification:(NSUserNotification *)notification)
{
  [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

RCT_EXPORT_METHOD(scheduleLocalNotification:(NSUserNotification *)notification)
{
  [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

RCT_EXPORT_METHOD(cancelAllLocalNotifications)
{
  for (NSUserNotification *notification in [NSUserNotificationCenter defaultUserNotificationCenter].scheduledNotifications) {
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotification:notification];
  }
}

RCT_EXPORT_METHOD(cancelLocalNotifications:(NSDictionary *)userInfo)
{
  for (NSUserNotification *notification in [NSUserNotificationCenter defaultUserNotificationCenter].scheduledNotifications) {
    __block BOOL matchesAll = YES;
    NSDictionary *notificationInfo = notification.userInfo;
    [userInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
      if (![notificationInfo[key] isEqual:obj]) {
        matchesAll = NO;
        *stop = YES;
      }
    }];
    if (matchesAll) {
      [[NSUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotification:notification];
    }
  }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
  return YES;
}

@end
