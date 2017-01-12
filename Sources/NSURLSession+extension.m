//
//  NSURLSession+extension.m
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import "NSURLSession+extension.h"
//同步返回
@implementation NSURLSession (extension)
- (void)synchronousDataTaskWithURL:(NSURL *)url callBack:(void(^)(NSData *data, NSURLResponse *response, NSError *error))callBack {
    __block NSData        *_data = nil;
    __block NSURLResponse *_response = nil;
    __block NSError       *_error = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    if (url) {
        [[self dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            _data = data;
            _response = response;
            _error = error;
            
            dispatch_semaphore_signal(semaphore);
        }] resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    return callBack(_data, _response, _error);
}

@end
