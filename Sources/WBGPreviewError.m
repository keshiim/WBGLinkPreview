//
//  WBGPreviewError.m
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import "WBGPreviewError.h"

@implementation WBGPreviewError

+ (WBGPreviewError *)previewError:(PreviewURLErorr)error url:(NSString *)url {
    WBGPreviewError *previewError = [self new];
    previewError.URLError = error;
    previewError.url = url;
    return previewError;
}

/**
 @override description
 
 @return custom error string
 */
- (NSString *)description {
    switch (self.URLError) {
        case noURLHasBeenFound: return NSLocalizedString(@"No URL has been found", @"");
        break;
        case invalidURL: return NSLocalizedString(@"This data is not valid URL", @"");
        break;
        case cannotBeOpened: return NSLocalizedString(@"This URL cannot be opened", @"");
        break;
        case parseError: return NSLocalizedString(@"An error occurred when parsing the HTML", @"");
        break;
        default: return @"";
        break;
    }
}

@end
