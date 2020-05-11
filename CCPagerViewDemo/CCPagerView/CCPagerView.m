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

@property (nonatomic, strong) UICollectionView *mainView; // 显示图片的collectionView
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, assign) NSUInteger realNumberOfCells;
@property (nonatomic, assign) BOOL numberOfCellHasChanged;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, assign) NSInteger totalItemsCount;
@property (nonatomic, strong) CCPageControl *pageControl;
@property (nonatomic, strong) UIImageView *backgroundImageView; // 当imageURLs为空时的背景图
@property (nonatomic, assign) BOOL isLoaded;
// 只有当进入后台的时候原来是开启定时器的，回前台才需要再开启
@property (nonatomic, assign) BOOL isTimerValidWhenEnterBackground;

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
    _autoScrollTimeInterval = 3.0;
    _autoScroll = YES;
    _infiniteLoop = YES;
    _showPageControl = YES;
    _pageControlDotSize = CGSizeMake(4, 4);
    _hidesForSinglePage = YES;
    _currentPageDotColor = [UIColor whiteColor];
    _pageDotColor = [UIColor lightGrayColor];
    _isLoaded = NO;
    _stopTimerBecomeBackground = YES;
    self.backgroundColor = [UIColor lightGrayColor];
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUpNotifications
{
    if (!_stopTimerBecomeBackground) {
        return;
    }
    [self removeNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUIApplicationWillEnterForegroundNotification)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUIApplicationDidEnterBackgroundNotification)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)onUIApplicationWillEnterForegroundNotification
{
//    [self log:@"enter foreground"];
    if (self.isTimerValidWhenEnterBackground) { // 进入前台，不能随便开启定时器，必须要满足 进入后台的时候定时器在跑
        [self notifyDelegateExpose:@"enterBackground"];
        [self startAutoScroll];
    }
}

- (void)onUIApplicationDidEnterBackgroundNotification
{
//    [self log:@"enter background"];
    self.isTimerValidWhenEnterBackground = _timer;
    [self stopAutoScroll];
}

+ (instancetype)pagerView
{
    return [self pagerViewWithFrame:CGRectZero placeholderImage:[UIImage imageNamed:@"live_banner_placeholder"]];
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
        self.backgroundImageView.frame = self.bounds;
    }
    
    self.backgroundImageView.image = placeholderImage;
}

- (void)setShowPageControl:(BOOL)showPageControl
{
    _showPageControl = showPageControl;
    _pageControl.hidden = !showPageControl;
}

- (void)setCurrentPageDotColor:(UIColor *)currentPageDotColor
{
    _currentPageDotColor = currentPageDotColor;
    _pageControl.currentPageIndicatorTintColor = currentPageDotColor;
}

- (void)setDisableScrollGesture:(BOOL)disableScrollGesture
{
    _disableScrollGesture = disableScrollGesture;
    self.mainView.panGestureRecognizer.enabled = !disableScrollGesture;
}

- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment
{
    _contentVerticalAlignment = contentVerticalAlignment;
    _pageControl.contentVerticalAlignment = contentVerticalAlignment;
}

- (void)setContentHorizontalAlignment:(UIControlContentHorizontalAlignment)contentHorizontalAlignment
{
    _contentHorizontalAlignment = contentHorizontalAlignment;
    _pageControl.contentHorizontalAlignment = contentHorizontalAlignment;
}

- (void)setStopTimerBecomeBackground:(BOOL)stopTimerBecomeBackground
{
    if (stopTimerBecomeBackground && [self enableAutoScroll]) {
        [self setUpNotifications];
    } else {
        [self removeNotifications];
    }
    _stopTimerBecomeBackground = stopTimerBecomeBackground;
}

- (void)setPageDotColor:(UIColor *)pageDotColor
{
    _pageDotColor = pageDotColor;
    _pageControl.pageIndicatorTintColor = pageDotColor;
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    _scrollDirection = scrollDirection;
    
    _flowLayout.scrollDirection = scrollDirection;
}

- (void)_reloadData
{
    if (_isLoaded) {
        return;
    }
    
    _isLoaded = YES;
    // dataSource
    NSUInteger oldRealNumberOfCells = _realNumberOfCells;
    if (_delegate && [_delegate respondsToSelector:@selector(numberOfPagerViewCell:)]) {
        _realNumberOfCells = [_delegate numberOfPagerViewCell:self];
    }
    _numberOfCellHasChanged = (oldRealNumberOfCells != _realNumberOfCells);
    _numberOfCellHasChanged = YES; // reload need all refresh.
    _totalItemsCount = self.infiniteLoop ? self.realNumberOfCells * kCellRepeatRatio : self.realNumberOfCells;
    
    // pageControl
    if ((_realNumberOfCells == 1 && !_hidesForSinglePage) || _realNumberOfCells > 1) {
        self.pageControl.hidden = NO;
        self.pageControl.numberOfPages = _realNumberOfCells;
    } else {
        self.pageControl.hidden = YES;
    }
    
    // mainView
    [self.mainView reloadData];
    // expose
    [self notifyDelegateExpose:@"reload"];
    
    // scrollEnable
    if ([self enableAutoScroll]) {
       self.mainView.scrollEnabled = YES;
    } else {
       self.mainView.scrollEnabled = NO;
    }
    
    // observe
    if ([self enableAutoScroll]) {
        [self setUpNotifications];
    }
}

- (BOOL)enableAutoScroll
{
    return self.realNumberOfCells > 1 && self.autoScroll;
}

- (void)restoreInitOffsetIfNeed
{
    // 只有初始化的时候，需要调整offset
    if (_realNumberOfCells > 1 && (self.mainView.contentOffset.x == 0 || _numberOfCellHasChanged)) {
        _numberOfCellHasChanged = NO;
        int targetIndex = 0;
        if (self.infiniteLoop) {
            targetIndex = _totalItemsCount * 0.5;
        } else {
            targetIndex = 0;
        }
//        [self log:@"resotreInitOffset:%@", @(targetIndex)];
        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                         atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self updatePageControlIndicatorPosition];
    }
}

#pragma mark - actions

- (void)setupTimer
{
    [self log:@"start Timer"];
    [self invalidateTimer]; // 创建定时器前先停止定时器，不然会出现僵尸定时器，导致轮播频率错误
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollTimeInterval target:self
                                                    selector:@selector(automaticScroll) userInfo:nil repeats:YES];
    _timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateTimer
{
    if (_timer) {
        [self log:@"invalid timer."];
        [_timer invalidate];
        _timer = nil;
    }
}

- (CCPageControl *)pageControl
{
    if (!_pageControl) {
        CCPageControl *pageControl = [[CCPageControl alloc] init];
        pageControl.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        pageControl.numberOfPages = 0;
        pageControl.currentPage = 0;
        pageControl.currentPageIndicatorSize = self.pageControlDotSize;
        pageControl.pageIndicatorSize = self.pageControlDotSize;
        [self addSubview:pageControl];
        _pageControl = pageControl;
    }
    return _pageControl;
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
            [self updatePageControlIndicatorPosition];
        }
        return;
    }
    [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                      atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

- (void)centerOfVisibleAreaAsFar
{
    if (!self.infiniteLoop) {
        return;
    }
// Example kCellRepeatRatio:10, realCnt:3
// ▶️：表示当前显示在屏幕中的cell
// pos:  0   1   2   3   4  .5   6   7   8   9
//      xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
// 假设当前显示在，如下位置：
//                                      ▶️
// 调整到中央位置，如下位置：
//                          ▶️
// 尽量降低触及到边界的可能性，如果不加这个处理 当前pagerView如果快速滑动的次数超过realCnt * kCellRepeatRatio * 0.5
// 则会出现不能滑动情况
    
    NSUInteger targetIndex = _totalItemsCount * 0.5 + self.currentPageControlIndex;
    if (targetIndex != [self currentIndex]) {
        [self log:@"centerVisibleAreaAsFar %@ to %@", @([self currentIndex]), @(targetIndex)];
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
    if (self.realNumberOfCells == 0) {
        [self log:@"warings, realNumberOfCelss is 0"];
        return 0;
    }
    return (int)index % self.realNumberOfCells;
}

#pragma mark - life circles
//解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self invalidateTimer];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self restoreInitOffsetIfNeed];
    // 设置frame
    [self layout];
}

- (void)layout
{
    _flowLayout.itemSize = self.frame.size;
    _mainView.frame = self.bounds;
    // pageControl frame
    CGFloat x = 6;
    CGFloat h = 12;
    CGFloat y = self.ccp_height - h;
    CGFloat w = self.ccp_width - 2 * x;
    CGRect rect = CGRectMake(x, y, w, h);
    _pageControl.frame = rect;
}

//解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
- (void)dealloc
{
    [self removeNotifications];
    _mainView.delegate = nil;
    _mainView.dataSource = nil;
}

#pragma mark - public actions
- (void)setNeedForceLayout
{
//    [self log:@"setNeedForceLayout"];
    _isLoaded = NO; // 标记成未加载状态
    [self setNeedsLayout];
}

- (void)reloadDataAndStartScroll
{
    [self reloadData];
    [self startAutoScroll];
}

- (void)reloadData
{
    [self _reloadData];
}

- (void)startAutoScroll
{
    if ([self enableAutoScroll]) {
        [self invalidateTimer];
        [self setupTimer];
    }
}

- (void)stopAutoScroll
{
    if ([self enableAutoScroll]) {
        [self invalidateTimer];
        [self centerOfVisibleAreaAsFar]; // 尽可能的将当前显示的区域调整到中央
    }
}

- (void)pagerViewDidAppear
{
    if (_isLoaded) {
        [self notifyDelegateExpose:@"pageAppear"];
    }
}

- (void)pagerViewDidDisappear
{
    
}

- (void)makeScrollViewScrollToIndex:(NSInteger)index
{
    if ([self enableAutoScroll]) {
        [self invalidateTimer];
    }
    if (0 == _totalItemsCount) {
         return;
    }
    
    [self scrollToIndex:(int)(_totalItemsCount * 0.5 + index)];
    
    if ([self enableAutoScroll]) {
        [self setupTimer];
    }
}

- (void)adjustWhenControllerViewWillAppear
{
    long targetIndex = [self currentIndex];
    if (targetIndex < _totalItemsCount) {
        [_mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                          atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self updatePageControlIndicatorPosition];
    }
}

- (BOOL)isDragging
{
    return _mainView.dragging;
}

- (BOOL)isDecelerating
{
    return _mainView.decelerating;
}

- (NSUInteger)currentPageControlIndex
{
    return [self pageControlIndexWithCurrentCellIndex:[self currentIndex]];
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
    
    if ([self.delegate respondsToSelector:@selector(configPagerViewCell:forIndex:pagerView:)] &&
        [self.delegate respondsToSelector:@selector(pagerViewCellClass:)] && [self.delegate pagerViewCellClass:self]) {
        [self.delegate configPagerViewCell:cell forIndex:itemIndex pagerView:self];
        return cell;
    } else if ([self.delegate respondsToSelector:@selector(configPagerViewCell:forIndex:pagerView:)] &&
              [self.delegate respondsToSelector:@selector(pagerViewCellNib:)] && [self.delegate pagerViewCellNib:self]) {
        [self.delegate configPagerViewCell:cell forIndex:itemIndex pagerView:self];
        return cell;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self notifyDelegateClick];
}


#pragma mark - UIScrollViewDelegate

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    if (![self enableAutoScroll]) {
//         return;
//    }
//    [self updatePageControlIndicatorPosition];
//}

- (void)updatePageControlIndicatorPosition
{
    NSUInteger indexOnPageControl = self.currentPageControlIndex;
    _pageControl.currentPage = indexOnPageControl;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self enableAutoScroll]) {
        [self invalidateTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self enableAutoScroll]) {
        [self setupTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDidEndScrollingAnimation:self.mainView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (![self enableAutoScroll]) {
         return;
    }
    [self updatePageControlIndicatorPosition];
    [self notifyDelegateExpose:@"es"];
}

#pragma mark - Communicate With Delegate

- (void)notifyDelegateClick
{
    NSUInteger indexOnPageControl = self.currentPageControlIndex;

    if ([self.delegate respondsToSelector:@selector(pagerView:didSelectItemAtIndex:)]) {
        [self.delegate pagerView:self didSelectItemAtIndex:indexOnPageControl];
    }
    if (self.selectBlock) {
        self.selectBlock(indexOnPageControl);
    }
}

- (void)notifyDelegateExpose:(NSString *)from
{
    NSUInteger indexOnPageControl = self.currentPageControlIndex;
    
    [self log:@"appear at:%@ from:%@", @(indexOnPageControl), from];

    if ([self.delegate respondsToSelector:@selector(pagerView:didAppearAtIndex:)]) {
       [self.delegate pagerView:self didAppearAtIndex:indexOnPageControl];
    } else if (self.appearBlock) {
       self.appearBlock(indexOnPageControl);
    }
}

- (void)log:(NSString *)format, ...
{
#ifdef DEBUG
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSLog(@"[CCPagerView] - %p: %@", self, msg);
#endif
}

@end
