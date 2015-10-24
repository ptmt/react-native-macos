//
//  main.m
//  SimpleGmailClient
//
//  Created by Dmitriy Loktev on 10/21/15.
//  Copyright © 2015 Elephant. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        NSApplication * application = [NSApplication sharedApplication];
        NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Application"];
        [NSApp setMainMenu:mainMenu];
        AppDelegate * appDelegate = [[AppDelegate alloc] init];
        [application setDelegate:appDelegate];
        [application run];
        return EXIT_SUCCESS;
    }
}