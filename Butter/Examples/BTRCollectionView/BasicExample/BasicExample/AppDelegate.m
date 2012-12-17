//
//  AppDelegate.m
//  BasicExample
//
//  Created by Indragie Karunaratne and Jonathan Willing on 2012-12-06.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "AppDelegate.h"
#import "CollectionViewCell.h"
#import "HeaderView.h"
#import "FooterView.h"

#import <Butter/BTRScrollView.h>

@interface AppDelegate()
@property (strong, nonatomic) BTRCollectionView *collectionView;
@property (strong, nonatomic) NSArray *data;
@end

@implementation AppDelegate

static NSString *cellIdentifier = @"TestCell";
static NSString *headerViewIdentifier = @"Test Header View";
static NSString *footerViewIdentifier = @"Test Footer View";

- (void)awakeFromNib {	
	BTRCollectionViewFlowLayout *collectionViewFlowLayout = [[BTRCollectionViewFlowLayout alloc] init];
	
	[collectionViewFlowLayout setScrollDirection:BTRCollectionViewScrollDirectionVertical];
	[collectionViewFlowLayout setItemSize:CGSizeMake(250, 250)];
	[collectionViewFlowLayout setHeaderReferenceSize:CGSizeMake(500, 30)];
	[collectionViewFlowLayout setFooterReferenceSize:CGSizeMake(500, 50)];
	[collectionViewFlowLayout setMinimumInteritemSpacing:10];
	[collectionViewFlowLayout setMinimumLineSpacing:10];
	//[collectionViewFlowLayout setSectionInset:UIEdgeInsetsMake(10, 0, 20, 0)];
	
	NSView *view = [self.window contentView];
	BTRScrollView *scrollView = [[BTRScrollView alloc] initWithFrame:view.bounds];
	scrollView.hasHorizontalScroller = NO;
    scrollView.hasVerticalScroller = YES;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
	_collectionView = [[BTRCollectionView alloc] initWithFrame:scrollView.bounds collectionViewLayout:collectionViewFlowLayout];
    _collectionView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[_collectionView setDataSource:self];
	[_collectionView setDelegate:self];
	
	[_collectionView registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
	[_collectionView registerClass:[HeaderView class] forSupplementaryViewOfKind:BTRCollectionElementKindSectionHeader withReuseIdentifier:headerViewIdentifier];
	[_collectionView registerClass:[FooterView class] forSupplementaryViewOfKind:BTRCollectionElementKindSectionFooter withReuseIdentifier:footerViewIdentifier];
	scrollView.documentView = _collectionView;
	[view addSubview:scrollView];
	
	self.data = @[ @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"], @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"], @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"], @[@"1", @"2", @"3"] ];
}

- (NSUInteger)numberOfSectionsInCollectionView:(BTRCollectionView *)collectionView {
    return [self.data count];
}


- (NSUInteger)collectionView:(BTRCollectionView *)collectionView numberOfItemsInSection:(NSUInteger)section {
    return [[self.data objectAtIndex:section] count];
}


- (BTRCollectionViewCell *)collectionView:(BTRCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = (CollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
	cell.title = [[self.data objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    
    return cell;
}

- (BTRCollectionReusableView *)collectionView:(BTRCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	NSString *identifier = nil;
	
	if ([kind isEqualToString:BTRCollectionElementKindSectionHeader]) {
		identifier = headerViewIdentifier;
	} else if ([kind isEqualToString:BTRCollectionElementKindSectionFooter]) {
		identifier = footerViewIdentifier;
	}
    BTRCollectionReusableView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
	
    // TODO Setup view
	
    return supplementaryView;
}

@end
