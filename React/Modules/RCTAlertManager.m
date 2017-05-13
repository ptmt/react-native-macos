/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTAlertManager.h"

#import "RCTAssert.h"
#import "RCTConvert.h"
#import "RCTLog.h"
#import "RCTUtils.h"

@implementation RCTConvert (NSAlertViewStyle)

RCT_ENUM_CONVERTER(RCTAlertViewStyle, (@{
  @"default": @(RCTAlertViewStyleDefault),
  @"secure-text": @(RCTAlertViewStyleSecureTextInput),
  @"plain-text": @(RCTAlertViewStylePlainTextInput),
  @"login-password": @(RCTAlertViewStyleLoginAndPasswordInput),
}), RCTAlertViewStyleDefault, integerValue)

RCT_ENUM_CONVERTER(NSAlertStyle, (@{
  @"default": @(NSWarningAlertStyle),
  @"information": @(NSInformationalAlertStyle),
  @"critical": @(NSCriticalAlertStyle)
}), NSWarningAlertStyle, integerValue)

@end

@interface RCTAlertManager() <NSAlertDelegate>

@end

@implementation RCTAlertManager
{
  NSMutableArray<NSAlert *> *_alerts;
  NSMutableArray<RCTResponseSenderBlock> *_alertCallbacks;
  NSMutableArray<NSArray<NSString *> *> *_alertButtonKeys;
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)invalidate
{
}

/**
 * @param {NSDictionary} args Dictionary of the form
 *
 *   @{
 *     @"message": @"<Alert message>",
 *     @"buttons": @[
 *       @{@"<key1>": @"<title1>"},
 *       @{@"<key2>": @"<title2>"},
 *     ],
 *     @"cancelButtonKey": @"<key2>",
 *   }
 * The key from the `buttons` dictionary is passed back in the callback on click.
 * Buttons are displayed in the order they are specified.
 */
RCT_EXPORT_METHOD(alertWithArgs:(NSDictionary *)args
                  callback:(RCTResponseSenderBlock)callback)
{
  NSString *title = args[@"title"];
  NSString *message = args[@"message"];
  //NSString *type = args[@"type"];
  NSArray *buttons = args[@"buttons"];

  if (!title && !message) {
    RCTLogError(@"Must specify either an alert title, or message, or both");
    return;
  } else if (buttons.count == 0) {
    RCTLogError(@"Must have at least one button.");
    return;
  }

  if (buttons.count == 0) {
    if (type == RCTAlertViewStyleDefault) {
      buttons = @[@{@"0": RCTUIKitLocalizedString(@"OK")}];
      cancelButtonKey = @"0";
    } else {
      buttons = @[
        @{@"0": RCTUIKitLocalizedString(@"OK")},
        @{@"1": RCTUIKitLocalizedString(@"Cancel")},
      ];
      cancelButtonKey = @"1";
    }
  }

  NSAlert *alertView = RCTAlertView(title, message, self, nil, nil);
  NSMutableArray *buttonKeys = [[NSMutableArray alloc] initWithCapacity:buttons.count];

  NSInteger index = 0;
  for (NSDictionary *button in buttons) {
    if (button.count != 1) {
      RCTLogError(@"Button definitions should have exactly one key.");
    }
    NSString *buttonKey = button.allKeys.firstObject;
    NSString *buttonTitle = [button[buttonKey] description];
    [alertView addButtonWithTitle:buttonTitle];
    [buttonKeys addObject:buttonKey];
    index ++;
  }

  [_alerts addObject:alertView];
  [_alertCallbacks addObject:callback ?: ^(__unused id unused) {}];
  [_alertButtonKeys addObject:buttonKeys];

  NSInteger buttonPosition = [alertView runModal];
  NSString *buttonKey = [buttonKeys objectAtIndex: buttonPosition - NSAlertFirstButtonReturn];
  
  callback(@[buttonKey]);
}

@end
