/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTFieldEditor.h"

@implementation RCTFieldEditor

@dynamic delegate;

- (instancetype)init
{
  if (self = [super init]) {
    self.fieldEditor = YES;
  }
  return self;
}

- (void)paste:(id)sender
{
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  NSString *text = [pasteboard stringForType:NSPasteboardTypeString];

  if (text && [self.delegate respondsToSelector:@selector(fieldEditor:didPaste:)]) {
    [self.delegate fieldEditor:self didPaste:text];
  }

  [super paste:sender];
}

- (void)keyDown:(NSEvent *)event
{
  [super keyDown:event];

  if (event.keyCode == 36 && [self.delegate respondsToSelector:@selector(fieldEditorDidReturn:)]) {
    [self.delegate fieldEditorDidReturn:self];
  }
}

@end
