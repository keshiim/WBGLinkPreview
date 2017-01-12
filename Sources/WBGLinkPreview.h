//
//  WBGLinkPreview.h
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import <Foundation/Foundation.h>
#import "WBGPreviewError.h"

@interface WBGLinkPreview : NSObject
@property (nonatomic, strong, readonly) NSString *text;
@property (nonatomic, strong, readonly) NSMutableDictionary *result;

- (void)previewWithText:(NSString *)text onSuccess:(void (^)(NSDictionary *result))onSuccess onError:(void (^)(WBGPreviewError *error))onError;
@end
