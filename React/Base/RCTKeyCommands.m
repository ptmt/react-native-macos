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

@property (nonatomic, strong) NSMutableSet *commands;

@end


@implementation NSWindow (RCTKeyCommands)

- (void)keyDown:(NSEvent *)theEvent {
  [super keyDown:theEvent];
  for (RCTKeyCommand *command in [RCTKeyCommands sharedInstance].commands) {
    if ([command.keyCommand isEqualToString:theEvent.characters] &&
        command.modifierFlags == (theEvent.modifierFlags & NSDeviceIndependentModifierFlagsMask)) {
      if (command.block) {
        NSLog(@"%@", theEvent.characters);
        command.block(theEvent);
      }
    } else {
      NSLog(@"%lu %lu", (unsigned long)command.modifierFlags, (unsigned long)theEvent.modifierFlags);
    }
  }
 }

//
//// Required for iOS 8.x
//- (BOOL)RCT_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event
//{
//  if (action == @selector(RCT_handleKeyCommand:)) {
//    [self RCT_handleKeyCommand:sender];
//    return YES;
//  }
//  return [self RCT_sendAction:action to:target from:sender forEvent:event];
//}

@end

@implementation RCTKeyCommands

+ (void)initialize
{

//  RCTSwapInstanceMethods([NSApp class],
//                           @selector(keyCommands),
//                           @selector(RCT_keyCommands));
//
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
  RCTAssertMainThread();

  RCTKeyCommand *keyCommand = [[RCTKeyCommand alloc] initWithKeyCommand:input modifierFlags:flags block:block];
  NSLog(@"registering %@", input);
  [_commands removeObject:keyCommand];
  [_commands addObject:keyCommand];
}

- (void)unregisterKeyCommandWithInput:(NSString *)input
                        modifierFlags:(NSEventModifierFlags)flags
{
  RCTAssertMainThread();

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
  RCTAssertMainThread();

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

- (void)registerKeyCommandWithInput:(NSString *)input
                      modifierFlags:(UIKeyModifierFlags)flags
                             action:(void (^)(UIKeyCommand *))block {}

- (void)unregisterKeyCommandWithInput:(NSString *)input
                        modifierFlags:(UIKeyModifierFlags)flags {}

- (BOOL)isKeyCommandRegisteredForInput:(NSString *)input
                         modifierFlags:(UIKeyModifierFlags)flags
{
  return NO;
}

@end

#endif
