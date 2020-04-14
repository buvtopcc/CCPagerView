//
//  CCPagerView.h
//  CCPagerView
//
//  Created by pcc on 2020/4/13.
//  Copyright © 2020 pcc. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, CCPagerViewControlAligment)
{
    CCPagerViewControlAligmentLeft = 1,             // Default
    CCPagerViewControlAligmentRight = 2,
    CCPagerViewControlAligmentCenter = 3
};

typedef NS_ENUM(NSUInteger, CCPagerViewControlStyle)
{
    CCPagerViewControlStyleClassic = 1,            // Default
    CCPagerViewControlStyleCustom = 2,
    CCPagerViewControlStyleNone = 3
};

@class CCPagerView;

@protocol CCPagerViewDelegate <NSObject>

@optional
/** 点击图片回调 */
- (void)pagerView:(CCPagerView *)pagerView didSelectItemAtIndex:(NSInteger)index;

/** 图片滚动回调 */
- (void)pagerView:(CCPagerView *)pagerView didAppearAtIndex:(NSInteger)index;

// 不需要自定义轮播cell的请忽略以下两个的代理方法

// ========== 自定义cell ==========
/** 自定义class */
- (Class)customCollectionViewCellClassForPagerView:(CCPagerView *)view;
/** 自定义nib */
- (UINib *)customCollectionViewCellNibForPagerView:(CCPagerView *)view;
/** 用数据填充自定义cell */
- (void)configCustomCell:(UICollectionViewCell *)cell forIndex:(NSInteger)index pagerView:(CCPagerView *)view;

@end

@interface CCPagerView : UIView


@property (nonatomic, weak) id <CCPagerViewDelegate> delegate;

//////////////////////  数据源API //////////////////////
///
/** 网络图片 url string 数组 */
@property (nonatomic, strong) NSArray *imageURLStringsGroup;

/** 每张图片对应要显示的文字数组 */
@property (nonatomic, strong) NSArray *titlesGroup;

/** 本地图片数组 */
@property (nonatomic, strong) NSArray *localizationImageNamesGroup;


//////////////////////  滚动控制API //////////////////////
///
/** 自动滚动间隔时间,默认3s */
@property (nonatomic, assign) CGFloat autoScrollTimeInterval;

/** 是否无限循环,默认Yes */
@property (nonatomic,assign) BOOL infiniteLoop;

/** 是否自动滚动,默认Yes */
@property (nonatomic,assign) BOOL autoScroll;

/** 图片滚动方向，默认为水平滚动 */
@property (nonatomic, assign) UICollectionViewScrollDirection scrollDirection;

/** block方式监听点击 */
@property (nonatomic, copy) void (^clickItemOperationBlock)(NSInteger currentIndex);

/** block方式监听滚动 */
@property (nonatomic, copy) void (^itemDidScrollOperationBlock)(NSInteger currentIndex);

//////////////////////  自定义样式API  //////////////////////

/** 轮播图片的ContentMode，默认为 UIViewContentModeScaleToFill */
@property (nonatomic, assign) UIViewContentMode bannerImageViewContentMode;

/** 占位图，用于网络未加载到图片时 */
@property (nonatomic, strong) UIImage *placeholderImage;

/** 是否显示分页控件 */
@property (nonatomic, assign) BOOL showPageControl;

/** 是否在只有一张图时隐藏pagecontrol，默认为YES */
@property(nonatomic) BOOL hidesForSinglePage;

/** 只展示文字轮播 */
@property (nonatomic, assign) BOOL onlyDisplayText;

/** pagecontrol 样式，默认为动画样式 */
@property (nonatomic, assign) CCPagerViewControlStyle pageControlStyle;

/** 分页控件位置 */
@property (nonatomic, assign) CCPagerViewControlAligment pageControlAligment;

/** 分页控件小圆标大小 */
@property (nonatomic, assign) CGSize pageControlDotSize;

/** 当前分页控件小圆标颜色 */
@property (nonatomic, strong) UIColor *currentPageDotColor;

/** 其他分页控件小圆标颜色 */
@property (nonatomic, strong) UIColor *pageDotColor;

/** 当前分页控件小圆标图片 */
@property (nonatomic, strong) UIImage *currentPageDotImage;

/** 其他分页控件小圆标图片 */
@property (nonatomic, strong) UIImage *pageDotImage;

/** 轮播文字label字体颜色 */
@property (nonatomic, strong) UIColor *titleLabelTextColor;

/** 轮播文字label字体大小 */
@property (nonatomic, strong) UIFont  *titleLabelTextFont;

/** 轮播文字label背景颜色 */
@property (nonatomic, strong) UIColor *titleLabelBackgroundColor;

/** 轮播文字label高度 */
@property (nonatomic, assign) CGFloat titleLabelHeight;

/** 轮播文字label对齐方式 */
@property (nonatomic, assign) NSTextAlignment titleLabelTextAlignment;



// 初始轮播图（推荐使用）
+ (instancetype)pagerViewWithFrame:(CGRect)frame placeholderImage:(UIImage *)placeholderImage;

/** 可以调用此方法手动控制滚动到哪一个index */
- (void)makeScrollViewScrollToIndex:(NSInteger)index;

/** 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法 */
- (void)adjustWhenControllerViewWillAppear;
/** 滚动手势禁用（文字轮播较实用） */
- (void)disableScrollGesture;

@end
