/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <React/RCTConvert.h>

typedef NS_ENUM(NSInteger, RCTResizeMode) {
  RCTResizeModeContain = 0,
  RCTResizeModeCover = 1,
  RCTResizeModeStretch = 2,
  RCTResizeModeCenter = 3,
  RCTResizeModeRepeat = -1,
};

@interface RCTConvert(RCTResizeMode)

+ (RCTResizeMode)RCTResizeMode:(id)json;

@end
