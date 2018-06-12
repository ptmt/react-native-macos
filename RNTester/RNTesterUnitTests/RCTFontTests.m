/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <CoreText/CoreText.h>
#import <XCTest/XCTest.h>

#import <React/RCTFont.h>

@interface RCTFontTests : XCTestCase

@end

@implementation RCTFontTests

// It can happen (particularly in tvOS simulator) that expected and result font objects
// will be different objects, but the same font, so this macro now explicitly
// checks that fontName (which includes the style) and pointSize are equal.
#define RCTAssertEqualFonts(font1, font2) { \
  XCTAssertTrue([font1.fontName isEqualToString:font2.fontName]); \
  XCTAssertEqual(font1.pointSize,font2.pointSize); \
}

- (void)testWeight
{
  {
    NSFont *expected = [NSFont systemFontOfSize:14 weight:NSFontWeightBold];
    NSFont *result = [RCTConvert NSFont:@{@"fontWeight": @"bold"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    NSFont *result = [RCTConvert NSFont:@{@"fontWeight": @"500"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont systemFontOfSize:14 weight:NSFontWeightUltraLight];
    NSFont *result = [RCTConvert NSFont:@{@"fontWeight": @"100"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont systemFontOfSize:14 weight:NSFontWeightRegular];
    NSFont *result = [RCTConvert NSFont:@{@"fontWeight": @"normal"}];
    RCTAssertEqualFonts(expected, result);
  }
}

- (void)testSize
{
  {
    NSFont *expected = [NSFont systemFontOfSize:18.5];
    NSFont *result = [RCTConvert NSFont:@{@"fontSize": @18.5}];
    RCTAssertEqualFonts(expected, result);
  }
}

- (void)testFamily
{
#if !TARGET_OS_TV
  {
    NSFont *expected = [NSFont fontWithName:@"Cochin" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"Cochin"}];
    RCTAssertEqualFonts(expected, result);
  }
#endif
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"Helvetica Neue"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue-Italic" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"HelveticaNeue-Italic"}];
    RCTAssertEqualFonts(expected, result);
  }
}

- (void)testStyle
{
  {
    NSFont *font = [NSFont systemFontOfSize:14];
    NSFontDescriptor *fontDescriptor = [font fontDescriptor];
    NSFontSymbolicTraits symbolicTraits = fontDescriptor.symbolicTraits;
    symbolicTraits |= NSFontItalicTrait;
    fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
    NSFont *expected = [NSFont fontWithDescriptor:fontDescriptor size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontStyle": @"italic"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont systemFontOfSize:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontStyle": @"normal"}];
    RCTAssertEqualFonts(expected, result);
  }
}

- (void)testStyleAndWeight
{
  {
    NSFont *font = [NSFont systemFontOfSize:14 weight:NSFontWeightUltraLight];
    NSFontDescriptor *fontDescriptor = [font fontDescriptor];
    NSFontSymbolicTraits symbolicTraits = fontDescriptor.symbolicTraits;
    symbolicTraits |= NSFontItalicTrait;
    fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
    NSFont *expected = [NSFont fontWithDescriptor:fontDescriptor size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontStyle": @"italic", @"fontWeight": @"100"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *font = [NSFont systemFontOfSize:14 weight:NSFontWeightBold];
    NSFontDescriptor *fontDescriptor = [font fontDescriptor];
    NSFontSymbolicTraits symbolicTraits = fontDescriptor.symbolicTraits;
    symbolicTraits |= NSFontItalicTrait;
    fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
    NSFont *expected = [NSFont fontWithDescriptor:fontDescriptor size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontStyle": @"italic", @"fontWeight": @"bold"}];
    RCTAssertEqualFonts(expected, result);
  }
}

- (void)testFamilyAndWeight
{
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue-Bold" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"Helvetica Neue", @"fontWeight": @"bold"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"HelveticaNeue-Bold", @"fontWeight": @"normal"}];
    RCTAssertEqualFonts(expected, result);
  }
#if !TARGET_OS_TV
  {
    NSFont *expected = [NSFont fontWithName:@"Cochin-Bold" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"Cochin", @"fontWeight": @"700"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont fontWithName:@"Cochin" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"Cochin", @"fontWeight": @"100"}];
    RCTAssertEqualFonts(expected, result);
  }
#endif
}

- (void)testFamilyAndStyle
{
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue-Italic" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"Helvetica Neue", @"fontStyle": @"italic"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"HelveticaNeue-Italic", @"fontStyle": @"normal"}];
    RCTAssertEqualFonts(expected, result);
  }
}

- (void)testFamilyStyleAndWeight
{
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue-LightItalic" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"Helvetica Neue", @"fontStyle": @"italic", @"fontWeight": @"300"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue-Bold" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"HelveticaNeue-Italic", @"fontStyle": @"normal", @"fontWeight": @"bold"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont fontWithName:@"HelveticaNeue" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"HelveticaNeue-Italic", @"fontStyle": @"normal", @"fontWeight": @"normal"}];
    RCTAssertEqualFonts(expected, result);
  }
}

- (void)testVariant
{
  {
    NSFont *expected = [NSFont monospacedDigitSystemFontOfSize:14 weight:NSFontWeightRegular];
    NSFont *result = [RCTConvert NSFont:@{@"fontVariant": @[@"tabular-nums"]}];
    // RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *monospaceFont = [NSFont monospacedDigitSystemFontOfSize:14 weight:NSFontWeightRegular];
    NSFontDescriptor *fontDescriptor = [monospaceFont.fontDescriptor fontDescriptorByAddingAttributes:@{
      NSFontFeatureSettingsAttribute: @[@{
        NSFontFeatureTypeIdentifierKey: @(kLowerCaseType),
        NSFontFeatureSelectorIdentifierKey: @(kLowerCaseSmallCapsSelector),
      }]
    }];
    NSFont *expected = [NSFont fontWithDescriptor:fontDescriptor size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontVariant": @[@"tabular-nums", @"small-caps"]}];
    // RCTAssertEqualFonts(expected, result);
  }
}

- (void)testInvalidFont
{
  {
    NSFont *expected = [NSFont systemFontOfSize:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"foobar"}];
    RCTAssertEqualFonts(expected, result);
  }
  {
    NSFont *expected = [NSFont systemFontOfSize:14 weight:NSFontWeightBold];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"foobar", @"fontWeight": @"bold"}];
    RCTAssertEqualFonts(expected, result);
  }
}

@end
