/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTDevMenu.h"

#import "RCTBridge+Private.h"
#import "RCTDevSettings.h"
#import "RCTKeyCommands.h"
#import "RCTLog.h"
#import "RCTUtils.h"

#define RCT_DEVMENU_TITLE @"React Native"

#if RCT_DEV

#if RCT_ENABLE_INSPECTOR
#import "RCTInspectorDevServerHelper.h"
#endif

NSString *const RCTShowDevMenuNotification = @"RCTShowDevMenuNotification";

@interface RCTDevMenuItem ()

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy) id value;
@property (nonatomic, copy) NSString *hotKey;

- (void)callHandler;

@end

@implementation RCTDevMenuItem
{
  RCTDevMenuItemTitleBlock _titleBlock;
  dispatch_block_t _handler;
}

- (instancetype)initWithTitleBlock:(RCTDevMenuItemTitleBlock)titleBlock
                           hotkey:(NSString *)hotkey
                           handler:(dispatch_block_t)handler
{
  if ((self = [super init])) {
    _titleBlock = [titleBlock copy];
    _handler = [handler copy];
    [self setAction:@selector(callHandler)];
    [self setTarget:self];
    [self setKeyEquivalent:hotkey];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)init)

+ (instancetype)buttonItemWithTitleBlock:(NSString *(^)(void))titleBlock
                                  hotkey:(NSString *)hotkey
                                 handler:(dispatch_block_t)handler
{
  return [[self alloc] initWithTitleBlock:titleBlock hotkey:hotkey handler:handler];
}

+ (instancetype)buttonItemWithTitleBlock:(NSString *(^)(void))titleBlock
                                 handler:(dispatch_block_t)handler
{
  return [[self alloc] initWithTitleBlock:titleBlock hotkey:@"" handler:handler];
}

+ (instancetype)buttonItemWithTitle:(NSString *)title
                             hotkey:(NSString *)hotkey
                            handler:(dispatch_block_t)handler
{
  return [[self alloc] initWithTitleBlock:^NSString *{ return title; } hotkey:hotkey handler:handler];
}

+ (instancetype)buttonItemWithTitle:(NSString *)title
                            handler:(dispatch_block_t)handler
{
  return [[self alloc] initWithTitleBlock:^NSString *{ return title; } hotkey:@"" handler:handler];
}

- (void)callHandler
{
  if (_handler) {
    _handler();
  }
}

- (NSString *)title
{
  if (_titleBlock) {
    return _titleBlock();
  }
  return nil;
}

@end

@interface RCTDevMenu () <RCTBridgeModule, RCTInvalidating>

@end

@implementation RCTDevMenu
{
  NSMutableArray<RCTDevMenuItem *> *_extraMenuItems;
  BOOL isShown;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

+ (void)initialize
{
  // We're swizzling here because it's poor form to override methods in a category,
  // however UIWindow doesn't actually implement motionEnded:withEvent:, so there's
  // no need to call the original implementation.
  // RCTSwapInstanceMethods([UIWindow class], @selector(motionEnded:withEvent:), @selector(RCT_motionEnded:withEvent:));
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (instancetype)init
{
  if ((self = [super init])) {
    isShown = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showOnShake)
                                                 name:RCTShowDevMenuNotification
                                               object:nil];
    _extraMenuItems = [NSMutableArray new];

#if DEBUG
    RCTKeyCommands *commands = [RCTKeyCommands sharedInstance];
    __weak __typeof(self) weakSelf = self;
    // Toggle debug menu
    [commands registerKeyCommandWithInput:@"d"
                            modifierFlags:NSEventModifierFlagCommand
                                   action:^(__unused NSEvent *command) {
                                     [weakSelf toggle];
                                   }];

    // Toggle element inspector
    [commands registerKeyCommandWithInput:@"i"
                            modifierFlags:NSEventModifierFlagCommand
                                   action:^(__unused NSEvent *command) {
                                     [weakSelf.bridge.devSettings toggleElementInspector];
                                   }];

    // Reload in normal mode
    [commands registerKeyCommandWithInput:@"n"
                            modifierFlags:NSEventModifierFlagCommand
                                   action:^(__unused NSEvent *command) {
                                     [weakSelf.bridge.devSettings setIsDebuggingRemotely:NO];
                                   }];

#endif
  }
  return self;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)invalidate
{
  _presentedItems = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showOnShake
{
  if ([_bridge.devSettings isShakeToShowDevMenuEnabled]) {
    [self show];
  }
}

- (BOOL)isActionSheetShown
{
  return isShown;
}

- (void)toggle
{
  // TODO: add invalidating/hiding
  [self show];
}

- (void)addItem:(NSString *)title handler:(void(^)(void))handler
{
  [self addItem:[RCTDevMenuItem buttonItemWithTitle:title handler:handler]];
}

- (void)addItem:(RCTDevMenuItem *)item
{
  [_extraMenuItems addObject:item];
}

- (NSArray<RCTDevMenuItem *> *)_menuItemsToPresent
{
  NSMutableArray<RCTDevMenuItem *> *items = [NSMutableArray new];

  // Add built-in items
  __weak RCTBridge *bridge = _bridge;
  __weak RCTDevSettings *devSettings = _bridge.devSettings;

  [items addObject:[RCTDevMenuItem buttonItemWithTitle:@"Reload"  hotkey:@"r" handler:^{
    [bridge reload];
  }]];

  if (devSettings.isNuclideDebuggingAvailable) {
    [items addObject:[RCTDevMenuItem buttonItemWithTitle:[NSString stringWithFormat:@"Debug JS in Nuclide %@", @"\U0001F4AF"] handler:^{
#if RCT_ENABLE_INSPECTOR
      [RCTInspectorDevServerHelper attachDebugger:@"ReactNative" withBundleURL:bridge.bundleURL withView: RCTPresentedViewController()];
#endif
    }]];
  }

  if (!devSettings.isRemoteDebuggingAvailable) {
    [items addObject:[RCTDevMenuItem buttonItemWithTitle:@"Remote JS Debugger Unavailable" handler:^{
      NSAlert *alert = RCTAlertView(@"Remote JS Debugger Unavailable",
                                    @"You need to include the RCTWebSocket library to enable remote JS debugging",
                                    nil,
                                    @"OK",
                                    nil);
      [alert runModal];
    }]];
  } else {
    [items addObject:[RCTDevMenuItem buttonItemWithTitleBlock:^NSString *{
      NSString *title = devSettings.isDebuggingRemotely ? @"Stop Remote JS Debugging" : @"Debug JS Remotely";
      if (devSettings.isNuclideDebuggingAvailable) {
        return [NSString stringWithFormat:@"%@ %@", title, @"\U0001F645"];
      } else {
        return title;
      }
    }
                                                       hotkey:@"R"
                                                      handler:^{
      devSettings.isDebuggingRemotely = !devSettings.isDebuggingRemotely;
      [self show];
    }]];
  }

  if (devSettings.isLiveReloadAvailable) {
    [items addObject:[RCTDevMenuItem buttonItemWithTitleBlock:^NSString *{
      return devSettings.isLiveReloadEnabled ? @"Disable Live Reload" : @"Enable Live Reload";
    } handler:^{
      devSettings.isLiveReloadEnabled = !devSettings.isLiveReloadEnabled;
      [self show];
    }]];
    [items addObject:[RCTDevMenuItem buttonItemWithTitleBlock:^NSString *{
      return devSettings.isProfilingEnabled ? @"Stop Systrace" : @"Start Systrace";
    } handler:^{
      devSettings.isProfilingEnabled = !devSettings.isProfilingEnabled;
      [self show];
    }]];
  }

  if (_bridge.devSettings.isHotLoadingAvailable) {
    [items addObject:[RCTDevMenuItem buttonItemWithTitleBlock:^NSString *{
      return devSettings.isHotLoadingEnabled ? @"Disable Hot Reloading" : @"Enable Hot Reloading";
    } handler:^{
      devSettings.isHotLoadingEnabled = !devSettings.isHotLoadingEnabled;
      [self show];
    }]];
  }

  if (devSettings.isJSCSamplingProfilerAvailable) {
    // Note: bridge.jsContext is not implemented in the old bridge, so this code is
    // duplicated in RCTJSCExecutor
    [items addObject:[RCTDevMenuItem buttonItemWithTitle:@"Start / Stop JS Sampling Profiler" handler:^{
      [devSettings toggleJSCSamplingProfiler];
      [self show];
    }]];
  }

  [items addObject:[RCTDevMenuItem buttonItemWithTitleBlock:^NSString *{
    return @"Toggle Inspector";
  } handler:^{
    [devSettings toggleElementInspector];
    [self show];
  }]];

  [items addObjectsFromArray:_extraMenuItems];
  return items;
}

// TODO: Use Unified Menu API, update settings, update menu titles
- (NSMenu *)getDeveloperMenu
{
  if ([[NSApp mainMenu] indexOfItemWithTitle:RCT_DEVMENU_TITLE] > -1) {
    return [[NSApp mainMenu] itemWithTitle:RCT_DEVMENU_TITLE].submenu;
  } else {
    NSMenuItem *developerItemContainer = [[NSMenuItem alloc] init];
    NSMenu *developerMenu = [[NSMenu alloc] initWithTitle:RCT_DEVMENU_TITLE];
    developerItemContainer.title = RCT_DEVMENU_TITLE;
    [[NSApp mainMenu] addItem:developerItemContainer];
    [[NSApp mainMenu] setSubmenu:developerMenu forItem:developerItemContainer];
    return developerMenu;
  }
}



RCT_EXPORT_METHOD(show)
{
  if (!_bridge || RCTRunningInAppExtension()) {
    return;
  }

  isShown = YES;

  NSArray<RCTDevMenuItem *> *items = [self _menuItemsToPresent];
  NSMenu *developerMenu = [self getDeveloperMenu];
  [developerMenu removeAllItems];
  for (RCTDevMenuItem *item in items) {
    [developerMenu addItem:item];
  }

  _presentedItems = items;
}

//- (RCTDevMenuAlertActionHandler)alertActionHandlerForDevItem:(RCTDevMenuItem *__nullable)item
//{
//  return ^(__unused UIAlertAction *action) {
//    if (item) {
//      [item callHandler];
//    }
//
//    self->_actionSheet = nil;
//  };
//}

#pragma mark - deprecated methods and properties

#define WARN_DEPRECATED_DEV_MENU_EXPORT() RCTLogWarn(@"Using deprecated method %s, use RCTDevSettings instead", __func__)

- (void)setShakeToShow:(BOOL)shakeToShow
{
  _bridge.devSettings.isShakeToShowDevMenuEnabled = shakeToShow;
}

- (BOOL)shakeToShow
{
  return _bridge.devSettings.isShakeToShowDevMenuEnabled;
}

RCT_EXPORT_METHOD(reload)
{
  WARN_DEPRECATED_DEV_MENU_EXPORT();
  [_bridge reload];
}

RCT_EXPORT_METHOD(debugRemotely:(BOOL)enableDebug)
{
  WARN_DEPRECATED_DEV_MENU_EXPORT();
  _bridge.devSettings.isDebuggingRemotely = enableDebug;
}

RCT_EXPORT_METHOD(setProfilingEnabled:(BOOL)enabled)
{
  WARN_DEPRECATED_DEV_MENU_EXPORT();
  _bridge.devSettings.isProfilingEnabled = enabled;
}

- (BOOL)profilingEnabled
{
  return _bridge.devSettings.isProfilingEnabled;
}

RCT_EXPORT_METHOD(setLiveReloadEnabled:(BOOL)enabled)
{
  WARN_DEPRECATED_DEV_MENU_EXPORT();
  _bridge.devSettings.isLiveReloadEnabled = enabled;
}

- (BOOL)liveReloadEnabled
{
  return _bridge.devSettings.isLiveReloadEnabled;
}

RCT_EXPORT_METHOD(setHotLoadingEnabled:(BOOL)enabled)
{
  WARN_DEPRECATED_DEV_MENU_EXPORT();
  _bridge.devSettings.isHotLoadingEnabled = enabled;
}

- (BOOL)hotLoadingEnabled
{
  return _bridge.devSettings.isHotLoadingEnabled;
}

@end

#else // Unavailable when not in dev mode

@implementation RCTDevMenu

- (void)show {}
- (void)reload {}
- (void)addItem:(NSString *)title handler:(dispatch_block_t)handler {}
- (void)addItem:(RCTDevMenu *)item {}
- (BOOL)isActionSheetShown { return NO; }

@end

@implementation RCTDevMenuItem

+ (instancetype)buttonItemWithTitle:(NSString *)title handler:(void(^)(void))handler {return nil;}
+ (instancetype)buttonItemWithTitleBlock:(NSString * (^)(void))titleBlock
                                 handler:(void(^)(void))handler {return nil;}

@end

#endif

@implementation  RCTBridge (RCTDevMenu)

- (RCTDevMenu *)devMenu
{
#if RCT_DEV
  return [self moduleForClass:[RCTDevMenu class]];
#else
  return nil;
#endif
}

@end
