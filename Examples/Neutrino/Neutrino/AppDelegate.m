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
#import "RCTView.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//
    NSRect contentSize = NSMakeRect(200, 500, 500, 500);
//
    self.window  = [[NSWindow alloc] initWithContentRect:contentSize
                                     styleMask:NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask
                                       backing:NSBackingStoreBuffered
                                         defer:NO];


    [self.window setTitle:@"Neutrino"];
    [self.window setFrame:contentSize display:YES];
    [self.window makeKeyAndOrderFront:nil];

    NSArray *  topLevelObjs = nil;
    [[NSBundle mainBundle] loadNibNamed:@"LoadingView" owner:self topLevelObjects:&topLevelObjs];
    NSView *loadingView = topLevelObjs[1];

    NSURL *jsCodeLocation;
    jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/Examples/Neutrino/index.osx.bundle?platform=osx&dev=true"];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                        moduleName:@"Neutrino"
                                                 initialProperties:nil
                                                     launchOptions:nil];


  //  rootView.loadingView = loadingView;
//    NSViewController *rootViewController = [[NSViewController alloc] init];
//    rootViewController.view = rootView;
//    [self.window setContentViewController:rootViewController];

    [self.window setContentView:rootView];// = rootViewController;

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
