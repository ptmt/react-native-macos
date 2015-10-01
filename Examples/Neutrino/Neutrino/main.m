//
//  main.m
//  Neutrino
//
//  Created by Dmitriy Loktev on 9/26/15.
//  Copyright © 2015 Elephant. All rights reserved.
//

#import "AppDelegate.h"

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication * application = [NSApplication sharedApplication];
        AppDelegate * appDelegate = [[AppDelegate alloc] init];
        [application setDelegate:appDelegate];
        [application run];
        return EXIT_SUCCESS;
        //return NSApplicationMain(argc, argv);
    }

}
