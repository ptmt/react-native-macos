//
//  AppDelegate.m
//  Neutrino
//
//  Created by Dmitriy Loktev on 9/26/15.
//  Copyright © 2015 Elephant. All rights reserved.
//

#import "AppDelegate.h"
#import <AppKit/AppKit.h>
#import "RCTRootView.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//
    NSRect contentSize = NSMakeRect(200, 500, 500, 500);
//
    self.window  = [[NSWindow alloc] initWithContentRect:contentSize
                                     styleMask:NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask
                                       backing:NSBackingStoreBuffered
                                         defer:NO];


    [self.window setRestorable:YES]; // TODO:
    [self.window setRestorationClass:_restorationClass];

    [self.window setTitle:@"Neutrino"];
    [self.window setFrame:contentSize display:YES];
    [self.window makeKeyAndOrderFront:nil];

    NSArray *  topLevelObjs = nil;
    [[NSBundle mainBundle] loadNibNamed:@"LoadingView" owner:self topLevelObjects:&topLevelObjs];
    NSView *loadingView = topLevelObjs[1];

//    NSViewController *rootViewController = [[NSViewController alloc] init];
//    [self.window setContentViewController:rootViewController];
//    // TODO: resize dynamically & add background
//    //[self.window setContentView:loadingView];
//    [rootViewController setView:loadingView];
//    [self.window setContentViewController:rootViewController];
//   // [self.window addSubview]

//
    NSURL *jsCodeLocation;

    jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/Examples/Neutrino/index.osx.bundle?platform=osx&dev=true"];

    //
    RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                        moduleName:@"Neutrino"
                                                 initialProperties:nil
                                                     launchOptions:nil];


 //   rootView.loadingView = loadingView;
//    NSViewController *rootViewController = [[NSViewController alloc] init];
//    rootViewController.view = rootView;

    [self.window setContentView:rootView];// = rootViewController;
   // [self playground];
}

-(void)playground
{
    NSView *view = [[NSView alloc] initWithFrame:self.window.frame];
    NSTextField * cell = [[NSTextField alloc] initWithFrame: CGRectMake(0, 0, view.frame.size.width, 100)];
    cell.textColor = [NSColor blackColor];
    cell.alignment = NSTextAlignmentCenter;
    cell.font = [NSFont boldSystemFontOfSize:16];
    cell.editable = false;
    [cell setStringValue:@"TODO 1"];
    [view addSubview:cell];

    NSTextField * cell1 = [[NSTextField alloc] initWithFrame: CGRectMake(0, 100, view.frame.size.width, 100)];
    cell1.textColor = [NSColor blackColor];
    cell1.alignment = NSTextAlignmentCenter;
    cell1.font = [NSFont boldSystemFontOfSize:16];
    cell1.editable = false;
    [cell1 setStringValue:@"TODO 2"];
    [view addSubview:cell1];

    const CGFloat buttonHeight = 60;

    NSButton *dismissButton = [[NSButton alloc] init];
    [dismissButton setBezelStyle:NSRecessedBezelStyle];
    dismissButton.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;
    dismissButton.accessibilityIdentifier = @"redbox-dismiss";
    dismissButton.font = [NSFont systemFontOfSize:20];
    [dismissButton setTitle:@"Dismiss (ESC)"];



    NSButton *reloadButton = [[NSButton alloc] init];
    [reloadButton setBezelStyle:NSRecessedBezelStyle];
    reloadButton.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;
    reloadButton.accessibilityIdentifier = @"redbox-reload";
    reloadButton.font = [NSFont systemFontOfSize:20];
    [reloadButton setTitle:@"Reload JS"];

    CGFloat buttonWidth = view.frame.size.width / 2;
    dismissButton.frame = CGRectMake(0, view.frame.size.height - buttonHeight, buttonWidth, buttonHeight);
    reloadButton.frame = CGRectMake(buttonWidth, view.frame.size.height - buttonHeight, buttonWidth, buttonHeight);
    [view addSubview:dismissButton];
    [view addSubview:reloadButton];


    [self.window setContentView:view];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
