/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import "RCTDevMenu.h"

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTDefines.h"
#import "RCTEventDispatcher.h"
#import "RCTKeyCommands.h"
#import "RCTLog.h"
#import "RCTPerfStats.h"
#import "RCTProfile.h"
#import "RCTRootView.h"
#import "RCTSourceCode.h"
#import "RCTUtils.h"

#if RCT_DEV

@interface RCTBridge (Profiling)

- (void)startProfiling;
- (void)stopProfiling:(void (^)(NSData *))callback;

@end

static NSString *const RCTShowDevMenuNotification = @"RCTShowDevMenuNotification";
static NSString *const RCTDevMenuSettingsKey = @"RCTDevMenu";


typedef NS_ENUM(NSInteger, RCTDevMenuType) {
  RCTDevMenuTypeButton,
  RCTDevMenuTypeToggle
};

@interface RCTDevMenuItem ()

@property (nonatomic, assign, readonly) RCTDevMenuType itemType;
@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *selectedTitle;
@property (nonatomic, copy) id value;
@property (nonatomic, copy) NSString *hotKey;

- (void)callHandler;

@end

@implementation RCTDevMenuItem
{
  id _handler; // block
}

- (instancetype)initWithType:(RCTDevMenuType)itemType
                         key:(NSString *)key
                       title:(NSString *)title
               selectedTitle:(NSString *)selectedTitle
                     handler:(id /* block */)handler
{
  if ((self = [super init])) {
    _itemType = itemType;
    _key = [key copy];
    [self setTitle:title];
    _selectedTitle = [selectedTitle copy];
    _handler = [handler copy];
    _value = nil;
    [self setAction:@selector(callHandler)];
    [self setTarget:self];
    // [self keyEquivalent:] TODO: key equeiavalent
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)init)

+ (instancetype)buttonItemWithTitle:(NSString *)title
                            handler:(void (^)(void))handler
{
  return [[self alloc] initWithType:RCTDevMenuTypeButton
                                key:nil
                              title:title
                      selectedTitle:nil
                            handler:handler];
}

+ (instancetype)toggleItemWithKey:(NSString *)key
                            title:(NSString *)title
                    selectedTitle:(NSString *)selectedTitle
                          handler:(void (^)(BOOL selected))handler
{
  return [[self alloc] initWithType:RCTDevMenuTypeToggle
                                key:key
                              title:title
                      selectedTitle:selectedTitle
                            handler:handler];
}

- (void)callHandler
{
  switch (_itemType) {
    case RCTDevMenuTypeButton: {
      if (_handler) {
        ((void(^)())_handler)();
      }
      break;
    }
    case RCTDevMenuTypeToggle: {
      if (_handler) {
        ((void(^)(BOOL selected))_handler)([_value boolValue]);
      }
      break;
    }
  }
}

@end

@interface RCTDevMenu () <RCTBridgeModule, RCTInvalidating>

@property (nonatomic, strong) Class executorClass;

@end

@implementation RCTDevMenu
{
  NSUserDefaults *_defaults;
  NSMutableDictionary *_settings;
  NSURLSessionDataTask *_updateTask;
  NSURL *_liveReloadURL;
  BOOL _jsLoaded;
  NSArray *_presentedItems;
  NSMutableArray *_extraMenuItems;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

+ (void)initialize
{
  // We're swizzling here because it's poor form to override methods in a category,
  // however UIWindow doesn't actually implement motionEnded:withEvent:, so there's
  // no need to call the original implementation.
  //RCTSwapInstanceMethods([UIWindow class], @selector(motionEnded:withEvent:), @selector(RCT_motionEnded:withEvent:));
}

- (instancetype)init
{
  if ((self = [super init])) {

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(settingsDidChange)
                               name:NSUserDefaultsDidChangeNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(jsLoaded:)
                               name:RCTJavaScriptDidLoadNotification
                             object:nil];

    _defaults = [NSUserDefaults standardUserDefaults];
    _settings = [[NSMutableDictionary alloc] initWithDictionary:[_defaults objectForKey:RCTDevMenuSettingsKey]];
    _extraMenuItems = [NSMutableArray new];

    __weak RCTDevMenu *weakSelf = self;

    [_extraMenuItems addObject:[RCTDevMenuItem toggleItemWithKey:@"showFPS"
                                               title:@"Show FPS Monitor"
                                       selectedTitle:@"Hide FPS Monitor"
                                             handler:^(BOOL showFPS)
    {
      RCTDevMenu *strongSelf = weakSelf;
      if (strongSelf) {
        strongSelf->_showFPS = showFPS;
        if (showFPS) {
          [strongSelf.bridge.perfStats show];
        } else {
          [strongSelf.bridge.perfStats hide];
        }
      }
    }]];

    [_extraMenuItems addObject:[RCTDevMenuItem toggleItemWithKey:@"showInspector"
                                                 title:@"Show Inspector"
                                         selectedTitle:@"Hide Inspector"
                                               handler:^(__unused BOOL enabled)
    {
      [weakSelf.bridge.eventDispatcher sendDeviceEventWithName:@"toggleElementInspector" body:nil];
    }]];

    // Delay setup until after Bridge init
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf updateSettings:_settings];
    });

    RCTKeyCommands *commands = [RCTKeyCommands sharedInstance];

    // Toggle element inspector
    [commands registerKeyCommandWithInput:@"d"
                            modifierFlags:NSCommandKeyMask
                                   action:^(__unused NSEvent *command) {
                                     [self toggle];
                                   }];

    // Toggle element inspector
    [commands registerKeyCommandWithInput:@"i"
                            modifierFlags:NSCommandKeyMask
                                   action:^(__unused NSEvent *command) {
                                     [weakSelf.bridge.eventDispatcher
                                      sendDeviceEventWithName:@"toggleElementInspector"
                                      body:nil];
                                   }];

    // Reload in normal mode
    [commands registerKeyCommandWithInput:@"n"
                            modifierFlags:NSCommandKeyMask
                                   action:^(__unused NSEvent *command) {
                                     weakSelf.executorClass = Nil;
                                   }];


  }
  return self;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)settingsDidChange
{
  // Needed to prevent a race condition when reloading
  __weak RCTDevMenu *weakSelf = self;
  NSDictionary *settings = [_defaults objectForKey:RCTDevMenuSettingsKey];
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf updateSettings:settings];
  });
}

/**
 * This method loads the settings from NSUserDefaults and overrides any local
 * settings with them. It should only be called on app launch, or after the app
 * has returned from the background, when the settings might have been edited
 * outside of the app.
 */
- (void)updateSettings:(NSDictionary *)settings
{
  [_settings setDictionary:settings];

  // Fire handlers for items whose values have changed
  for (RCTDevMenuItem *item in _extraMenuItems) {
    if (item.key) {
      id value = settings[item.key];
      if (value != item.value && ![value isEqual:item.value]) {
        item.value = value;
        [item callHandler];
      }
    }
  }

  self.profilingEnabled = [_settings[@"profilingEnabled"] ?: @NO boolValue];
  self.liveReloadEnabled = [_settings[@"liveReloadEnabled"] ?: @NO boolValue];
  self.showFPS = [_settings[@"showFPS"] ?: @NO boolValue];
  self.executorClass = NSClassFromString(_settings[@"executorClass"]);
}

/**
 * This updates a particular setting, and then saves the settings. Because all
 * settings are overwritten by this, it's important that this is not called
 * before settings have been loaded initially, otherwise the other settings
 * will be reset.
 */
- (void)updateSetting:(NSString *)name value:(id)value
{
  // Fire handler for item whose values has changed
  for (RCTDevMenuItem *item in _extraMenuItems) {
    if ([item.key isEqualToString:name]) {
      if (value != item.value && ![value isEqual:item.value]) {
        item.value = value;
        [item callHandler];
      }
      break;
    }
  }

  // Save the setting
  id currentValue = _settings[name];
  if (currentValue == value || [currentValue isEqual:value]) {
    return;
  }
  if (value) {
    _settings[name] = value;
  } else {
    [_settings removeObjectForKey:name];
  }
  [_defaults setObject:_settings forKey:RCTDevMenuSettingsKey];
  [_defaults synchronize];
}

- (void)jsLoaded:(NSNotification *)notification
{
  if (notification.userInfo[@"bridge"] != _bridge) {
    return;
  }

  _jsLoaded = YES;

  // Check if live reloading is available
  _liveReloadURL = nil;
  RCTSourceCode *sourceCodeModule = _bridge.modules[RCTBridgeModuleNameForClass([RCTSourceCode class])];
  if (!sourceCodeModule.scriptURL) {
    if (!sourceCodeModule) {
      RCTLogWarn(@"RCTSourceCode module not found");
    } else {
      RCTLogWarn(@"RCTSourceCode module scriptURL has not been set");
    }
  } else if (!(sourceCodeModule.scriptURL).fileURL) {
    // Live reloading is disabled when running from bundled JS file
    _liveReloadURL = [[NSURL alloc] initWithString:@"/onchange" relativeToURL:sourceCodeModule.scriptURL];
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    // Hit these setters again after bridge has finished loading
    self.profilingEnabled = _profilingEnabled;
    self.liveReloadEnabled = _liveReloadEnabled;
    self.executorClass = _executorClass;

    // Inspector can only be shown after JS has loaded
    if ([_settings[@"showInspector"] boolValue]) {
      [self.bridge.eventDispatcher sendDeviceEventWithName:@"toggleElementInspector" body:nil];
    }
  });
}

- (void)invalidate
{
  _presentedItems = nil;
  [_updateTask cancel];
  //[_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:YES];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showOnShake
{
  if (_shakeToShow) {
    [self show];
  }
}

- (void)toggle
{
//  if (_actionSheet) {
////    [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:YES];
////    _actionSheet = nil;
//  } else {
//    [self show];
//  }
  [self show];
}

- (void)addItem:(NSString *)title handler:(void(^)(void))handler
{
  [self addItem:[RCTDevMenuItem buttonItemWithTitle:title handler:handler]];
}

- (void)addItem:(RCTDevMenuItem *)item
{
  [_extraMenuItems addObject:item];

  // Fire handler for items whose saved value doesn't match the default
  [self settingsDidChange];
}

- (NSArray *)menuItems
{
  NSMutableArray *items = [NSMutableArray new];

  // Add built-in items

  __weak RCTDevMenu *weakSelf = self;

  [items addObject:[RCTDevMenuItem buttonItemWithTitle:@"Reload" handler:^{
    [weakSelf reload];
  }]];

  Class chromeExecutorClass = NSClassFromString(@"RCTWebSocketExecutor");
  if (!chromeExecutorClass) {
    [items addObject:[RCTDevMenuItem buttonItemWithTitle:@"Chrome Debugger Unavailable" handler:^{
      NSAlert *alert = RCTAlertView(@"Chrome Debugger Unavailable", @"You need to include the RCTWebSocket library to enable Chrome debugging", nil, @"OK", nil);
      [alert runModal];
    }]];
  } else {
    BOOL isDebuggingInChrome = _executorClass && _executorClass == chromeExecutorClass;
    NSLog(@"isDebuggingInChrome %hhd", isDebuggingInChrome);
    NSString *debugTitleChrome = isDebuggingInChrome ? @"Disable Chrome Debugging" : @"Debug in Chrome";
    [items addObject:[RCTDevMenuItem buttonItemWithTitle:debugTitleChrome handler:^{
      weakSelf.executorClass = isDebuggingInChrome ? Nil : chromeExecutorClass;
    }]];
  }

  Class safariExecutorClass = NSClassFromString(@"RCTWebViewExecutor");
  BOOL isDebuggingInSafari = _executorClass && _executorClass == safariExecutorClass;
  NSString *debugTitleSafari = isDebuggingInSafari ? @"Disable Safari Debugging" : @"Debug in Safari";
  [items addObject:[RCTDevMenuItem buttonItemWithTitle:debugTitleSafari handler:^{
    weakSelf.executorClass = isDebuggingInSafari ? Nil : safariExecutorClass;
  }]];

  if (_liveReloadURL) {
    NSString *liveReloadTitle = _liveReloadEnabled ? @"Disable Live Reload" : @"Enable Live Reload";
    [items addObject:[RCTDevMenuItem buttonItemWithTitle:liveReloadTitle handler:^{
      weakSelf.liveReloadEnabled = !_liveReloadEnabled;
    }]];

    NSString *profilingTitle  = RCTProfileIsProfiling() ? @"Stop Systrace" : @"Start Systrace";
    [items addObject:[RCTDevMenuItem buttonItemWithTitle:profilingTitle handler:^{
      weakSelf.profilingEnabled = !_profilingEnabled;
    }]];
  }

  [items addObjectsFromArray:_extraMenuItems];

  return items;
}

RCT_EXPORT_METHOD(show)
{
  if ([NSApp mainMenu].itemArray.lastObject && [[NSApp mainMenu].itemArray.lastObject.submenu.title isEqualToString:@"Developer"]) {
    return;
  }
  NSMenuItem *developerItemContainer = [[NSMenuItem alloc] init]; //WithTitle:@"Developer" action:nil keyEquivalent:@"d"
  NSMenu *developerMenu = [[NSMenu alloc] initWithTitle:@"Developer"];
  [developerItemContainer setSubmenu:developerMenu];

  NSArray *items = [self menuItems];
  for (RCTDevMenuItem *item in items) {
    [developerMenu addItem:item];
  }

  //TODO: update settings, update menu titles

  [[NSApp mainMenu] addItem:developerItemContainer];

  return;
}

RCT_EXPORT_METHOD(reload)
{
  _jsLoaded = NO;
  _liveReloadURL = nil;
  [_bridge reload];
}

- (void)setProfilingEnabled:(BOOL)enabled
{
  _profilingEnabled = enabled;
  [self updateSetting:@"profilingEnabled" value:@(_profilingEnabled)];

  if (_liveReloadURL && enabled != RCTProfileIsProfiling()) {
    if (enabled) {
      [_bridge startProfiling];
    } else {
      [_bridge stopProfiling:^(NSData *logData) {
        RCTProfileSendResult(_bridge, @"systrace", logData);
      }];
    }
  }
}

- (void)setLiveReloadEnabled:(BOOL)enabled
{
  _liveReloadEnabled = enabled;
  [self updateSetting:@"liveReloadEnabled" value:@(_liveReloadEnabled)];

  if (_liveReloadEnabled) {
    [self checkForUpdates];
  } else {
    [_updateTask cancel];
    _updateTask = nil;
  }
}

- (void)setExecutorClass:(Class)executorClass
{
  if (_executorClass != executorClass) {
    _executorClass = executorClass;
    [self updateSetting:@"executorClass" value:NSStringFromClass(executorClass)];
  }

  if (_bridge.executorClass != executorClass) {

    // TODO (6929129): we can remove this special case test once we have better
    // support for custom executors in the dev menu. But right now this is
    // needed to prevent overriding a custom executor with the default if a
    // custom executor has been set directly on the bridge
    if (executorClass == Nil &&
        (_bridge.executorClass != NSClassFromString(@"RCTWebSocketExecutor") &&
         _bridge.executorClass != NSClassFromString(@"RCTWebViewExecutor"))) {
      return;
    }

    _bridge.executorClass = executorClass;
    [self reload];
  }
}

- (void)setShowFPS:(BOOL)showFPS
{
  _showFPS = showFPS;
  [self updateSetting:@"showFPS" value:@(showFPS)];
}

- (void)checkForUpdates
{
  if (!_jsLoaded || !_liveReloadEnabled || !_liveReloadURL) {
    return;
  }

  if (_updateTask) {
    [_updateTask cancel];
    _updateTask = nil;
    return;
  }

  __weak RCTDevMenu *weakSelf = self;
  _updateTask = [[NSURLSession sharedSession] dataTaskWithURL:_liveReloadURL completionHandler:
                 ^(__unused NSData *data, NSURLResponse *response, NSError *error) {

    dispatch_async(dispatch_get_main_queue(), ^{
      RCTDevMenu *strongSelf = weakSelf;
      if (strongSelf && strongSelf->_liveReloadEnabled) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        if (!error && HTTPResponse.statusCode == 205) {
          [strongSelf reload];
        } else {
          strongSelf->_updateTask = nil;
          [strongSelf checkForUpdates];
        }
      }
    });

  }];

  [_updateTask resume];
}

@end

#else // Unavailable when not in dev mode

@implementation RCTDevMenu

- (void)show {}
- (void)reload {}
- (void)addItem:(NSString *)title handler:(dispatch_block_t)handler {}
- (void)addItem:(RCTDevMenu *)item {}

@end

#endif

@implementation  RCTBridge (RCTDevMenu)

- (RCTDevMenu *)devMenu
{
#if RCT_DEV
  return self.modules[RCTBridgeModuleNameForClass([RCTDevMenu class])];
#else
  return nil;
#endif
}

@end
