//
//  CCPagerView.h
//  CCPagerView
//
//  Created by pcc on 2020/4/13.
//  Copyright © 2020 pcc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CCPagerView;

@protocol CCPagerViewDelegate <NSObject>

- (void)configPagerViewCell:(UICollectionViewCell *)cell forIndex:(NSInteger)index pagerView:(CCPagerView *)pagerView;
- (NSUInteger)numberOfPagerViewCell:(CCPagerView *)pagerView;

@optional
// 以下两个方法必须要实现一个
- (Class)pagerViewCellClass:(CCPagerView *)pagerView;
- (UINib *)pagerViewCellNib:(CCPagerView *)pagerView;

/** 点击图片回调 */
- (void)pagerView:(CCPagerView *)pagerView didSelectItemAtIndex:(NSInteger)index;
/** 图片滚动回调 */
- (void)pagerView:(CCPagerView *)pagerView didAppearAtIndex:(NSInteger)index;

@end

@interface CCPagerView : UIView


@property (nonatomic, weak) id <CCPagerViewDelegate> delegate;

#pragma mark - 滚动控制
// 自动滚动间隔时间,默认3s
@property (nonatomic, assign) CGFloat autoScrollTimeInterval;

// 是否无限循环,默认YES
@property (nonatomic,assign) BOOL infiniteLoop;

// 是否自动滚动，默认YES
@property (nonatomic,assign) BOOL autoScroll;

// 图片滚动方向，默认为水平滚动
@property (nonatomic, assign) UICollectionViewScrollDirection scrollDirection;

// block方式监听点击
@property (nonatomic, copy) void (^selectBlock)(NSInteger index);

// block方式监听滚动
@property (nonatomic, copy) void (^appearBlock)(NSInteger index);

// 是否禁用滑动手势，默认NO
@property (nonatomic, assign) BOOL disableScrollGesture;

// 是否开启到后台停止定时器，默认NO
@property (nonatomic, assign) BOOL stopTimerBecomeBackground;

#pragma mark - 自定义样式
// 占位图，用于网络未加载到图片时
@property (nonatomic, strong) UIImage *placeholderImage;

// 是否显示分页控件
@property (nonatomic, assign) BOOL showPageControl;

// 是否在只有一张图时隐藏pagecontrol，默认为YES
@property(nonatomic) BOOL hidesForSinglePage;

// 分页控件位置
@property(nonatomic, assign) UIControlContentVerticalAlignment contentVerticalAlignment;
@property(nonatomic, assign) UIControlContentHorizontalAlignment contentHorizontalAlignment;

// 分页控件小圆标大小
@property (nonatomic, assign) CGSize pageControlDotSize;

// 当前分页控件小圆标颜色
@property (nonatomic, strong) UIColor *currentPageDotColor;

// 其他分页控件小圆标颜色
@property (nonatomic, strong) UIColor *pageDotColor;

// 是否正在拖拽
@property (nonatomic, assign) BOOL isDragging;

// 是否正在减速
@property (nonatomic, assign) BOOL isDecelerating;

// 当前选中的index
@property (nonatomic, assign) NSUInteger currentPageControlIndex;

#pragma mark - Init
// 初始轮播图（推荐使用）
+ (instancetype)pagerView;
+ (instancetype)pagerViewWithFrame:(CGRect)frame placeholderImage:(UIImage *)placeholderImage;

#pragma mark - Others
// 设置后，再次调用reload会强制刷新
- (void)setNeedForceLayout;
// 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法
- (void)adjustWhenControllerViewWillAppear;

#pragma mark - Load & Scroll

// 刷新界面，开启定时器，一般情况下使用该方式
- (void)reloadDataAndStartScroll;

// 刷新界面，不开启定时器，一般预加载的时候，可以先调用该方法加载出来
// 后面等真正出现在屏幕时再调用startAutoScroll开启定时器
- (void)reloadData;
// 开启定时器
- (void)startAutoScroll;
// 停止定时器
- (void)stopAutoScroll;

- (void)pagerViewDidAppear;
- (void)pagerViewDidDisappear;

// 可以调用此方法手动控制滚动到哪一个index
- (void)makeScrollViewScrollToIndex:(NSInteger)index;

@end
