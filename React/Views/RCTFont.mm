/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTFont.h"
#import "RCTLog.h"

#import <CoreText/CoreText.h>

#import <mutex>

#define NSFontWeightUltraLight -0.8
#define NSFontWeightThin -0.6
#define NSFontWeightLight -0.4
#define NSFontWeightRegular 0
#define NSFontWeightMedium 0.23
#define NSFontWeightSemibold 0.3
#define NSFontWeightBold 0.4
#define NSFontWeightHeavy 0.56
#define NSFontWeightBlack 0.62

typedef CGFloat RCTFontWeight;
static RCTFontWeight weightOfFont(NSFont *font)
{
  static NSDictionary *nameToWeight;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nameToWeight = @{
       @"normal": @(NSFontWeightRegular),
       @"bold": @(NSFontWeightBold),
       @"ultralight": @(NSFontWeightUltraLight),
       @"thin": @(NSFontWeightThin),
       @"light": @(NSFontWeightLight),
       @"regular": @(NSFontWeightRegular),
       @"medium": @(NSFontWeightMedium),
       @"semibold": @(NSFontWeightSemibold),
       @"bold": @(NSFontWeightBold),
       @"heavy": @(NSFontWeightHeavy),
       @"black": @(NSFontWeightBlack),
    };
  });

  NSDictionary *traits = [font.fontDescriptor objectForKey:NSFontTraitsAttribute];
  RCTFontWeight weight = [traits[NSFontWeightTrait] doubleValue];
  if (weight == 0.0) {
    for (NSString *name in nameToWeight) {
      if ([font.fontName.lowercaseString hasSuffix:name]) {
        return [nameToWeight[name] doubleValue];
      }
    }
  }
  return weight;
}

static BOOL isItalicFont(NSFont *font)
{
  NSDictionary *traits = [font.fontDescriptor objectForKey:NSFontTraitsAttribute];
  NSFontSymbolicTraits symbolicTraits = [traits[NSFontSymbolicTrait] unsignedIntValue];
  return (symbolicTraits & NSFontItalicTrait) != 0;
}

static BOOL isCondensedFont(NSFont *font)
{
  NSDictionary *traits = [font.fontDescriptor objectForKey:NSFontTraitsAttribute];
  NSFontSymbolicTraits symbolicTraits = [traits[NSFontSymbolicTrait] unsignedIntValue];
  return (symbolicTraits & NSFontCondensedTrait) != 0;
}

static NSFont *cachedSystemFont(CGFloat size, RCTFontWeight weight)
{
  static NSCache *fontCache;
  static std::mutex fontCacheMutex;

  NSString *cacheKey = [NSString stringWithFormat:@"%.1f/%.2f", size, weight];
  NSFont *font;
  {
    std::lock_guard<std::mutex> lock(fontCacheMutex);
    if (!fontCache) {
      fontCache = [NSCache new];
    }
    font = [fontCache objectForKey:cacheKey];
  }

  if (!font) {
    // Only supported on iOS8.2 and above
    if ([NSFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
      font = [NSFont systemFontOfSize:size weight:weight];
    } else {
      if (weight >= NSFontWeightBold) {
        font = [NSFont boldSystemFontOfSize:size];
      } else if (weight >= NSFontWeightMedium) {
        font = [NSFont fontWithName:@"HelveticaNeue-Medium" size:size];
      } else if (weight <= NSFontWeightLight) {
        font = [NSFont fontWithName:@"HelveticaNeue-Light" size:size];
      } else {
        font = [NSFont systemFontOfSize:size];
      }
    }

    {
      std::lock_guard<std::mutex> lock(fontCacheMutex);
      [fontCache setObject:font forKey:cacheKey];
    }
  }

  return font;
}

@implementation RCTConvert (RCTFont)

+ (NSFont *)NSFont:(id)json
{
  json = [self NSDictionary:json];
  return [RCTFont updateFont:nil
                  withFamily:[RCTConvert NSString:json[@"fontFamily"]]
                        size:[RCTConvert NSNumber:json[@"fontSize"]]
                      weight:[RCTConvert NSString:json[@"fontWeight"]]
                       style:[RCTConvert NSString:json[@"fontStyle"]]
                     variant:[RCTConvert NSStringArray:json[@"fontVariant"]]
             scaleMultiplier:1];
}

RCT_ENUM_CONVERTER(RCTFontWeight, (@{
                                     @"normal": @(NSFontWeightRegular),
                                     @"bold": @(NSFontWeightBold),
                                     @"100": @(NSFontWeightUltraLight),
                                     @"200": @(NSFontWeightThin),
                                     @"300": @(NSFontWeightLight),
                                     @"400": @(NSFontWeightRegular),
                                     @"500": @(NSFontWeightMedium),
                                     @"600": @(NSFontWeightSemibold),
                                     @"700": @(NSFontWeightBold),
                                     @"800": @(NSFontWeightHeavy),
                                     @"900": @(NSFontWeightBlack),
                                     }), NSFontWeightRegular, doubleValue)

typedef BOOL RCTFontStyle;
RCT_ENUM_CONVERTER(RCTFontStyle, (@{
                                    @"normal": @NO,
                                    @"italic": @YES,
                                    @"oblique": @YES,
                                    }), NO, boolValue)

typedef NSDictionary RCTFontVariantDescriptor;
+ (RCTFontVariantDescriptor *)RCTFontVariantDescriptor:(id)json
{
  static NSDictionary *mapping;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mapping = @{
      @"small-caps": @{
          NSFontFeatureTypeIdentifierKey: @(kLowerCaseType),
          NSFontFeatureSelectorIdentifierKey: @(kLowerCaseSmallCapsSelector),
          },
      @"oldstyle-nums": @{
          NSFontFeatureTypeIdentifierKey: @(kNumberCaseType),
          NSFontFeatureSelectorIdentifierKey: @(kLowerCaseNumbersSelector),
          },
      @"lining-nums": @{
          NSFontFeatureTypeIdentifierKey: @(kNumberCaseType),
          NSFontFeatureSelectorIdentifierKey: @(kUpperCaseNumbersSelector),
          },
      @"tabular-nums": @{
          NSFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
          NSFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector),
          },
      @"proportional-nums": @{
          NSFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
          NSFontFeatureSelectorIdentifierKey: @(kProportionalNumbersSelector),
          },
      };
  });
  RCTFontVariantDescriptor *value = mapping[json];
  if (RCT_DEBUG && !value && [json description].length > 0) {
    RCTLogError(@"Invalid RCTFontVariantDescriptor '%@'. should be one of: %@", json,
                [[mapping allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]);
  }
  return value;
}

RCT_ARRAY_CONVERTER(RCTFontVariantDescriptor)

@end

@implementation RCTFont

+ (NSFont *)updateFont:(NSFont *)font
            withFamily:(NSString *)family
                  size:(NSNumber *)size
                weight:(NSString *)weight
                 style:(NSString *)style
               variant:(NSArray<RCTFontVariantDescriptor *> *)variant
       scaleMultiplier:(CGFloat)scaleMultiplier
{
  // Defaults
  static NSString *defaultFontFamily;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultFontFamily = [NSFont systemFontOfSize:14].familyName;
  });
  const RCTFontWeight defaultFontWeight = NSFontWeightRegular;
  const CGFloat defaultFontSize = 14;

  // Initialize properties to defaults
  CGFloat fontSize = defaultFontSize;
  RCTFontWeight fontWeight = defaultFontWeight;
  NSString *familyName = defaultFontFamily;
  BOOL isItalic = NO;
  BOOL isCondensed = NO;

  if (font) {
    familyName = font.familyName ?: defaultFontFamily;
    fontSize = font.pointSize ?: defaultFontSize;
    fontWeight = weightOfFont(font);
    isItalic = isItalicFont(font);
    isCondensed = isCondensedFont(font);
  }

  // Get font attributes
  fontSize = [RCTConvert CGFloat:size] ?: fontSize;
  if (scaleMultiplier > 0.0 && scaleMultiplier != 1.0) {
    fontSize = round(fontSize * scaleMultiplier);
  }
  familyName = [RCTConvert NSString:family] ?: familyName;
  isItalic = style ? [RCTConvert RCTFontStyle:style] : isItalic;
  fontWeight = weight ? [RCTConvert RCTFontWeight:weight] : fontWeight;

  BOOL didFindFont = NO;

  // Handle system font as special case. This ensures that we preserve
  // the specific metrics of the standard system font as closely as possible.
  if ([familyName isEqual:defaultFontFamily] || [familyName isEqualToString:@"System"]) {
    font = cachedSystemFont(fontSize, fontWeight);
    if (font) {
      didFindFont = YES;

      if (isItalic || isCondensed) {
        NSFontDescriptor *fontDescriptor = [font fontDescriptor];
        NSFontSymbolicTraits symbolicTraits = fontDescriptor.symbolicTraits;
        if (isItalic) {
          symbolicTraits |= NSFontItalicTrait;
        }
        if (isCondensed) {
          symbolicTraits |= NSFontCondensedTrait;
        }
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
        font = [NSFont fontWithDescriptor:fontDescriptor size:fontSize];
      }
    }
  }

  // Gracefully handle being given a font name rather than font family, for
  // example: "Helvetica Light Oblique" rather than just "Helvetica".
  if (!didFindFont &&
      [[NSFontManager sharedFontManager] availableMembersOfFontFamily:familyName].count == 0) {
    font = [NSFont fontWithName:familyName size:fontSize];
    if (font) {
      // It's actually a font name, not a font family name,
      // but we'll do what was meant, not what was said.
      familyName = font.familyName;
      fontWeight = weight ? fontWeight : weightOfFont(font);
      isItalic = style ? isItalic : isItalicFont(font);
      isCondensed = isCondensedFont(font);
    } else {
      // Not a valid font or family
      RCTLogError(@"Unrecognized font family '%@'", familyName);
      if ([NSFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
        font = [NSFont systemFontOfSize:fontSize weight:fontWeight];
      } else if (fontWeight > NSFontWeightRegular) {
        font = [NSFont boldSystemFontOfSize:fontSize];
      } else {
        font = [NSFont systemFontOfSize:fontSize];
      }
    }
  }

  // Get the closest font that matches the given weight for the fontFamily
  CGFloat closestWeight = INFINITY;
  for (NSArray *fontFamily in [[NSFontManager sharedFontManager] availableMembersOfFontFamily:familyName]) {
    NSString *name = fontFamily[0];
    NSFont *match = [NSFont fontWithName:name size:fontSize];
    if (isItalic == isItalicFont(match) &&
        isCondensed == isCondensedFont(match)) {
      CGFloat testWeight = weightOfFont(match);
      if (ABS(testWeight - fontWeight) < ABS(closestWeight - fontWeight)) {
        font = match;
        closestWeight = testWeight;
      }
    }
  }

  // If we still don't have a match at least return the first font in the fontFamily
  // This is to support built-in font Zapfino and other custom single font families like Impact
  if (!font) {
    NSArray *names = [[NSFontManager sharedFontManager] availableMembersOfFontFamily:familyName];
    if (names.count > 0) {
      font = [NSFont fontWithName:names[0] size:fontSize];
    }
  }

  // Apply font variants to font object
  if (variant) {
    NSArray *fontFeatures = [RCTConvert RCTFontVariantDescriptorArray:variant];
    NSFontDescriptor *fontDescriptor = [font.fontDescriptor
                                        fontDescriptorByAddingAttributes:@{
      NSFontFeatureSettingsAttribute: fontFeatures
    }];
    font = [NSFont fontWithDescriptor:fontDescriptor size:fontSize];
  }

  return font;
}

+ (NSFont *)updateFont:(NSFont *)font withFamily:(NSString *)family
{
  return [self updateFont:font withFamily:family size:nil weight:nil style:nil variant:nil scaleMultiplier:1];
}

+ (NSFont *)updateFont:(NSFont *)font withSize:(NSNumber *)size
{
  return [self updateFont:font withFamily:nil size:size weight:nil style:nil variant:nil scaleMultiplier:1];
}

+ (NSFont *)updateFont:(NSFont *)font withWeight:(NSString *)weight
{
  return [self updateFont:font withFamily:nil size:nil weight:weight style:nil variant:nil scaleMultiplier:1];
}

+ (NSFont *)updateFont:(NSFont *)font withStyle:(NSString *)style
{
  return [self updateFont:font withFamily:nil size:nil weight:nil style:style variant:nil scaleMultiplier:1];
}

@end
