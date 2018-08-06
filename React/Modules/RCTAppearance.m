#import "RCTAppearance.h"

@implementation RCTAppearance

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
  [NSApp addObserver:self
          forKeyPath:@"effectiveAppearance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

}

- (void)observeValueForKeyPath:(__unused NSString *)keyPath
                      ofObject:(__unused id)object
                        change:(__unused NSDictionary *)change
                       context:(__unused void *)context {
  [NSAppearance setCurrentAppearance:[NSApp mainWindow].effectiveAppearance];
  [self sendEventWithName:@"onAppearanceChange" body:[self resolveConstants]];
}

- (void)stopObserving
{
  [NSApp removeObserver:self forKeyPath:@"effectiveAppearance"];
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}


- (NSDictionary<NSString *, id> *)resolveConstants
{
  return @{
           @"currentAppearance": [NSAppearance currentAppearance].name,
           @"colors": @{
               @"textColor": [self rgba:[NSColor textColor]],
               @"textBackgroundColor": [self rgba:[NSColor textBackgroundColor]],
               @"controlShadowColor": [self rgba:[NSColor controlShadowColor]],
               @"controlDarkShadowColor": [self rgba:[NSColor controlDarkShadowColor]],
               @"controlColor": [self rgba:[NSColor controlColor]],
               @"controlHighlightColor": [self rgba:[NSColor controlHighlightColor]],
               @"controlLightHighlightColor": [self rgba:[NSColor controlLightHighlightColor]],
               @"controlBackgroundColor": [self rgba:[NSColor controlBackgroundColor]],
               @"selectedControlTextColor": [self rgba:[NSColor selectedControlTextColor]],
               @"disabledControlTextColor": [self rgba:[NSColor disabledControlTextColor]],
               @"selectedTextColor": [self rgba:[NSColor selectedTextColor]],
               @"selectedTextBackgroundColor": [self rgba:[NSColor selectedTextBackgroundColor]],
               @"gridColor": [self rgba:[NSColor gridColor]],
               @"keyboardFocusIndicatorColor": [self rgba:[NSColor keyboardFocusIndicatorColor]],
               @"windowBackgroundColor": [self rgba:[NSColor windowBackgroundColor]],
               @"underPageBackgroundColor": [self rgba:[NSColor underPageBackgroundColor]],
               @"labelColor": [self rgba:[NSColor labelColor]],
               @"secondaryLabelColor": [self rgba:[NSColor secondaryLabelColor]],
               @"tertiaryLabelColor": [self rgba:[NSColor tertiaryLabelColor]],
               @"quaternaryLabelColor": [self rgba:[NSColor quaternaryLabelColor]],
               @"scrollBarColor": [self rgba:[NSColor scrollBarColor]],
               @"knobColor": [self rgba:[NSColor knobColor]],
               @"selectedKnobColor": [self rgba:[NSColor selectedKnobColor]],
               @"windowFrameColor": [self rgba:[NSColor windowFrameColor]],
               @"windowFrameTextColor": [self rgba:[NSColor windowFrameTextColor]],
               @"selectedMenuItemColor": [self rgba:[NSColor selectedMenuItemColor]],
               @"highlightColor": [self rgba:[NSColor highlightColor]],
               @"shadowColor": [self rgba:[NSColor shadowColor]],
               @"headerColor": [self rgba:[NSColor headerColor]],
               
               @"selectedMenuItemColor": [self rgba:[NSColor selectedMenuItemColor]],
               @"highlightColor": [self rgba:[NSColor highlightColor]],
               @"shadowColor": [self rgba:[NSColor shadowColor]],
               @"headerColor": [self rgba:[NSColor headerColor]],
               @"selectedMenuItemColor": [self rgba:[NSColor selectedMenuItemColor]],
               @"highlightColor": [self rgba:[NSColor highlightColor]],
               @"shadowColor": [self rgba:[NSColor shadowColor]],
               @"headerColor": [self rgba:[NSColor headerColor]],
               @"headerTextColor": [self rgba:[NSColor headerTextColor]],
               @"alternateSelectedControlColor": [self rgba:[NSColor alternateSelectedControlColor]],
               @"alternateSelectedControlTextColor": [self rgba:[NSColor alternateSelectedControlTextColor]],
               @"headerColor": [self rgba:[NSColor headerColor]],
               
               @"systemRedColor": [self rgba:[NSColor systemRedColor]],
               @"systemGreenColor": [self rgba:[NSColor systemGreenColor]],
               @"systemBlueColor": [self rgba:[NSColor systemBlueColor]],
               @"systemOrangeColor": [self rgba:[NSColor systemOrangeColor]],
               @"systemBrownColor": [self rgba:[NSColor systemBrownColor]],
               @"systemPinkColor": [self rgba:[NSColor systemPinkColor]],
               @"systemPurpleColor": [self rgba:[NSColor systemPurpleColor]],
               @"systemGrayColor": [self rgba:[NSColor systemGrayColor]]
               }
           };
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  return [self resolveConstants];
}

- (NSString *)rgba:(NSColor *)color
{
  NSColor *convertedColor=[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  return [NSString stringWithFormat:@"rgba(%f, %f, %f, %f)", convertedColor.redComponent * 255.99999f,
      convertedColor.greenComponent * 255.99999f,
      convertedColor.blueComponent * 255.99999f,
      convertedColor.alphaComponent];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onAppearanceChange"];
}

RCT_EXPORT_METHOD(highlightWithLevel:(NSColor *)color
                  level:(NSNumber * _Nonnull)level
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  resolve([self rgba:[color highlightWithLevel:level.doubleValue]]);
}

RCT_EXPORT_METHOD(shadowWithLevel:(NSColor *)color
                  level:(NSNumber * _Nonnull)level
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  resolve([self rgba:[color shadowWithLevel:level.doubleValue]]);
}

@end
