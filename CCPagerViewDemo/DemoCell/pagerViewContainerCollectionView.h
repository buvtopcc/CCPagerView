//
//  pagerViewContainerCollectionView.h
//  CCPagerViewDemo
//
//  Created by pcc on 2020/4/14.
//  Copyright © 2020 pcc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface pagerViewContainerCollectionView : UICollectionViewCell

@property (nonatomic, strong) NSArray *images;

- (void)cellWillAppear;
- (void)cellWillDisappear;

@end

NS_ASSUME_NONNULL_END
