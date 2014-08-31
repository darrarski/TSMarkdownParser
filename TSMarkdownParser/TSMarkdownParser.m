//
//  TSMarkdownParser.m
//  TSMarkdownParser
//
//  Created by Tobias Sundstrand on 14-08-30.
//  Copyright (c) 2014 Computertalk Sweden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSMarkdownParser.h"

@interface TSExpressionBlockPair : NSObject

@property (nonatomic, strong) NSRegularExpression *regularExpression;
@property (nonatomic, strong) TSMarkdownParserBlock block;

+ (TSExpressionBlockPair *)pairWithRegularExpression:(NSRegularExpression *)regularExpression block:(TSMarkdownParserBlock)block;

@end

@implementation TSExpressionBlockPair

+ (TSExpressionBlockPair *)pairWithRegularExpression:(NSRegularExpression *)regularExpression block:(TSMarkdownParserBlock)block {
    TSExpressionBlockPair *pair = [TSExpressionBlockPair new];
    pair.regularExpression = regularExpression;
    pair.block = block;
    return pair;
}

@end

@interface TSMarkdownParser ()

@property (nonatomic, strong) NSMutableArray *parsingPairs;

@end

@implementation TSMarkdownParser

- (instancetype)init {
    self = [super init];
    if(self) {
        _parsingPairs = [NSMutableArray array];
        _paragraphFont = [UIFont systemFontOfSize:12];
        _strongFont = [UIFont boldSystemFontOfSize:12];
        _emphasisFont = [UIFont italicSystemFontOfSize:12];
        _h1Font = [UIFont boldSystemFontOfSize:23];
        _h2Font = [UIFont boldSystemFontOfSize:21];
        _h3Font = [UIFont boldSystemFontOfSize:19];
        _h4Font = [UIFont boldSystemFontOfSize:17];
        _h5Font = [UIFont boldSystemFontOfSize:15];
        _h6Font = [UIFont boldSystemFontOfSize:13];
        _linkColor = [UIColor blueColor];
        _linkUnderlineStyle = @(NSUnderlineStyleSingle);
    }
    return self;
}

+ (TSMarkdownParser *)standardParser {


    TSMarkdownParser *defaultParser = [TSMarkdownParser new];
    [defaultParser addStrongParsing];
    [defaultParser addEmphasisParsing];
    [defaultParser addListParsing];
    [defaultParser addLinkParsing];
    [defaultParser addH1Parsing];
    [defaultParser addH2Parsing];
    [defaultParser addH3Parsing];
    [defaultParser addH4Parsing];
    [defaultParser addH5Parsing];
    [defaultParser addH6Parsing];
    [defaultParser addImageParsing];

    return defaultParser;
}

static NSString *const TSMarkdownBoldRegex      = @"(\\*|_){2}.*(\\*|_){2}";
static NSString *const TSMarkdownEmRegex        = @"(\\*|_).*(\\*|_)";
static NSString *const TSMarkdownListRegex      = @"^(\\*|\\+).+$";
static NSString *const TSMarkdownLinkRegex      = @"(?<!\\!)\\[.*\\]\\(.*\\)";
static NSString *const TSMarkdownImageRegex     = @"\\!\\[.*\\]\\(.*\\)";
static NSString *const TSMarkdownHeaderRegex    = @"^#{%i}(?!#).+$";

- (void)addStrongParsing {
    NSRegularExpression *boldParsing = [NSRegularExpression regularExpressionWithPattern:TSMarkdownBoldRegex options:NSRegularExpressionCaseInsensitive error:nil];
    __weak TSMarkdownParser *weakSelf = self;
    [self addParsingRuleWithRegularExpression:boldParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {

        [attributedString addAttribute:NSFontAttributeName
                                 value:weakSelf.strongFont
                                 range:match.range];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 2)];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location+match.range.length-4, 2)];

    }];
}

- (void)addEmphasisParsing {
    NSRegularExpression *boldParsing = [NSRegularExpression regularExpressionWithPattern:TSMarkdownEmRegex options:NSRegularExpressionCaseInsensitive error:nil];
    __weak TSMarkdownParser *weakSelf = self;
    [self addParsingRuleWithRegularExpression:boldParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakSelf.emphasisFont
                                 range:match.range];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 1)];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location+match.range.length-2, 1)];

    }];
}

- (void)addListParsing {
    NSRegularExpression *listParsing = [NSRegularExpression regularExpressionWithPattern:TSMarkdownListRegex options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:nil];
    [self addParsingRuleWithRegularExpression:listParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        [attributedString replaceCharactersInRange:NSMakeRange(match.range.location, 1) withString:@"•\\t"];
    }];

}

- (void)addLinkParsing {
    NSRegularExpression *linkParsing = [NSRegularExpression regularExpressionWithPattern:TSMarkdownLinkRegex options:NSRegularExpressionCaseInsensitive error:nil];
    __weak TSMarkdownParser *weakSelf = self;
    [self addParsingRuleWithRegularExpression:linkParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {

        NSUInteger linkStartInResult = [attributedString.string rangeOfString:@"(" options:0 range:match.range].location;
        NSRange linkRange = NSMakeRange(linkStartInResult, match.range.length+match.range.location-linkStartInResult-1);
        NSString *linkURLString = [attributedString.string substringWithRange:NSMakeRange(linkRange.location+1, linkRange.length-1)];
        NSURL *url = [NSURL URLWithString:linkURLString];

        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 1)];
        NSUInteger linkTextEndLocation = [attributedString.string rangeOfString:@"]" options:0 range:match.range].location;
        NSRange linkTextRange = NSMakeRange(match.range.location, linkTextEndLocation-match.range.location);

        [attributedString deleteCharactersInRange:NSMakeRange(linkRange.location-2, linkRange.length+2)];
        [attributedString addAttribute:NSLinkAttributeName
                                 value:url
                                 range:linkTextRange];
        [attributedString addAttribute:NSUnderlineStyleAttributeName
                                 value:weakSelf.linkUnderlineStyle
                                 range:linkTextRange];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:weakSelf.linkColor
                                 range:linkTextRange];
    }];
}

- (void)addH1Parsing {
   [self addHeaderParsingWithInt:1 font:@"h1Font"];
}

- (void)addH2Parsing {
    [self addHeaderParsingWithInt:2 font:@"h2Font"];
}

- (void)addH3Parsing {
    [self addHeaderParsingWithInt:3 font:@"h3Font"];
}

- (void)addH4Parsing {
    [self addHeaderParsingWithInt:4 font:@"h4Font"];
}

- (void)addH5Parsing {
    [self addHeaderParsingWithInt:5 font:@"h5Font"];
}

- (void)addH6Parsing {
    [self addHeaderParsingWithInt:6 font:@"h6Font"];
}

- (void)addHeaderParsingWithInt:(NSUInteger)header font:(NSString *)fontKey{
    NSString *headerRegex = [NSString stringWithFormat:TSMarkdownHeaderRegex, header];
    NSRegularExpression *headerExpression = [NSRegularExpression regularExpressionWithPattern:headerRegex options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:nil];
    __weak TSMarkdownParser *weakSelf = self;
    [self addParsingRuleWithRegularExpression:headerExpression withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:[weakSelf valueForKey:fontKey]
                                 range:match.range];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, header)];

    }];
}

- (void)addImageParsing {
    NSRegularExpression *headerExpression = [NSRegularExpression regularExpressionWithPattern:TSMarkdownImageRegex options:NSRegularExpressionCaseInsensitive error:nil];
    [self addParsingRuleWithRegularExpression:headerExpression withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        NSUInteger imagePathStart = [attributedString.string rangeOfString:@"(" options:0 range:match.range].location;
        NSRange linkRange = NSMakeRange(imagePathStart, match.range.length+match.range.location- imagePathStart -1);
        NSString *imagePath = [attributedString.string substringWithRange:NSMakeRange(linkRange.location+1, linkRange.length-1)];
        UIImage *image = [UIImage imageNamed:imagePath];
        if(image){
            [attributedString deleteCharactersInRange:match.range];
            NSTextAttachment *imageAttachment = [NSTextAttachment new];
            imageAttachment.image = image;
            [attributedString addAttribute:NSAttachmentAttributeName value:imageAttachment range:NSMakeRange(match.range.location, 1)];
        } else {
            NSUInteger linkTextEndLocation = [attributedString.string rangeOfString:@"]" options:0 range:match.range].location;
            NSRange linkTextRange = NSMakeRange(match.range.location+2, linkTextEndLocation-match.range.location-2);
            NSString *alternativeText = [attributedString.string substringWithRange:linkTextRange];
            [attributedString replaceCharactersInRange:match.range withString:alternativeText];
        }


    }];
}

- (void)addParsingRuleWithRegularExpression:(NSRegularExpression *)regularExpression withBlock:(TSMarkdownParserBlock)block {
    @synchronized (self) {
        [self.parsingPairs addObject:[TSExpressionBlockPair pairWithRegularExpression:regularExpression block:block]];
    }
}

- (NSAttributedString *)attributedStringFromMarkdown:(NSString *)markdown {
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:markdown];

    [mutableAttributedString addAttribute:NSFontAttributeName
                                    value:self.paragraphFont
                                    range:NSMakeRange(0, mutableAttributedString.length)];

    @synchronized (self) {
        for (TSExpressionBlockPair *expressionBlockPair in self.parsingPairs) {
            NSTextCheckingResult *match;
            while((match = [expressionBlockPair.regularExpression firstMatchInString:mutableAttributedString.string options:0 range:NSMakeRange(0, mutableAttributedString.string.length)])){
                expressionBlockPair.block(match, mutableAttributedString);
            }
        }
    }
    return mutableAttributedString;
}


@end
