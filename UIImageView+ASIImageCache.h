//
//  UIImageView+ASIImageCache.h
//
//  Created by LiYou on 13-12-5.
//
//

#import <UIKit/UIKit.h>

@interface UIImageView (ASIImageCache)

- (void)setImageWithURLString:(NSString *)urlString
             placeholderImage:(UIImage *)placeholderImage;

- (void)setImageWithURLString:(NSString *)urlString
                    cachePath:(NSString *)cachePath
             placeholderImage:(UIImage *)placeholderImage;

@end
