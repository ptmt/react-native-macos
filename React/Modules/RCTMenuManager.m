#include "RCTMenuManager.h"
#include "Cocoa/Cocoa.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

@implementation MenuManager {
  BOOL toRefresh;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

 - (instancetype)init
 {
   if (self = [super init]) {
     toRefresh = NO;
   }
   return self;
 }

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;
  toRefresh = YES;
}

-(NSMenu *)ensureSubmenu:(NSString *)title
 {
   if ([[NSApp mainMenu] indexOfItemWithTitle:title] > -1) {
     if (toRefresh) {
       [[NSApp mainMenu] removeItemAtIndex:[[NSApp mainMenu] indexOfItemWithTitle:title]];
     } else {
       return [[NSApp mainMenu] itemWithTitle:title].submenu;
     }
   }
   NSMenuItem *itemContainer = [[NSMenuItem alloc] init];
   itemContainer.title = title;
   NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
   [itemContainer setSubmenu:menu];
   [[NSApp mainMenu] addItem:itemContainer];
   toRefresh = NO;
   return menu;
 }

-(void)callback:(id)sender
{
  NSMenuItem *item = (NSMenuItem *)sender;
  if (item.keyEquivalent) {
    NSString *keyPrefix = @"onKeyPressed_";

    [_bridge.eventDispatcher
     sendDeviceEventWithName:[keyPrefix stringByAppendingString:item.keyEquivalent]
     body:@{}];
  }
  NSString *prefix = @"onTitlePressed";

  [_bridge.eventDispatcher
   sendDeviceEventWithName:[prefix stringByAppendingString:item.title]
   body:@{}];

}

RCT_EXPORT_METHOD(addItemToSubmenu:(NSString *)title
                  item:(NSDictionary *)item
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{

  if (!item || ![item valueForKey:@"title"]) {
    reject(@"Item requires title, key and callback", nil, nil);
  }

  NSMenu *menu = [self ensureSubmenu:title];
  if ([menu indexOfItemWithTitle:item[@"title"]] == -1) {
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];

    menuItem.title = item[@"title"];
    if ([item valueForKey:@"key"]) {
       menuItem.keyEquivalent = item[@"key"];
    }

    if ([item valueForKey:@"firstResponder"]) {
      menuItem.action = NSSelectorFromString([item valueForKey:@"firstResponder"]);
      [menuItem setTarget:nil];
    } else {
      menuItem.action = @selector(callback:);
      [menuItem setTarget:self];

    }
       [menu addItem:menuItem];
    if ([item valueForKey:@"separator"]) {
      [menu addItem:[NSMenuItem separatorItem]];
    }
    resolve(@[]);
  }
}


@end
