/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTAppState.h"

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"

static NSString *RCTCurrentAppBackgroundState()
{
  static NSDictionary *states;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    states = @{
//      @(NSApplication): @"active",
//      @(UIApplicationStateBackground): @"background",
//      @(UIApplicationStateInactive): @"inactive"
    };
  });

  if (RCTRunningInAppExtension()) {
    return @"extension";
  }

  //return states[@(RCTSharedApplication().applicationState)] ?: @"unknown";
  return @"unknown";
}

@implementation RCTAppState
{
  NSString *_lastKnownState;
}

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (NSDictionary *)constantsToExport
{
  return @{@"initialAppState": RCTCurrentAppBackgroundState()};
}

#pragma mark - Lifecycle

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"appStateDidChange", @"memoryWarning"];
}

- (void)startObserving
{
  _lastKnownState = RCTCurrentAppBackgroundState();

  for (NSString *name in @[NSApplicationWillBecomeActiveNotification,
                           NSApplicationDidHideNotification,
                           NSApplicationDidFinishLaunchingNotification]) {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppStateDidChange)
                                                 name:name
                                               object:nil];
  }
}

- (void)stopObserving
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - App Notification Methods

- (void)handleAppStateDidChange
{
  NSString *newState = RCTCurrentAppBackgroundState();
  if (![newState isEqualToString:_lastKnownState]) {
    _lastKnownState = newState;
    [self sendEventWithName:@"appStateDidChange"
                       body:@{@"app_state": _lastKnownState}];
  }
}

#pragma mark - Public API

/**
 * Get the current background/foreground state of the app
 */
RCT_EXPORT_METHOD(getCurrentAppState:(RCTResponseSenderBlock)callback
                  error:(__unused RCTResponseSenderBlock)error)
{
  callback(@[@{@"app_state": RCTCurrentAppBackgroundState()}]);
}

RCT_EXPORT_METHOD(exit)
{
  [RCTSharedApplication() terminate:self];
}

@end
