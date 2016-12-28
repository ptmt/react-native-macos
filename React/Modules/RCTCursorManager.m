/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTCursorManager.h"

// Macros for creation set methods for provided cursor type
#define EXPORT_CURSOR_SET_METHOD(name) \
  RCT_EXPORT_METHOD(name) {            \
    [[NSCursor name] set];             \
  }


@implementation RCTCursorManager

RCT_EXPORT_MODULE();

EXPORT_CURSOR_SET_METHOD(arrowCursor);
EXPORT_CURSOR_SET_METHOD(IBeamCursor);
EXPORT_CURSOR_SET_METHOD(crosshairCursor);
EXPORT_CURSOR_SET_METHOD(closedHandCursor);
EXPORT_CURSOR_SET_METHOD(openHandCursor);
EXPORT_CURSOR_SET_METHOD(pointingHandCursor);
EXPORT_CURSOR_SET_METHOD(resizeLeftCursor);
EXPORT_CURSOR_SET_METHOD(resizeRightCursor);
EXPORT_CURSOR_SET_METHOD(resizeLeftRightCursor);
EXPORT_CURSOR_SET_METHOD(resizeUpCursor);
EXPORT_CURSOR_SET_METHOD(resizeDownCursor);
EXPORT_CURSOR_SET_METHOD(resizeUpDownCursor);
EXPORT_CURSOR_SET_METHOD(disappearingItemCursor);
EXPORT_CURSOR_SET_METHOD(IBeamCursorForVerticalLayout);
EXPORT_CURSOR_SET_METHOD(operationNotAllowedCursor);
EXPORT_CURSOR_SET_METHOD(dragLinkCursor);
EXPORT_CURSOR_SET_METHOD(dragCopyCursor);
EXPORT_CURSOR_SET_METHOD(contextualMenuCursor);

@end
