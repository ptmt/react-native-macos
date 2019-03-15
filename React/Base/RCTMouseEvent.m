/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTMouseEvent.h"

#import "RCTAssert.h"

@implementation RCTMouseEvent
{
  NSDictionary *_userInfo;
  uint16_t _coalescingKey;
}

@synthesize eventName = _eventName;
@synthesize viewTag = _viewTag;

- (instancetype)initWithEventName:(NSString *)eventName
                           target:(NSNumber *)target
                         userInfo:(NSDictionary *)userInfo
                    coalescingKey:(uint16_t)coalescingKey
{
  if (self = [super init]) {
    _viewTag = target;
    _userInfo = [NSDictionary dictionaryWithDictionary:userInfo];
    _eventName = eventName;
    _coalescingKey = coalescingKey;
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)init)

#pragma mark - RCTEvent

- (BOOL)canCoalesce
{
  return [_eventName isEqual:@"mouseMove"];
}

// We coalesce only move events, while holding some assumptions that seem reasonable but there are no explicit guarantees about them.
- (id<RCTEvent>)coalesceWithEvent:(id<RCTEvent>)newEvent
{
  RCTAssert([newEvent isKindOfClass:[RCTMouseEvent class]], @"Mouse event cannot be coalesced with any other type of event, such as provided %@", newEvent);
  return ((RCTMouseEvent *)newEvent).timestamp > self.timestamp ? newEvent : self;
}

+ (NSString *)moduleDotMethod
{
  return @"RCTEventEmitter.receiveEvent";
}

- (NSArray *)arguments
{
  return @[_viewTag, RCTNormalizeInputEventName(_eventName), _userInfo];
}

- (uint16_t)coalescingKey
{
  return _coalescingKey;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: %p; name = %@; coalescing key = %hu>", [self class], self, _eventName, _coalescingKey];
}

- (NSTimeInterval)timestamp
{
  return [_userInfo[@"timestamp"] doubleValue];
}

@end
