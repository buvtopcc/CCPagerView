//
//  ViewController.m
//  CCPagerViewDemo
//
//  Created by pcc on 2020/4/14.
//  Copyright © 2020 pcc. All rights reserved.
//

#import "ViewController.h"
#import "CCPagerView.h"
#import "CustomCell.h"
#import "pagerViewContainerCollectionView.h"

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    self.title = @"CCPagerView Demo";
    
    [self initCollectionView];
}

- (void)initCollectionView
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 10;
    layout.itemSize = CGSizeMake(CGRectGetWidth(self.view.bounds), 80);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                                          collectionViewLayout:layout];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [collectionView registerClass:[pagerViewContainerCollectionView class] forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:collectionView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 如果你发现你的CycleScrollview会在viewWillAppear时图片卡在中间位置，你可以调用此方法调整图片位置
//    [你的CycleScrollview adjustWhenControllerViewWillAppear];
}

#pragma mark - UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 12;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    pagerViewContainerCollectionView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
                                                                                       forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.images = @[@"1", @"2", @"3", @"4"];
    } else {
        cell.images = @[];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [(pagerViewContainerCollectionView*)cell setIsStartAutoScroll:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [(pagerViewContainerCollectionView*)cell setIsStartAutoScroll:NO];
}

@end

