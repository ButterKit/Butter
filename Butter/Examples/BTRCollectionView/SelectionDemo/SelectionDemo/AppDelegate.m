//
//  AppDelegate.m
//  SelectionDemo
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//  Images used are from PSTCollectionView
//

#import "AppDelegate.h"
#import <Butter/BTRScrollView.h>
#import <Butter/NSView+BTRAdditions.h>
#import "Cell.h"

@interface AppDelegate()
@property (nonatomic, strong) BTRCollectionView *collectionView;
@end

@implementation AppDelegate

- (void)awakeFromNib {
	NSView *view = [self.window contentView];
	BTRScrollView *scrollView = [[BTRScrollView alloc] initWithFrame:view.bounds];
	scrollView.hasHorizontalScroller = NO;
    scrollView.hasVerticalScroller = YES;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	
	BTRCollectionViewFlowLayout *flowLayout = [[BTRCollectionViewFlowLayout alloc] init];
    self.collectionView = [[BTRCollectionView alloc] initWithFrame:scrollView.bounds collectionViewLayout:flowLayout];
    self.collectionView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	self.collectionView.allowsMultipleSelection = YES;
	self.collectionView.animatesSelection = YES;
	[self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:@"MY_CELL"];
	[self.collectionView setDataSource:self];
	[self.collectionView setDelegate:self];
	scrollView.documentView = _collectionView;
	[view addSubview:scrollView];
}

- (BTRCollectionViewCell *)collectionView:(BTRCollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Cell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"MY_CELL" forIndexPath:indexPath];
    
	cell.label.stringValue = [NSString stringWithFormat:@"{%ld,%ld}", (long)indexPath.row, (long)indexPath.section];
	//cell.contentView.layer.contents = [NSImage imageNamed:[NSString stringWithFormat:@"%d",(arc4random() % (32))]];
	cell.imageView.image = [NSImage imageNamed:[NSString stringWithFormat:@"%d",(arc4random() % (32))]];
	
    return cell;
}

- (CGSize)collectionView:(BTRCollectionViewCell *)collectionView layout:(BTRCollectionViewCell *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(180, 140);
}

- (NSUInteger)collectionView:(BTRCollectionViewCell *)view numberOfItemsInSection:(NSUInteger)section {
    return 5000;
}

- (BOOL)collectionView:(BTRCollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)collectionView:(BTRCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	[collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:BTRCollectionViewScrollPositionCenteredVertically animated:YES];
}

- (void)collectionView:(BTRCollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	BTRCollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
	[NSView btr_animateWithDuration:0.1 animationCurve:BTRViewAnimationCurveEaseInOut animations:^{
		cell.layer.transform = CATransform3DConcat(CATransform3DMakeScale(0.9, 0.9, 0.0), CATransform3DMakeTranslation(9, 9, 0));
	} completion:^{
		[NSView btr_animateWithDuration:0.2 animationCurve:BTRViewAnimationCurveEaseOut animations:^{
			cell.layer.transform = CATransform3DIdentity;
		} completion:NULL];
	}];
}

- (void)collectionView:(BTRCollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	
}

@end
