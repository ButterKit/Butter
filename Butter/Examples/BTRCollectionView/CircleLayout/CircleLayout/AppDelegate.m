//
//  AppDelegate.m
//  CircleLayout
//
//  Created by Jonathan Willing on 12/7/12.
//  Copyright (c) 2012 Jonathan Willing. All rights reserved.
//

#import "AppDelegate.h"
#import "Cell.h"
#import "CircleLayout.h"

#import <Butter/NSView+RBLAnimationAdditions.h>
#import <Butter/RBLScrollView.h>

static NSInteger count;

@interface AppDelegate()
@property (nonatomic, strong) NSMutableArray* sections;
@property (nonatomic, strong) BTRCollectionView *collectionView;
@end

@implementation AppDelegate

- (void)awakeFromNib {
    self.sections = [[NSMutableArray alloc] initWithArray:@[[NSMutableArray array]]];
    
    
    for(NSInteger i = 0; i < 25; i++)
        [self.sections[0] addObject:@(count++)];
    
	NSView *view = [self.window contentView];
	RBLScrollView *scrollView = [[RBLScrollView alloc] initWithFrame:view.bounds];
	scrollView.hasHorizontalScroller = NO;
    scrollView.hasVerticalScroller = YES;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	
    self.collectionView = [[BTRCollectionView alloc] initWithFrame:scrollView.bounds collectionViewLayout:[[CircleLayout alloc] init]];
    self.collectionView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[self.collectionView setDelegate:self];
	[self.collectionView setDataSource:self];
	[self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:@"MY_CELL"];
	scrollView.documentView = _collectionView;
	[view addSubview:scrollView positioned:NSWindowBelow relativeTo:self.toggleButton];
}

-(NSInteger)numberOfSectionsInCollectionView:(BTRCollectionView *)collectionView
{
    return [self.sections count];
}

- (NSInteger)collectionView:(BTRCollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return [self.sections[section] count];
}

- (BTRCollectionViewCell *)collectionView:(BTRCollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    Cell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"MY_CELL" forIndexPath:indexPath];
	cell.delegate = self;
    cell.label.stringValue = [NSString stringWithFormat:@"%@", self.sections[indexPath.section][indexPath.item]];
    return (BTRCollectionViewCell *)cell;
}

- (void)cellClicked:(Cell *)cell {
	//TODO: Deletion is broken. Layout is not updated automatically.
	NSIndexPath *tappedCellPath = [self.collectionView indexPathForCell:cell];
	NSLog(@"%@",self.sections[tappedCellPath.section][tappedCellPath.item]);
	if (tappedCellPath != nil)
	{
		[self.sections[tappedCellPath.section] removeObjectAtIndex:tappedCellPath.item];
		[self.collectionView performBatchUpdates:^{
			[self.collectionView deleteItemsAtIndexPaths:@[tappedCellPath]];
			[self.collectionView setNeedsLayout:YES];
		} completion:^
		 {
			 NSLog(@"delete finished");
		 }];
	}
}

- (void)changeLayout:(id)sender {
	// Wrapping new layouts in an animation block is not nessesary to get an animation.
	// This is just an example of how the animation can be changed as desired.
	[NSView rbl_animateWithDuration:1.5 animationCurve:RBLViewAnimationCurveEaseInOut animations:^{
		if([self.collectionView.collectionViewLayout isKindOfClass:[CircleLayout class]]) {
			
			[self.collectionView setCollectionViewLayout:[[BTRCollectionViewFlowLayout alloc] init] animated:YES];
		}
		else {
			[self.collectionView setCollectionViewLayout:[[CircleLayout alloc] init] animated:YES];
		}
	} completion:NULL];
}

- (void)addCell:(id)sender {
	// Either I'm doing this wrong, or this is broken. Right now I'm using the terribly inefficient and slow
	// method of just reloading the whole collection view.
	// TODO: Look into insertion.
	
	 [self.sections[0] addObject:@([[self.sections[0] lastObject] intValue] + 1)];
	//[self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath btr_indexPathForRow:[self.sections[0] count] inSection:0]]];
	[self.collectionView reloadData];
	
	
	/*
	
	NSInteger insertElements = 10;
	NSInteger deleteElements = 10;
	
	NSMutableSet* insertedIndexPaths = [NSMutableSet set];
	NSMutableSet* deletedIndexPaths = [NSMutableSet set];
	
	for(NSInteger i=0;i<deleteElements;i++)
	{
		NSInteger index = rand()%[self.sections[0] count];
		NSIndexPath* indexPath = [NSIndexPath btr_indexPathForItem:index inSection:0];
		
		if([deletedIndexPaths containsObject:indexPath])
		{
			i--;
			continue;
		}
		[self.sections[0] removeObjectAtIndex:index];
		[deletedIndexPaths addObject:indexPath];
	}
	
	for(NSInteger i=0;i<insertElements;i++)
	{
		NSInteger index = rand()%[self.sections[0] count];
		NSIndexPath* indexPath = [NSIndexPath btr_indexPathForItem:index inSection:0];
		if([insertedIndexPaths containsObject:indexPath])
		{
			i--;
			continue;
		}
		
		[self.sections[0] insertObject:@(count++)
							   atIndex:index];
		[insertedIndexPaths addObject:indexPath];
	}
	[self.collectionView performBatchUpdates:^{
		
		
		[self.collectionView insertItemsAtIndexPaths:[insertedIndexPaths allObjects]];
		[self.collectionView deleteItemsAtIndexPaths:[deletedIndexPaths allObjects]];
		
		
	} completion:^{
		 NSLog(@"insert finished");
	 }];
	 */
}


@end
