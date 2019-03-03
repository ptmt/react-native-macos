/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTKeyCommands.h"

#import <AppKit/AppKit.h>

#import "RCTDefines.h"
#import "RCTUtils.h"

#if RCT_DEV

@interface RCTKeyCommand : NSObject <NSCopying>

@property (nonatomic, strong) NSString *keyCommand;
@property (nonatomic) NSEventModifierFlags modifierFlags;
@property (nonatomic, copy) void (^block)(NSEvent *);

@end

@implementation RCTKeyCommand

- (instancetype)initWithKeyCommand:(NSString *)keyCommand
                     modifierFlags:(NSEventModifierFlags)modifierFlags
                             block:(void (^)(NSEvent *))block
{
  if ((self = [super init])) {
    _keyCommand = keyCommand;
    _modifierFlags = modifierFlags;
    _block = block;
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)init)

- (id)copyWithZone:(__unused NSZone *)zone
{
  return self;
}

- (NSUInteger)hash
{
  return _keyCommand.hash ^ _modifierFlags;
}

- (BOOL)isEqual:(RCTKeyCommand *)object
{
  if (![object isKindOfClass:[RCTKeyCommand class]]) {
    return NO;
  }
  return [self matchesInput:object.keyCommand
                      flags:object.modifierFlags];
}

- (BOOL)matchesInput:(NSString*)keyCommand flags:(int)flags
{
  return [_keyCommand isEqual:keyCommand] && _modifierFlags == flags;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@:%p input=\"%@\" flags=%zd hasBlock=%@>",
          [self class], self, _keyCommand, _modifierFlags,
          _block ? @"YES" : @"NO"];
}

@end

@interface RCTKeyCommands ()

@property (nonatomic, strong) NSMutableSet<RCTKeyCommand *> *commands;

@end


@implementation NSWindow (RCTKeyCommands)

- (void)keyDown:(NSEvent *)theEvent
{
  for (RCTKeyCommand *command in [RCTKeyCommands sharedInstance].commands) {
    if ([command.keyCommand isEqualToString:theEvent.characters] &&
        command.modifierFlags == (theEvent.modifierFlags & NSDeviceIndependentModifierFlagsMask)) {
      if (command.block) {
        command.block(theEvent);
      }
      return;
    }
  }

  [super keyDown:theEvent];
}

@end

@implementation RCTKeyCommands

+ (void)initialize
{

}

+ (instancetype)sharedInstance
{
  static RCTKeyCommands *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [self new];
  });

  return sharedInstance;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _commands = [NSMutableSet new];
  }
  return self;
}

- (void)registerKeyCommandWithInput:(NSString *)input
                      modifierFlags:(NSEventModifierFlags)flags
                             action:(void (^)(NSEvent *))block
{
  RCTAssertMainQueue();

  RCTKeyCommand *keyCommand = [[RCTKeyCommand alloc] initWithKeyCommand:input modifierFlags:flags block:block];
  [_commands removeObject:keyCommand];
  [_commands addObject:keyCommand];
}

- (void)unregisterKeyCommandWithInput:(NSString *)input
                        modifierFlags:(NSEventModifierFlags)flags
{
  RCTAssertMainQueue();

  for (RCTKeyCommand *command in _commands.allObjects) {
    if ([command matchesInput:input flags:flags]) {
      [_commands removeObject:command];
      break;
    }
  }
}

- (BOOL)isKeyCommandRegisteredForInput:(NSString *)input
                         modifierFlags:(NSEventModifierFlags)flags
{
  RCTAssertMainQueue();

  for (RCTKeyCommand *command in _commands) {
    if ([command matchesInput:input flags:flags]) {
      return YES;
    }
  }
  return NO;
}

- (void)registerDoublePressKeyCommandWithInput:(NSString *)input
                      modifierFlags:(NSEventModifierFlags)flags
                             action:(void (^)(NSEvent *))block
{
  RCTAssertMainQueue();

//  NSEvent *command = [NSEvent keyCommandWithInput:input
//                                              modifierFlags:flags
//                                                     action:@selector(RCT_handleDoublePressKeyCommand:)];
//
//  RCTKeyCommand *keyCommand = [[RCTKeyCommand alloc] initWithKeyCommand:command block:block];
//  [_commands removeObject:keyCommand];
//  [_commands addObject:keyCommand];
}

- (void)unregisterDoublePressKeyCommandWithInput:(NSString *)input
                        modifierFlags:(NSEventModifierFlags)flags
{
  RCTAssertMainQueue();

  for (RCTKeyCommand *command in _commands.allObjects) {
    if ([command matchesInput:input flags:flags]) {
      [_commands removeObject:command];
      break;
    }
  }
}

- (BOOL)isDoublePressKeyCommandRegisteredForInput:(NSString *)input
                         modifierFlags:(NSEventModifierFlags)flags
{
  RCTAssertMainQueue();

  for (RCTKeyCommand *command in _commands) {
    if ([command matchesInput:input flags:flags]) {
      return YES;
    }
  }
  return NO;
}

@end

#else

@implementation RCTKeyCommands

+ (instancetype)sharedInstance
{
  return nil;
}

- (void)registerKeyCommandWithInput:(__unused NSString *)input
                      modifierFlags:(__unused NSEventModifierFlags)flags
                             action:(void (^)(__unused NSEvent *))block {}

- (void)unregisterKeyCommandWithInput:(__unused NSString *)input
                        modifierFlags:(__unused NSEventModifierFlags)flags {}

- (BOOL)isKeyCommandRegisteredForInput:(__unused NSString *)input
                         modifierFlags:(__unused NSEventModifierFlags)flags
{
  return NO;
}

- (void)registerDoublePressKeyCommandWithInput:(NSString *)input
                      modifierFlags:(NSEventModifierFlags)flags
                             action:(void (^)(NSEvent *))block {}

- (void)unregisterDoublePressKeyCommandWithInput:(NSString *)input
                        modifierFlags:(NSEventModifierFlags)flags {}

- (BOOL)isDoublePressKeyCommandRegisteredForInput:(NSString *)input
                         modifierFlags:(NSEventModifierFlags)flags
{
  return NO;
}

@end

#endif
