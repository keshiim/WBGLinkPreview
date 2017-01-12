//
//  NSString+previewExtension.m
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import "NSString+previewExtension.h"
#import "WBGPreviewRegex.h"

@implementation NSString (previewExtension)
///Trim
- (NSString *)trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/// Remove extra white spaces
- (NSString *)extendedTrim {
    NSArray * components = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return [[components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString * _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject.length > 0;
    }]] componentsJoinedByString:@" "].trim;
}

/// Decode HTML entities
- (NSString *)decoded {
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                 documentAttributes:nil error:nil];
    return attributedString.string ? : self;
}

/// Strip tags
- (NSString *)tagStripped {
    return [self deleteTagByPattern:rawTagPattern];
}

/// Delete tab by pattern
- (NSString *)deleteTagByPattern:(NSString *)pattern {
    return [self stringByReplacingOccurrencesOfString:pattern withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, self.length)];
}

/// Replace
- (NSString *)replaceSearchString:(NSString *)search withString:(NSString *)with {
    return [self stringByReplacingOccurrencesOfString:search withString:with];
}

/// SubString
- (NSString *)subStringStart:(NSUInteger)start end:(NSUInteger)end {
    return [self substringWithRange:NSMakeRange(start, end)];
}

/// Check if it's a valid url
- (BOOL)isValidURL {
    return [WBGPreviewRegex testString:self regex:rawUrlPattern];
}

/// Check if url is an image
- (BOOL)isImage {
    return [WBGPreviewRegex testString:self regex:imagePattern];
}

@end
