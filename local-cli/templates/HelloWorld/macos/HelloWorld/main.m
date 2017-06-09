/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import "AppDelegate.h"

int main(int argc, char * argv[]) {
  @autoreleasepool {
    NSApplication * application = [NSApplication sharedApplication];
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Application"];
    [NSApp setMainMenu:mainMenu];
    AppDelegate * appDelegate = [[AppDelegate alloc] init];
    [application setDelegate:appDelegate];
    if (argc > 1) {
      NSMutableArray *argvArray = [[NSMutableArray alloc] init];
      for (int i = 1; i < argc; i++) {
        [argvArray addObject:[[NSString alloc] initWithUTF8String:argv[i]]];
      }
      [appDelegate setArgv:argvArray];
    } else {
      [appDelegate setArgv:[[NSArray alloc] init]];
    }

    [application run];
    return EXIT_SUCCESS;
  }
}
