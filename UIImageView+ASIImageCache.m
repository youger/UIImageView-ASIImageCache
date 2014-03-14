//
//  UIImageView+ASIImageCache.m
//
//  Created by LiYou on 13-12-5.
//
//

#import "UIImageView+ASIImageCache.h"
#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import <objc/runtime.h>

static char kASIImageRequestOperationObjectKey;
static char kASIDownloadCacheObjectKey;

@interface UIImageView (_ASIImageCache)
@property (readwrite, nonatomic, strong, setter = setImageRequestOperation:) ASIHTTPRequest *imageRequestOperation;
@property (readwrite, nonatomic, strong, setter = setMyCache:) ASIDownloadCache *myCache;
@end

#pragma mark -

@implementation UIImageView (_ASIImageCache)
@dynamic imageRequestOperation;

- (ASIHTTPRequest *)imageRequestOperation {
    return (ASIHTTPRequest *)objc_getAssociatedObject(self, &kASIImageRequestOperationObjectKey);
}

- (ASIDownloadCache *)myCache{
    return (ASIDownloadCache *)objc_getAssociatedObject(self, &kASIDownloadCacheObjectKey);
}

- (void)setImageRequestOperation:(ASIHTTPRequest *)imageRequestOperation {
    objc_setAssociatedObject(self, &kASIImageRequestOperationObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setMyCache:(ASIDownloadCache *)myCache
{
    objc_setAssociatedObject(self, &kASIDownloadCacheObjectKey, myCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (ASINetworkQueue *)sharedImageRequestOperationQueue {
    static ASINetworkQueue *imageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageRequestOperationQueue = [[ASINetworkQueue alloc] init];
        imageRequestOperationQueue.delegate = self;
        [imageRequestOperationQueue setShouldCancelAllRequestsOnFailure:NO];
        [imageRequestOperationQueue setQueueDidFinishSelector:@selector(queueDidFinish:)];
        [imageRequestOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        [imageRequestOperationQueue go];
    });
    
    return imageRequestOperationQueue;
}

+ (ASIDownloadCache *)sharedImageCache {
    static ASIDownloadCache *imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        imageCache = [[ASIDownloadCache alloc] init];
        
    });
    
    return imageCache;
}

- (void)setImageWithURLString:(NSString *)urlString
             placeholderImage:(UIImage *)placeholderImage
{
    ASIDownloadCache *cache = [ASIDownloadCache sharedCache];
    NSData *cachedData = [cache cachedResponseDataForURL:[NSURL URLWithString:urlString]];
    UIImage *cachedImage = [UIImage imageWithData:cachedData];
    if (cachedImage) {
        self.image = cachedImage;

    } else {
        self.image = placeholderImage;
        ASIHTTPRequest *imageRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
        imageRequest.delegate = self;
        [imageRequest setDownloadCache:cache];
        [imageRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
        [imageRequest setCompletionBlock:^{
            
            NSData *responseData = [imageRequest responseData];
            UIImage *responseImage = [UIImage imageWithData:responseData];
            self.image = responseImage;
        }];
        [imageRequest setFailedBlock:^{

            //NSError *error = [imageRequest error];
        }];
        [imageRequest startAsynchronous];
        //[[[self class] sharedImageRequestOperationQueue] addOperation:imageRequest];
    }
}

- (void)setImageWithURLString:(NSString *)urlString
                    cachePath:(NSString *)cachePath
             placeholderImage:(UIImage *)placeholderImage
{
    ASIDownloadCache *cache;
    if (cachePath) {
        
        cache = [[self class] sharedImageCache];
        [cache setStoragePath:cachePath];
    }
    else{
        cache = [ASIDownloadCache sharedCache];
    }
    
    
    NSData *cachedData = [cache cachedResponseDataForURL:[NSURL URLWithString:urlString]];
    UIImage *cachedImage = [UIImage imageWithData:cachedData];
    if (cachedImage) {
        self.image = cachedImage;
        
    } else {
        self.image = placeholderImage;
        ASIHTTPRequest *imageRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
        imageRequest.delegate = self;
        [self setMyCache:cache];
        [imageRequest setDownloadCache:[self myCache]];
        [imageRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
        [imageRequest setCompletionBlock:^{
            
            NSData *responseData = [imageRequest responseData];
            UIImage *responseImage = [UIImage imageWithData:responseData];
            self.image = responseImage;
        }];
        [imageRequest setFailedBlock:^{
            
            //NSError *error = [imageRequest error];
        }];
        [imageRequest startAsynchronous];
    }
    
}

- (void)cancelImageRequestOperation {
    [self.imageRequestOperation cancel];
    self.imageRequestOperation = nil;
}

#pragma mark - 

- (void)queueDidFinish:(ASINetworkQueue*)queue
{
    [ASIHTTPRequest hideNetworkActivityIndicator];
}

@end
