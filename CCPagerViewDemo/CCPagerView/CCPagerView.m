//
//  CCPagerView.m
//  CCPagerView
//
//  Created by pcc on 2020/4/13.
//  Copyright © 2020 pcc. All rights reserved.
//

#import "CCPagerView.h"
#import "CCPageControl.h"

// 重复的倍数（必须为偶数，才能够使初始设定0.5 * totolItemsCount在第一个cell上）
static NSUInteger const kCellRepeatRatio = 1000;
static NSString * const kCellReuseIndentifier = @"CCPagerViewCell";

@interface UIView (CCPagerExt)

- (CGFloat)ccp_width;
- (CGFloat)ccp_height;

@end

@implementation UIView (CCPagerExt)

- (CGFloat)ccp_width
{
    return CGRectGetWidth(self.bounds);
}

- (CGFloat)ccp_height
{
    return CGRectGetHeight(self.bounds);
}

@end

@interface CCPagerView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) UICollectionView *mainView; // 显示图片的collectionView
@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, assign) NSUInteger realNumberOfCells;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, assign) NSInteger totalItemsCount;
@property (nonatomic, weak) UIControl *pageControl;

@property (nonatomic, strong) UIImageView *backgroundImageView; // 当imageURLs为空时的背景图

@end

@implementation CCPagerView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
        [self setupMainView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initialization];
    [self setupMainView];
}

- (void)initialization
{
    _pageControlAligment = CCPagerViewControlAligmentLeft;
    _autoScrollTimeInterval = 3.0;
    _autoScroll = YES;
    _infiniteLoop = YES;
    _showPageControl = YES;
    _pageControlDotSize = CGSizeMake(4, 4);
    _pageControlStyle = CCPagerViewControlStyleCustom;
    _hidesForSinglePage = YES;
    _currentPageDotColor = [UIColor whiteColor];
    _pageDotColor = [UIColor lightGrayColor];
    self.backgroundColor = [UIColor lightGrayColor];
    
}

+ (instancetype)pagerViewWithFrame:(CGRect)frame placeholderImage:(UIImage *)placeholderImage
{
    CCPagerView *cycleScrollView = [[self alloc] initWithFrame:frame];
    cycleScrollView.placeholderImage = placeholderImage;
    return cycleScrollView;
}

// 设置显示图片的collectionView
- (void)setupMainView
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _flowLayout = flowLayout;
    
    UICollectionView *mainView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    mainView.backgroundColor = [UIColor clearColor];
    mainView.pagingEnabled = YES;
    mainView.showsHorizontalScrollIndicator = NO;
    mainView.showsVerticalScrollIndicator = NO;
    
    mainView.dataSource = self;
    mainView.delegate = self;
    mainView.scrollsToTop = NO;
    [self addSubview:mainView];
    _mainView = mainView;
}


#pragma mark - properties

- (void)setDelegate:(id<CCPagerViewDelegate>)delegate
{
    _delegate = delegate;
    if ([self.delegate respondsToSelector:@selector(pagerViewCellClass:)] &&
        [self.delegate pagerViewCellClass:self]) {
        [self.mainView registerClass:[self.delegate pagerViewCellClass:self]
          forCellWithReuseIdentifier:kCellReuseIndentifier];
    } else if ([self.delegate respondsToSelector:@selector(pagerViewCellNib:)] &&
              [self.delegate pagerViewCellNib:self]) {
        [self.mainView registerNib:[self.delegate pagerViewCellNib:self]
        forCellWithReuseIdentifier:kCellReuseIndentifier];
    }
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
    
    if (!self.backgroundImageView) {
        UIImageView *bgImageView = [UIImageView new];
        bgImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self insertSubview:bgImageView belowSubview:self.mainView];
        self.backgroundImageView = bgImageView;
    }
    
    self.backgroundImageView.image = placeholderImage;
}

- (void)setPageControlDotSize:(CGSize)pageControlDotSize
{
    _pageControlDotSize = pageControlDotSize;
    [self setupPageControl];
    if ([self.pageControl isKindOfClass:[CCPageControl class]]) {
        CCPageControl *pageContol = (CCPageControl *)_pageControl;
        pageContol.currentPageIndicatorSize = pageControlDotSize;
        pageContol.pageIndicatorSize = pageControlDotSize;
    }
}

- (void)setShowPageControl:(BOOL)showPageControl
{
    _showPageControl = showPageControl;
    
    _pageControl.hidden = !showPageControl;
}

- (void)setCurrentPageDotColor:(UIColor *)currentPageDotColor
{
    _currentPageDotColor = currentPageDotColor;
    if ([self.pageControl isKindOfClass:[CCPageControl class]]) {
        CCPageControl *pageControl = (CCPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = currentPageDotColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = currentPageDotColor;
    }
    
}

- (void)setPageDotColor:(UIColor *)pageDotColor
{
    _pageDotColor = pageDotColor;
    
    if ([self.pageControl isKindOfClass:[CCPageControl class]]) {
        CCPageControl *pageControl = (CCPageControl *)_pageControl;
        pageControl.pageIndicatorTintColor = pageDotColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.pageIndicatorTintColor = pageDotColor;
    }
}

- (void)setInfiniteLoop:(BOOL)infiniteLoop
{
    _infiniteLoop = infiniteLoop;
    
    if (self.realNumberOfCells) {
        [self reloadData];
    }
}

- (void)setAutoScroll:(BOOL)autoScroll
{
    _autoScroll = autoScroll;
    
    [self invalidateTimer];
    
    if (_autoScroll) {
        [self setupTimer];
    }
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    _scrollDirection = scrollDirection;
    
    _flowLayout.scrollDirection = scrollDirection;
}

- (void)setAutoScrollTimeInterval:(CGFloat)autoScrollTimeInterval
{
    _autoScrollTimeInterval = autoScrollTimeInterval;
    
    [self setAutoScroll:self.autoScroll];
}

- (void)setPageControlStyle:(CCPagerViewControlStyle)pageControlStyle
{
    _pageControlStyle = pageControlStyle;
    
    [self setupPageControl];
}

- (void)reloadData
{
    [self invalidateTimer];
    
    _realNumberOfCells = 0;
    if (_delegate && [_delegate respondsToSelector:@selector(numberOfPagerViewCell:)]) {
        _realNumberOfCells = [_delegate numberOfPagerViewCell:self];
    }
    
    _totalItemsCount = self.infiniteLoop ? self.realNumberOfCells * kCellRepeatRatio : self.realNumberOfCells;
    
    if (self.realNumberOfCells > 1) {
        self.mainView.scrollEnabled = YES;
        [self setAutoScroll:self.autoScroll];
    } else {
        self.mainView.scrollEnabled = NO;
        [self invalidateTimer];
    }
    
    [self setupPageControl];
    [self.mainView reloadData];
}

- (void)startAutoScroll
{
    if (!self.autoScroll) {
        self.autoScroll = YES;
    }
}

- (void)stopAutoScroll
{
    if (self.autoScroll) {
        self.autoScroll = NO;
        [self centerOfVisibleAreaAsFar]; // 尽可能的将当前显示的区域调整到中央
    }
}

- (void)disableScrollGesture
{
    self.mainView.canCancelContentTouches = NO;
    for (UIGestureRecognizer *gesture in self.mainView.gestureRecognizers) {
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            [self.mainView removeGestureRecognizer:gesture];
        }
    }
}

#pragma mark - actions

- (void)setupTimer
{
    [self invalidateTimer]; // 创建定时器前先停止定时器，不然会出现僵尸定时器，导致轮播频率错误
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollTimeInterval target:self
                                                    selector:@selector(automaticScroll) userInfo:nil repeats:YES];
    _timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (void)setupPageControl
{
    if (_pageControl) {
         [_pageControl removeFromSuperview];
    } // 重新加载数据时调整
    
    if (self.realNumberOfCells == 0) {
         return;
    }
    
    if ((self.realNumberOfCells == 1) && self.hidesForSinglePage) {
         return;
    }
    
    int indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:[self currentIndex]];
    
    switch (self.pageControlStyle) {
        case CCPagerViewControlStyleCustom: {
            CCPageControl *pageControl = [[CCPageControl alloc] init];
            pageControl.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            pageControl.numberOfPages = self.realNumberOfCells;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        case CCPagerViewControlStyleClassic: {
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            pageControl.numberOfPages = self.realNumberOfCells;
            pageControl.currentPageIndicatorTintColor = self.currentPageDotColor;
            pageControl.pageIndicatorTintColor = self.pageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        default:
            break;
    }
}


- (void)automaticScroll
{
    if (0 == _totalItemsCount) {
         return;
    }
    int currentIndex = [self currentIndex];
    int targetIndex = currentIndex + 1;
    [self scrollToIndex:targetIndex];
}

- (void)scrollToIndex:(int)targetIndex
{
    /// Example repeat:10, realCnt:3, init ⬆️ pos at .
    ///  0   1   2   3   4  .5   6   7   8   9
    /// xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
    if (targetIndex >= _totalItemsCount) {
        if (self.infiniteLoop) {
            targetIndex = _totalItemsCount * 0.5;
            [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                              atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
        return;
    }
    [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                      atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

- (void)centerOfVisibleAreaAsFar
{
// Example kCellRepeatRatio:10, realCnt:3
// ▶️：表示当前显示在屏幕中的cell
// pos:  0   1   2   3   4  .5   6   7   8   9
//      xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
//                                      ▶️
// 作用：将当前显示在屏幕中的cell，调整到中央位置，如下位置：
//                          ▶️
// 尽量降低触及到边界的可能性，如果不加这个处理
// 当前pagerView如果手动滑动的次数超过realCnt * kCellRepeatRatio * 0.5次，则会出现不能滑动情况
    
    NSUInteger targetIndex = _totalItemsCount * 0.5 + [self pageControlIndexWithCurrentCellIndex:[self currentIndex]];
    if (targetIndex != [self currentIndex]) {
        NSLog(@"centerVisibleAreaAsFar %@ to %@", @([self currentIndex]), @(targetIndex));
        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                                 atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self updatePageControlIndicatorPosition];
    }
}

- (int)currentIndex
{
    if (_mainView.ccp_width == 0 || _mainView.ccp_height == 0) {
        return 0;
    }
    
    int index = 0;
    if (_flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        index = (_mainView.contentOffset.x + _flowLayout.itemSize.width * 0.5) / _flowLayout.itemSize.width;
    } else {
        index = (_mainView.contentOffset.y + _flowLayout.itemSize.height * 0.5) / _flowLayout.itemSize.height;
    }
    
    return MAX(0, index);
}

- (int)pageControlIndexWithCurrentCellIndex:(NSInteger)index
{
    return (int)index % self.realNumberOfCells;
}

#pragma mark - life circles

- (void)layoutSubviews
{
    self.delegate = self.delegate;
    
    [super layoutSubviews];
    
    _flowLayout.itemSize = self.frame.size;
    
    _mainView.frame = self.bounds;
    if (_mainView.contentOffset.x == 0 &&  _totalItemsCount) { // xxx xxx xxx xxx
        int targetIndex = 0;
        if (self.infiniteLoop) {
            targetIndex = _totalItemsCount * 0.5;
        } else {
            targetIndex = 0;
        }
        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                          atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
    
    CGSize size = CGSizeZero;
    if ([self.pageControl isKindOfClass:[CCPageControl class]]) {
        size = CGSizeMake(self.ccp_width - 2 * 6, 12);
    } else {
        size = CGSizeMake(self.realNumberOfCells * self.pageControlDotSize.width * 1.5,
                          self.pageControlDotSize.height);
    }
    CGFloat x;
    if (self.pageControlAligment == CCPagerViewControlAligmentRight) {
        x = self.mainView.ccp_width - size.width - 6;
    } else if (self.pageControlAligment == CCPagerViewControlAligmentLeft) {
        x = 6;
    } else {
        x = (self.ccp_width - size.width) * 0.5;
    }
    CGFloat y = self.mainView.ccp_height - size.height;
    
    CGRect pageControlFrame = CGRectMake(x, y, size.width, size.height);
    self.pageControl.frame = pageControlFrame;
    self.pageControl.hidden = !_showPageControl;
    
    if (self.backgroundImageView) {
        self.backgroundImageView.frame = self.bounds;
    }
    
}

//解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self invalidateTimer];
    }
}

//解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
- (void)dealloc
{
    _mainView.delegate = nil;
    _mainView.dataSource = nil;
}

#pragma mark - public actions

- (void)adjustWhenControllerViewWillAppear
{
    long targetIndex = [self currentIndex];
    if (targetIndex < _totalItemsCount) {
        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                          atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _totalItemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:
                                    kCellReuseIndentifier forIndexPath:indexPath];
    
    long itemIndex = [self pageControlIndexWithCurrentCellIndex:indexPath.item];
    
    if ([self.delegate respondsToSelector:@selector(configCell:forIndex:pagerView:)] &&
        [self.delegate respondsToSelector:@selector(pagerViewCellClass:)] && [self.delegate pagerViewCellClass:self]) {
        [self.delegate configCell:cell forIndex:itemIndex pagerView:self];
        return cell;
    } else if ([self.delegate respondsToSelector:@selector(configCell:forIndex:pagerView:)] &&
              [self.delegate respondsToSelector:@selector(pagerViewCellNib:)] && [self.delegate pagerViewCellNib:self]) {
        [self.delegate configCell:cell forIndex:itemIndex pagerView:self];
        return cell;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(pagerView:didSelectItemAtIndex:)]) {
        [self.delegate pagerView:self didSelectItemAtIndex:[self pageControlIndexWithCurrentCellIndex:indexPath.item]];
    }
    if (self.clickItemOperationBlock) {
        self.clickItemOperationBlock([self pageControlIndexWithCurrentCellIndex:indexPath.item]);
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.realNumberOfCells) {
         return;
    }
    // 解决清除timer时偶尔会出现的问题
    [self updatePageControlIndicatorPosition];
}

- (void)updatePageControlIndicatorPosition
{
    int itemIndex = [self currentIndex];
    int indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:itemIndex];
       
    if ([self.pageControl isKindOfClass:[CCPageControl class]]) {
        CCPageControl *pageControl = (CCPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.autoScroll) {
        [self invalidateTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.autoScroll) {
        [self setupTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDidEndScrollingAnimation:self.mainView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (!self.realNumberOfCells) {
         return;
    } // 解决清除timer时偶尔会出现的问题
    int itemIndex = [self currentIndex];
    int indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if ([self.delegate respondsToSelector:@selector(pagerView:didAppearAtIndex:)]) {
        [self.delegate pagerView:self didAppearAtIndex:indexOnPageControl];
    } else if (self.itemDidScrollOperationBlock) {
        self.itemDidScrollOperationBlock(indexOnPageControl);
    }
}

- (void)makeScrollViewScrollToIndex:(NSInteger)index
{
    if (self.autoScroll) {
        [self invalidateTimer];
    }
    if (0 == _totalItemsCount) {
         return;
    }
    
    [self scrollToIndex:(int)(_totalItemsCount * 0.5 + index)];
    
    if (self.autoScroll) {
        [self setupTimer];
    }
}


@end
