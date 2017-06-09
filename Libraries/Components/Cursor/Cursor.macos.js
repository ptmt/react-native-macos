/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule Cursor
 * @flow
 */
'use strict';

const CursorManager = require('NativeModules').CursorManager;

// All cursor types:
type CursorType = $Enum<{
  arrow: string,
  IBeam: string,
  pointingHand: string,
  closedHand: string,
  openHand: string,
  resizeLeft: string,
  resizeRight: string,
  resizeLeftRight: string,
  resizeUp: string,
  resizeDown: string,
  resizeUpDown: string,
  crosshair: string,
  disappearing: string,
  operationNotAllowed: string,
  dragLink: string,
  dragCopy: string,
  contextualMenu: string,
  IBeamForVerticalLayout: string,
}>;

const cursorTypeMap = {
  arrow: 'arrowCursor',
  IBeam: 'IBeamCursor',
  pointingHand: 'pointingHandCursor',
  closedHand: 'closedHandCursor',
  openHand: 'openHandCursor',
  resizeLeft: 'resizeLeftCursor',
  resizeRight: 'resizeRightCursor',
  resizeLeftRight: 'resizeLeftRightCursor',
  resizeUp: 'resizeUpCursor',
  resizeDown: 'resizeDownCursor',
  resizeUpDown: 'resizeUpDownCursor',
  crosshair: 'crosshairCursor',
  disappearing: 'disappearingItemCursor',
  operationNotAllowed: 'operationNotAllowedCursor',
  dragLink: 'dragLinkCursor',
  dragCopy: 'dragCopyCursor',
  contextualMenu: 'contextualMenuCursor',
  IBeamForVerticalLayout: 'IBeamCursorForVerticalLayout',
};

/**
 * Let change cursor style
 * List of all cursor types:
 * https://developer.apple.com/reference/appkit/nscursor?language=objc
 *
 * // Usage
 * ```
 * Cursor.set('openHand');
 * ```
 */
class Cursor {
  static set(type: CursorType): void {
    if (!cursorTypeMap[type]) {
      console.warn(`${type} isn't supported cursor type`);
    } else {
      const nativeCursorType = cursorTypeMap[type];
      CursorManager[nativeCursorType]();
    }
  }
}

module.exports = Cursor;
