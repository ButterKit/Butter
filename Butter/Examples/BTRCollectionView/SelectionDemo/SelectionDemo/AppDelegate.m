//
//  AppDelegate.m
//  SelectionDemo
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//  Images used are from PSTCollectionView
//

#import "AppDelegate.h"
#import <Butter/RBLScrollView.h>
#import "Cell.h"

@interface AppDelegate()
@property (nonatomic, strong) BTRCollectionView *collectionView;
@end

@implementation AppDelegate

- (void)awakeFromNib {
	NSView *view = [self.window contentView];
	RBLScrollView *scrollView = [[RBLScrollView alloc] initWithFrame:view.bounds];
	scrollView.hasHorizontalScroller = NO;
    scrollView.hasVerticalScroller = YES;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	
	BTRCollectionViewFlowLayout *flowLayout = [[BTRCollectionViewFlowLayout alloc] init];
#warning setting item size here is temporary until the delegate methods are fixed
	flowLayout.itemSize = CGSizeMake(180, 140);
    self.collectionView = [[BTRCollectionView alloc] initWithFrame:scrollView.bounds collectionViewLayout:flowLayout];
    self.collectionView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:@"MY_CELL"];
	[self.collectionView setDataSource:self];
	[self.collectionView setDelegate:self];
	scrollView.documentView = _collectionView;
	[view addSubview:scrollView];
}

- (BTRCollectionViewCell *)collectionView:(BTRCollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Cell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"MY_CELL" forIndexPath:indexPath];
    
	cell.label.stringValue = [NSString stringWithFormat:@"{%ld,%ld}", (long)indexPath.row, (long)indexPath.section];
	cell.layer.contents = [NSImage imageNamed:[NSString stringWithFormat:@"%d",(arc4random() % (32))]];
	
    return cell;
}

- (CGSize)collectionView:(BTRCollectionViewCell *)collectionView layout:(BTRCollectionViewCell *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"%s",__PRETTY_FUNCTION__); // not called
    return CGSizeMake(1000, 1000); //CGSizeMake(130, 180);
}

- (NSInteger)collectionView:(BTRCollectionViewCell *)view numberOfItemsInSection:(NSInteger)section {
    return 1000;
}

@end
