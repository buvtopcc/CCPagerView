//
//  CustomCell.m
//  CCPagerViewDemo
//
//  Created by pcc on 2020/4/14.
//  Copyright © 2020 pcc. All rights reserved.
//

#import "CustomCell.h"

@implementation CustomCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    self.contentView.backgroundColor = [UIColor whiteColor];
    _imageView = [UIImageView new];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    [self.contentView addSubview:_imageView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}

@end
