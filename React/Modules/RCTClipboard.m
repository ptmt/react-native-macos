/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTClipboard.h"
#import <AppKit/AppKit.h>

@implementation RCTClipboard

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}


RCT_EXPORT_METHOD(setString:(NSString *)content)
{
  NSPasteboard *clipboard = [NSPasteboard generalPasteboard];
  [clipboard clearContents];
  [clipboard writeObjects:[NSArray arrayWithObject:content]];
}

RCT_EXPORT_METHOD(getString:(RCTPromiseResolveBlock)resolve
                  rejecter:(__unused RCTPromiseRejectBlock)reject)
{
  NSPasteboard *clipboard = [NSPasteboard generalPasteboard];
  resolve(@[RCTNullIfNil([clipboard  stringForType:NSPasteboardTypeString])]);
}

@end
