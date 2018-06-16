/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <Cocoa/Cocoa.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

@implementation AppDelegate

-(id)init
{
  if(self = [super init]) {
    NSRect contentSize = NSMakeRect(200, 500, 1000, 500); // initial size of main NSWindow

    self.window = [[NSWindow alloc] initWithContentRect:contentSize
                                             styleMask:
                                                NSWindowStyleMaskTitled |
                                                NSWindowStyleMaskResizable |
                                                NSWindowStyleMaskFullSizeContentView |
                                                NSWindowStyleMaskMiniaturizable |
                                                NSWindowStyleMaskClosable
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];

    NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:self.window];

    [[self window] setTitleVisibility:NSWindowTitleHidden];
    [[self window] setTitlebarAppearsTransparent:YES];
    
    [windowController setShouldCascadeWindows:NO];
    [windowController setWindowFrameAutosaveName:@"HelloWorld"];

    [windowController showWindow:self.window];

    [self setUpApplicationMenu];
  }
  return self;
}


- (void)applicationDidFinishLaunching:(__unused NSNotification *)aNotification
{
  NSURL *jsCodeLocation;

  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.macos" fallbackResource:nil];

  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"HelloWorld"
                                               initialProperties:nil
                                                   launchOptions:@{@"argv": [self argv]}];
  // try NSVisualEffectMaterialDark or NSVisualEffectMaterialMediumLight
  rootView.material = NSVisualEffectMaterialAppearanceBased;
  [self.window setContentView:rootView];
}

- (void)setUpApplicationMenu
{
  NSMenuItem *containerItem = [[NSMenuItem alloc] init];
  NSMenu *rootMenu = [[NSMenu alloc] initWithTitle:@"" ];
  [containerItem setSubmenu:rootMenu];
  [rootMenu addItemWithTitle:@"Quit HelloWorld" action:@selector(terminate:) keyEquivalent:@"q"];
  [[NSApp mainMenu] addItem:containerItem];
}

@end
