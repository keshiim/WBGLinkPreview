//
//  NSURLSession+extension.h
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface NSURLSession (extension)

- (void)synchronousDataTaskWithURL:(NSURL *)url callBack:(void(^)(NSData *data, NSURLResponse *response, NSError *error))callBack;

@end
NS_ASSUME_NONNULL_END
