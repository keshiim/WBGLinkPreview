//
//  WBGPreviewRegex.h
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString * const imagePattern;
FOUNDATION_EXTERN NSString * const imageTagPattern;
FOUNDATION_EXTERN NSString * const titlePattern;
FOUNDATION_EXTERN NSString * const metatagPattern;
FOUNDATION_EXTERN NSString * const metatagContentPattern;
FOUNDATION_EXTERN NSString * const cannonicalUrlPattern;
FOUNDATION_EXTERN NSString * const rawUrlPattern;
FOUNDATION_EXTERN NSString * const rawTagPattern;
FOUNDATION_EXTERN NSString * const inlineStylePattern;
FOUNDATION_EXTERN NSString * const inlineScriptPattern;
FOUNDATION_EXTERN NSString * const linkPattern;
FOUNDATION_EXTERN NSString * const scriptPattern;
FOUNDATION_EXTERN NSString * const commentPattern;

@interface WBGPreviewRegex : NSObject

+ (BOOL)testString:(NSString *)string regex:(NSString *)regex;

// Match first occurrency
+ (NSString *)pregMatchFirstString:(NSString *)string regex:(NSString *)regex index:(NSUInteger)index;

// Match all occurrencies
+ (NSArray<NSString *> *)pregMatchAllString:(NSString *)string regex:(NSString *)regex index:(NSUInteger)index;

// Extract matches from string
+ (NSArray<NSString *> *)stringMatchesResults:(NSArray *)results text:(NSString *)text index:(NSUInteger)index;

// Return tag pattern
+ (NSString *)tagPattern:(NSString *)tag;

@end
