//
//  WBGPreviewError.h
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PreviewURLErorr) {
    noURLHasBeenFound = 0,
    invalidURL,
    cannotBeOpened,
    parseError
};

@interface WBGPreviewError : NSError

+ (WBGPreviewError *)previewError:(PreviewURLErorr)error url:(NSString *)url;

@property (nonatomic, assign) PreviewURLErorr URLError;
@property (nonatomic, copy  ) NSString *url;

@end
