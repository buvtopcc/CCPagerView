//
//  CCPagerViewDefaultCell.h
//  CCPagerView
//
//  Created by pcc on 2020/4/13.
//  Copyright © 2020 pcc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCPagerViewDefaultCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIColor *titleLabelTextColor;
@property (nonatomic, strong) UIFont *titleLabelTextFont;
@property (nonatomic, strong) UIColor *titleLabelBackgroundColor;
@property (nonatomic, assign) CGFloat titleLabelHeight;
@property (nonatomic, assign) NSTextAlignment titleLabelTextAlignment;

@property (nonatomic, assign) BOOL hasConfigured;

/** 只展示文字轮播 */
@property (nonatomic, assign) BOOL onlyDisplayText;

+ (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
