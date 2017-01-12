//
//  WBGLinkPreview.m
//  Trader
//
//  Created by Jason on 2017/1/5.
//
//

#import "WBGLinkPreview.h"
#import "NSString+previewExtension.h"
#import "WBGPreviewRegex.h"
#import "WBGPreviewError.h"


static const NSUInteger titleMinimumRelevant = 15;
static const NSUInteger decriptionMinimumRelevant = 100;

@interface WBGLinkPreview ()
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSObject *> *result;
@property (nonatomic, assign) BOOL wasOnMainThread;

@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSURLSession *sesstion;
@end

@interface WBGLinkPreview (extraction)
- (NSURL *)extractURL;
- (void)unshortenURL:(NSURL *)url completion:(void(^)(NSURL *unshortened))completion;
- (NSString *)extractCanonicalURL:(NSURL *)finalUrl;
- (void)extractInfo:(void(^)(void))completion onError:(void(^)(WBGPreviewError *))onError;
@end

@interface WBGLinkPreview (otherExtension)
- (void)crawlMetaTags:(NSString *)htmlCode;
- (NSString *)crawlTitle:(NSString *)htmlCode;
- (NSString *)crawlDescription:(NSString *)htmlCode;
- (void)crawlImages:(NSString *)htmlCode;
@end

@implementation WBGLinkPreview

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sesstion = [NSURLSession sharedSession];
        self.wasOnMainThread = YES;
        self.result = [NSMutableDictionary new];
    }
    return self;
}

- (void)previewWithText:(NSString *)text onSuccess:(void (^)(NSDictionary *result))onSuccess onError:(void (^)(WBGPreviewError *error))onError {
    [self resetResult];
    self.wasOnMainThread = [NSThread isMainThread];
    
    self.text = text;
    
    NSURL *url = [self extractURL];
    if (url) {
        self.url = url;
        self.result[@"url"] = self.url.absoluteString;
        [self unshortenURL:url completion:^(NSURL *unshortened) {
            self.result[@"finalUrl"] = unshortened;
            self.result[@"canonicalUrl"] = [self extractCanonicalURL:unshortened];
            [self extractInfo:^{
                onSuccess(self.result);
            } onError:onError];
        }];
    } else {
        onError([WBGPreviewError previewError:noURLHasBeenFound url:self.text]);
    }
    
}


#pragma mark - private
// Reset data on result
- (void)resetResult {
    self.result = [@{@"url":@"",
                     @"finalUrl":@"",
                     @"canonicalUrl":@"",
                     @"title":@"",
                     @"description":@"",
                     @"images":[NSArray new],
                     @"image":@""
                     } mutableCopy];
}

- (void)fillRemainingInfoWithTitle:(NSString *)title description:(NSString *)description images:(NSArray<NSString *> *)images image:(NSString *)image {
    [self.result setObject:title forKey:@"title"];
    [self.result setObject:description forKey:@"description"];
    [self.result setObject:images forKey:@"images"];
    [self.result setObject:image forKey:@"image"];
}

- (void)cancel {
    if (self.task) {
        [self.task cancel];
    }
}

@end

#pragma mark - Extraction functions
@implementation WBGLinkPreview (extraction)

/// Extract first URL from text
- (NSURL *)extractURL {
    NSArray<NSString *> *pieces = [[self.text componentsSeparatedByString:@" "] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isValidURL];
    }]];
    
    NSURL *url = nil;
    if (pieces.count > 0) {
        NSString *piece = pieces[0];
        url = [NSURL URLWithString:piece];
    }
    return url;
}

/// Unshorten URL by following redirections
- (void)unshortenURL:(NSURL *)url completion:(void(^)(NSURL *unshortened))completion {
    __weak typeof(self)weakSelf = self;
    self.task = [self.sesstion dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSURL *finalResult = response.URL;
        if (finalResult) {
            
            if ([finalResult.absoluteString isEqualToString:url.absoluteString]) {
                if (weakSelf.wasOnMainThread) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(url);
                    });
                } else {
                    completion(url);
                }
            } else {
                [weakSelf.task cancel];
                [weakSelf unshortenURL:finalResult completion:completion];
            }
        } else {
            if (weakSelf.wasOnMainThread) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(url);
                });
            } else {
                completion(url);
            }
        }
    }];
    
    if (self.task) {
        [self.task resume];
    }
}

- (void)extractInfo:(void(^)(void))completion onError:(void(^)(WBGPreviewError *))onError {
    NSURL *url = [[self.result objectForKey:@"finalUrl"] isKindOfClass:[NSURL class]] ? (NSURL *)[self.result objectForKey:@"finalUrl"] : nil;
    
    if (url) {
        if ([url.absoluteString isImage]) {
            [self fillRemainingInfoWithTitle:@"" description:@"" images:@[url.absoluteString] image:url.absoluteString];
            completion();
        } else {
            NSURL *sourceUrl = [url.absoluteString hasPrefix:@"http://"] || [url.absoluteString hasPrefix:@"https://"] ? url : [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url.absoluteString]];
            
            NSStringEncoding encoding;
            NSError *error = nil;
            __block NSString *source = [[NSString stringWithContentsOfURL:sourceUrl usedEncoding:&encoding error:&error] extendedTrim];
            
            if (!error) {
                if (self.wasOnMainThread) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        source = [self cleanSource:source];
                        [self performPageCrawing:source];
                        
                        completion();
                    });
                } else {
                    source = [self cleanSource:source];
                    [self performPageCrawing:source];
                    
                    completion();
                }
            } else {
                NSMutableArray *arrayOfEncodings = [NSMutableArray new];
                const NSStringEncoding *encodings = [NSString availableStringEncodings];
                while (*encodings != 0){
                    [arrayOfEncodings addObject:[NSNumber numberWithUnsignedLong:*encodings]];
                    encodings++;
                }
                [self tryAnotherEncoding:sourceUrl encodingArray:arrayOfEncodings completion:completion onError:onError];
            }
        }
    } else {
        [self fillRemainingInfoWithTitle:@"" description:@"" images:@[] image:@""];
        completion();
    }
}

// Try to get the page using another available encoding instead the page's own encoding
- (void)tryAnotherEncoding:(NSURL *)sourceUrl encodingArray:(NSArray *)encodingArray completion:(void(^)(void))completion onError:(void(^)(WBGPreviewError *))onError {
    if (!encodingArray || encodingArray.count == 0) {
        onError([WBGPreviewError previewError:parseError url:sourceUrl.absoluteString]);
    } else {
        NSError *error = nil;
        __block NSString *source = [NSString stringWithContentsOfURL:sourceUrl encoding:[encodingArray[0] unsignedLongValue] error:&error];
        
        if (!error) {
            if (self.wasOnMainThread) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    source = [self cleanSource:source];
                    [self performPageCrawing:source];
                    completion();
                });
            }
            else {
                source = [self cleanSource:source];
                [self performPageCrawing:source];
                completion();
            }
        } else {
            NSNumber *firstEncoding = encodingArray[0];
            encodingArray = [encodingArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNumber *evaluatedObject, NSDictionary<NSString *,id> *bindings) {
                return ![evaluatedObject isEqualToNumber:firstEncoding];
            }]];
            [self tryAnotherEncoding:sourceUrl encodingArray:encodingArray completion:completion onError:onError];
        }
    }
}

- (NSString *)cleanSource:(NSString *)_source {
    NSString *source = _source;
    source = [source deleteTagByPattern:inlineStylePattern];
    source = [source deleteTagByPattern:inlineScriptPattern];
    source = [source deleteTagByPattern:linkPattern];
    source = [source deleteTagByPattern:scriptPattern];
    source = [source deleteTagByPattern:commentPattern];
    return source;
}

// Perform the page crawiling
- (void)performPageCrawing:(NSString *)_htmlCode {
    NSString *htmlCode = _htmlCode;
    
    [self crawlMetaTags:htmlCode];
    htmlCode = [self crawlTitle:htmlCode];
    htmlCode = [self crawlDescription:htmlCode];
    [self crawlImages:htmlCode];
}

// Extract canonical URL
- (NSString *)extractCanonicalURL:(NSURL *)finalUrl {
    NSString *preUrl = finalUrl.absoluteString;
    NSString *url = [[[[preUrl
                        replaceSearchString:@"http://" withString:@""]
                       replaceSearchString:@"https://" withString:@""]
                      replaceSearchString:@"file://" withString:@""]
                     replaceSearchString:@"ftp://" withString:@""];
    if (![preUrl isEqualToString:url]) {
        NSString *canonicalUrl = [WBGPreviewRegex pregMatchFirstString:url regex:cannonicalUrlPattern index:1];
        if (canonicalUrl && canonicalUrl.length > 0) {
            return [self extractBaseUrl:canonicalUrl];
        } else {
            return [self extractBaseUrl:url];
        }
    } else {
        return [self extractBaseUrl:url];
    }
}

- (NSString *)extractBaseUrl:(NSString *)url {
    NSRange slash = [url rangeOfString:@"/"];
    if (slash.location != NSNotFound) {
        url = [url subStringStart:0 end:slash.length > 1 ? slash.length - 1 : 0];
    }
    return url;
}

@end


///Tag functions
@implementation WBGLinkPreview (otherExtension)

/// Search for meta tags
- (void)crawlMetaTags:(NSString *)htmlCode {
    NSArray<NSString *> *possibleTags = @[@"title", @"description", @"image"];
    NSArray<NSString *> *metatags= [WBGPreviewRegex pregMatchAllString:htmlCode regex:metatagPattern index:1];
    
    [metatags enumerateObjectsUsingBlock:^(NSString * _Nonnull metatag, NSUInteger idx, BOOL * _Nonnull stop) {
        for (NSString *tag in possibleTags) {
            if ([metatag containsString:[NSString stringWithFormat:@"property=\"og:%@",tag]] ||
                [metatag containsString:[NSString stringWithFormat:@"property='og:%@", tag]] ||
                [metatag containsString:[NSString stringWithFormat:@"name=\"twitter:%@",tag]] ||
                [metatag containsString:[NSString stringWithFormat:@"name='twitter:%@", tag]] ||
                [metatag containsString:[NSString stringWithFormat:@"name=\"%@", tag]] ||
                [metatag containsString:[NSString stringWithFormat:@"name='%@", tag]]  ||
                [metatag containsString:[NSString stringWithFormat:@"itemprop=\"%@",tag]] ||
                [metatag containsString:[NSString stringWithFormat:@"itemprop='%@", tag]]) {
                NSString *tmp = [[self.result objectForKey:tag] isKindOfClass:[NSString class]] ? (NSString *)[self.result objectForKey:tag] : @"";
                if ([tmp length] == 0) {
                    NSString *value = nil;
                    if ((value = [WBGPreviewRegex pregMatchFirstString:metatag regex:metatagContentPattern index:2])) {
                        value = [value decoded].extendedTrim;
                        self.result[tag] = [tag isEqualToString:@"image"] ? [self addImagePrefixIfNeeded:value] : value;
                    }
                    
                }
            }
        }
    }];
}

/// Crawl for title if needed
- (NSString *)crawlTitle:(NSString *)htmlCode {
    NSString *title = [self.result[@"title"] isKindOfClass:[NSString class]] ? (NSString *)self.result[@"title"] : nil;
    if (!title || title.length == 0) {
        NSString *value = nil;
        if ((value = [WBGPreviewRegex pregMatchFirstString:htmlCode regex:titlePattern index:2])) {
            if (value.length == 0) {
                NSString *fromBody = [self crawlCodeContent:htmlCode minimum:titleMinimumRelevant];
                if (fromBody.length > 0) {
                    self.result[@"title"] = fromBody.decoded.extendedTrim;
                    return [htmlCode replaceSearchString:fromBody withString:@""];
                }
            } else {
                self.result[@"title"] = value.decoded.extendedTrim;
            }
        }
    }
    return htmlCode;
}

/// Crawl for description if needed
- (NSString *)crawlDescription:(NSString *)htmlCode {
    NSString *description = [self.result[@"description"] isKindOfClass:[NSString class]] ? (NSString *)self.result[@"description"] : nil;
    if (description) {
        if (description.length == 0) {
            NSString *value = [self crawlCodeContent:htmlCode minimum:decriptionMinimumRelevant];
            if (value.length > 0) {
                self.result[@"description"] = value.decoded.extendedTrim;
            }
        }
    }
    
    return htmlCode;
}

/// Crawl for images
- (void)crawlImages:(NSString *)htmlCode {
    NSString *mainImage = [self.result[@"image"] isKindOfClass:[NSString class]] ? (NSString *)self.result[@"image"] : @"";
    if (mainImage.length == 0) {
        NSString *images = [self.result[@"images"] isKindOfClass:[NSString class]] ? (NSString *)self.result[@"images"] : @"";
        if (images.length == 0 ) {
            NSArray<NSString *> *values = [WBGPreviewRegex pregMatchAllString:htmlCode regex:imageTagPattern index:2];
            if (values.count > 0) {
                NSMutableArray<NSString *> *imgs = @[].mutableCopy;
                for (NSString *value in values) {
                    [imgs addObject:[self addImagePrefixIfNeeded:value]];
                }
                
                self.result[@"images"] = imgs.copy;
                
                if (imgs.count > 0) {
                    self.result[@"image"] = imgs[0];
                }
            }
        }
    } else {
        self.result[@"images"] = @[[self addImagePrefixIfNeeded:mainImage]];
    }
}

/// Crawl the entire code
- (NSString *)crawlCodeContent:(NSString *)content minimum:(NSInteger)minimum {
    NSString *resultFirstSearch = [self getTagConent:@"p" content:content minimum:minimum];
    
    if (resultFirstSearch.length > 0) {
        return resultFirstSearch;
    } else {
        NSString *resultSecondSearch = [self getTagConent:@"div" content:content minimum:minimum];
        if (resultSecondSearch.length > 0) {
            return resultSecondSearch;
        } else {
            NSString *resultThirdSearch = [self getTagConent:@"span" content:content minimum:minimum];
            if (resultThirdSearch.length > 0) {
                return resultThirdSearch;
            } else {
                if (resultThirdSearch.length >= resultFirstSearch.length) {
                    if (resultThirdSearch.length >= resultThirdSearch.length) {
                        return resultThirdSearch;
                    } else {
                        return resultThirdSearch;
                    }
                } else {
                    return resultFirstSearch;
                }
            }
        }
    }
}

/// Get tag content
- (NSString *)getTagConent:(NSString *)tag content:(NSString *)content minimum:(NSInteger)minimum {
    NSString *pattern = [WBGPreviewRegex tagPattern:tag];
    NSInteger index = 2;
    NSArray<NSString *> *rawMatches = [WBGPreviewRegex pregMatchAllString:content regex:pattern index:index];
    NSArray<NSString *> *matches = [rawMatches filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString * _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject.extendedTrim.tagStripped.length >= minimum;
    }]];
    
    NSString *result = matches.count > 0 ? matches[0] : @"";
    if (result.length == 0) {
        
        NSString *match = [WBGPreviewRegex pregMatchFirstString:content regex:pattern index:2];
        if (match) {
            result = [[match extendedTrim] tagStripped];
        }
    }
    
    return result;
}

- (NSString *)addImagePrefixIfNeeded:(NSString *)_image {
    NSString *image = _image;
    NSString *canonicalUrl = [self.result[@"canonicalUrl"] isKindOfClass:[NSString class]] ? (NSString *)self.result[@"canonicalUrl"] : nil;
    
    if (canonicalUrl) {
        if ([image hasPrefix:@"//"]) {
            image = [@"http:" stringByAppendingString:image];
        } else if ([image hasPrefix:@"/"]) {
            image = [@"http://" stringByAppendingFormat:@"%@%@", canonicalUrl, image];
        }
    }
    return image;
}

@end
