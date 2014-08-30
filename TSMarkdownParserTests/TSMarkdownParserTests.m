//
//  TSMarkdownParserTests.m
//  TSMarkdownParserTests
//
//  Created by Tobias Sundstrand on 14-08-30.
//  Copyright (c) 2014 Computertalk Sweden. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "TSMarkdownParser.h"

@interface TSMarkdownParserTests : XCTestCase

@end

@implementation TSMarkdownParserTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBasicBoldParsing {
    TSMarkdownParser *parser = [TSMarkdownParser new];
    NSError *error;
    NSRegularExpression *boldParsing = [NSRegularExpression regularExpressionWithPattern:@"\\*{2}.*\\*{2}" options:NSRegularExpressionCaseInsensitive error:&error];
    [parser addParsingRuleWithRegularExpression:boldParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {

        [attributedString addAttribute:NSFontAttributeName
                                 value:[UIFont boldSystemFontOfSize:12]
                                 range:match.range];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 2)];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location+match.range.length-4, 2)];

    }];

    NSAttributedString *attributedString = [parser attributedStringFromMarkdown:@"Hello\nMen att **Pär är här** men inte Pia"];
    XCTAssertEqualObjects([[attributedString attribute:NSFontAttributeName atIndex:16 effectiveRange:NULL] fontName], @".Helvetica NeueUI Bold");
    XCTAssertTrue([attributedString.string rangeOfString:@"*"].location == NSNotFound);
}

- (void)testBasicEmParsing {
    TSMarkdownParser *parser = [TSMarkdownParser new];
    NSError *error;
    NSRegularExpression *boldParsing = [NSRegularExpression regularExpressionWithPattern:@"\\*{1}.*\\*{1}" options:NSRegularExpressionCaseInsensitive error:&error];
    [parser addParsingRuleWithRegularExpression:boldParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {

        [attributedString addAttribute:NSFontAttributeName
                                 value:[UIFont italicSystemFontOfSize:12]
                                 range:match.range];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 1)];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location+match.range.length-2, 1)];

    }];

    NSAttributedString *attributedString = [parser attributedStringFromMarkdown:@"Hello\nMen att *Pär är här* men inte Pia"];
    XCTAssertEqualObjects([[attributedString attribute:NSFontAttributeName atIndex:16 effectiveRange:NULL] fontName], @".Helvetica NeueUI Italic");
    XCTAssertTrue([attributedString.string rangeOfString:@"*"].location == NSNotFound);
}

- (void)testStandardFont {
    TSMarkdownParser *parser = [TSMarkdownParser new];
    XCTAssertEqualObjects(parser.paragraphFont.fontName, @".Helvetica NeueUI");
}

- (void)testBoldFont {
    TSMarkdownParser *parser = [TSMarkdownParser new];
    XCTAssertEqualObjects(parser.boldFont.fontName, @".Helvetica NeueUI Bold");
}

- (void)testItalicFont {
    TSMarkdownParser *parser = [TSMarkdownParser new];
    XCTAssertEqualObjects(parser.italicFont.fontName, @".Helvetica NeueUI Italic");
}

- (void)testDefaultBoldParsing {
    NSAttributedString *attributedString = [[TSMarkdownParser defaultParser] attributedStringFromMarkdown:@"Hello\nMen att **Pär är här** men inte Pia"];
    XCTAssertEqualObjects([[attributedString attribute:NSFontAttributeName atIndex:16 effectiveRange:NULL] fontName], @".Helvetica NeueUI Bold");
    XCTAssertEqualObjects(attributedString.string, @"Hello\nMen att Pär är här men inte Pia");
}

- (void)testDefaultEmParsing {
    NSAttributedString *attributedString = [[TSMarkdownParser defaultParser] attributedStringFromMarkdown:@"Hello\nMen att *Pär är här* men inte Pia"];
    XCTAssertEqualObjects([[attributedString attribute:NSFontAttributeName atIndex:16 effectiveRange:NULL] fontName], @".Helvetica NeueUI Italic");
    XCTAssertEqualObjects(attributedString.string, @"Hello\nMen att Pär är här men inte Pia");
}

- (void)testDefaultListWithAstricsParsing {
    NSAttributedString *attributedString = [[TSMarkdownParser defaultParser] attributedStringFromMarkdown:@"Hello\n* Men att Pär är här\nmen inte Pia"];
    XCTAssertEqualObjects(attributedString.string, @"Hello\n•\\t Men att Pär är här\nmen inte Pia");
}

- (void)testDefaultListWithPlusParsing {
    NSAttributedString *attributedString = [[TSMarkdownParser defaultParser] attributedStringFromMarkdown:@"Hello\n+ Men att Pär är här\nmen inte Pia"];
    XCTAssertEqualObjects(attributedString.string, @"Hello\n•\\t Men att Pär är här\nmen inte Pia");
}

- (void)testDefaultLinkParsing {
    NSAttributedString *attributedString = [[TSMarkdownParser defaultParser] attributedStringFromMarkdown:@"Hello\n Men att [Pär](http://www.google.com/) är här\nmen inte Pia"];
    NSString *link = [attributedString attribute:NSLinkAttributeName atIndex:17 effectiveRange:NULL];
    XCTAssertEqualObjects(link, @"http://www.google.com/");
    XCTAssertTrue([attributedString.string rangeOfString:@"["].location == NSNotFound);
    XCTAssertTrue([attributedString.string rangeOfString:@"]"].location == NSNotFound);
    XCTAssertTrue([attributedString.string rangeOfString:@"("].location == NSNotFound);
    XCTAssertTrue([attributedString.string rangeOfString:@")"].location == NSNotFound);
    XCTAssertTrue([attributedString.string rangeOfString:@"Pär"].location != NSNotFound);
}

- (void)testDefaultFont {
    NSAttributedString *attributedString = [[TSMarkdownParser defaultParser] attributedStringFromMarkdown:@"Hello\n Men att Pär är här\nmen inte Pia"];
    XCTAssertEqualObjects([[attributedString attribute:NSFontAttributeName atIndex:6 effectiveRange:NULL] fontName], @".Helvetica NeueUI");
}

- (void)testDefaultH1 {
    NSAttributedString *attributedString = [[TSMarkdownParser defaultParser] attributedStringFromMarkdown:@"Hello\n# Men att Pär är här\nmen inte Pia"];
    UIFont *font = [attributedString attribute:NSFontAttributeName atIndex:10 effectiveRange:NULL];
    XCTAssertNotNil(font);
    XCTAssertEqualObjects(font.fontName, @".Helvetica NeueUI Bold");
    XCTAssertEqual(font.pointSize, 20.f);
    XCTAssertTrue([attributedString.string rangeOfString:@"#"].location == NSNotFound);
}

- (void)testDefaultH2 {
    NSAttributedString *attributedString = [[TSMarkdownParser defaultParser] attributedStringFromMarkdown:@"Hello\n## Men att Pär är här\nmen inte Pia"];
    UIFont *font = [attributedString attribute:NSFontAttributeName atIndex:10 effectiveRange:NULL];
    XCTAssertNotNil(font);
    XCTAssertEqualObjects(font.fontName, @".Helvetica NeueUI Bold");
    XCTAssertEqual(font.pointSize, 19.f);
    XCTAssertTrue([attributedString.string rangeOfString:@"#"].location == NSNotFound);
}
@end
