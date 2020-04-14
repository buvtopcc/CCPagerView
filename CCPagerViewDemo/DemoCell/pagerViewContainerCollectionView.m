//
//  pagerViewContainerCollectionView.m
//  CCPagerViewDemo
//
//  Created by pcc on 2020/4/14.
//  Copyright © 2020 pcc. All rights reserved.
//

#import "pagerViewContainerCollectionView.h"
#import "CCPagerView.h"
#import "CustomCell.h"

@interface pagerViewContainerCollectionView () <CCPagerViewDelegate>

@property (nonatomic, strong) CCPagerView *pagerView;

@end

@implementation pagerViewContainerCollectionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpPagerView];
    }
    return self;
}

- (void)setUpPagerView
{
    CGFloat w = self.bounds.size.width;
    CGRect rect = CGRectMake(10, 80, w - 20, 180);
    CCPagerView *pageView = [CCPagerView pagerViewWithFrame:rect placeholderImage:[UIImage imageNamed:@"placeholder"]];
    pageView.delegate = self;
//    pageView.pageControlAligment = CCPagerViewControlAligmentLeft;
//    pageView.pageControlStyle = CCPagerViewControlStyleCustom;
//    pageView.currentPageDotColor = [UIColor whiteColor]; // 自定义分页控件小圆标颜色
//    pageView.autoScrollTimeInterval = 3;
//    pageView.pageControlDotSize = CGSizeMake(4, 4);
    pageView.layer.masksToBounds = YES;
    pageView.layer.cornerRadius = 5;
    [self addSubview:pageView];
    _pagerView = pageView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _pagerView.frame = self.bounds;
}

- (void)setImages:(NSArray *)images
{
    _images = images;
    [_pagerView reloadData];
}

- (void)cellWillAppear
{
    [_pagerView resumeScroll];
}

- (void)cellWillDisappear
{
    [_pagerView pauseScroll];
}

- (void)pagerView:(CCPagerView *)cycleScrollView didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@">>> 点击了第%@张图片", @(index));
}

 
// 滚动到第几张图回调
- (void)pagerView:(CCPagerView *)cycleScrollView didAppearAtIndex:(NSInteger)index
{
    NSLog(@">>> 滚动到第%@张图", @(index));
    
}

- (Class)pagerViewCellClass:(CCPagerView *)view
{
    return [CustomCell class];
}

- (void)configCell:(UICollectionViewCell *)cell forIndex:(NSInteger)index pagerView:(CCPagerView *)view
{
    CustomCell *myCell = (CustomCell *)cell;
    
    NSString *imageUrl = _images[index];
    if ([imageUrl hasPrefix:@"http"]) {
        // TODO: AFNetWorking
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self->_images[index]]];
        UIImage *image = [[UIImage alloc] initWithData:data];
        myCell.imageView.image = image;
    } else { // 本地图片
        myCell.imageView.image = [UIImage imageNamed:_images[index]];
    }
}

- (NSUInteger)numberOfPagerViewCell:(CCPagerView *)pagerView
{
    return [_images count];
}

@end
