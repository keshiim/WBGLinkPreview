//
//  NSString+previewExtension.h
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
@import UIKit;
#else
@import Cocoa;
#endif

@interface NSString (previewExtension)

///Trim
- (NSString *)trim;

/// Remove extra white spaces
- (NSString *)extendedTrim;

/// Decode HTML entities
- (NSString *)decoded;

/// Strip tags
- (NSString *)tagStripped;

/// Delete tab by pattern
- (NSString *)deleteTagByPattern:(NSString *)pattern;

/// Replace
- (NSString *)replaceSearchString:(NSString *)search withString:(NSString *)with;

/// SubString
- (NSString *)subStringStart:(NSUInteger)start end:(NSUInteger)end;

/// Check if it's a valid url
- (BOOL)isValidURL;

/// Check if url is an image
- (BOOL)isImage;

@end
