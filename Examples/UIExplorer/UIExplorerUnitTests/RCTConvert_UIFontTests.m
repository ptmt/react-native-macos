/**
 * The examples provided by Facebook are for non-commercial testing and
 * evaluation purposes only.
 *
 * Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 * AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <XCTest/XCTest.h>

#import "RCTConvert.h"

@interface RCTConvert_NSFontTests : XCTestCase

@end

@implementation RCTConvert_NSFontTests

#define RCTAssertEqualFonts(font1, font2) { \
  XCTAssertEqualObjects(font1, font2); \
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
  {
    NSFont *expected = [NSFont fontWithName:@"Cochin" size:14];
    NSFont *result = [RCTConvert NSFont:@{@"fontFamily": @"Cochin"}];
    RCTAssertEqualFonts(expected, result);
  }
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
