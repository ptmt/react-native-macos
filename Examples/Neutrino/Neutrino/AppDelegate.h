//
//  AppDelegate.h
//  Neutrino
//
//  Created by Dmitriy Loktev on 9/26/15.
//  Copyright © 2015 Dmitriy Loktev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (strong, nonatomic) NSWindow *window;
@property(assign) Class<NSWindowRestoration> restorationClass;

@end

