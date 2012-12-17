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

#import <Butter/NSView+BTRAdditions.h>
#import <Butter/BTRScrollView.h>

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
	BTRScrollView *scrollView = [[BTRScrollView alloc] initWithFrame:view.bounds];
	scrollView.hasHorizontalScroller = NO;
    scrollView.hasVerticalScroller = YES;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	
    self.collectionView = [[BTRCollectionView alloc] initWithFrame:scrollView.bounds collectionViewLayout:[[CircleLayout alloc] init]];
    self.collectionView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[self.collectionView setDelegate:self];
	[self.collectionView setDataSource:self];
	[self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:@"MY_CELL"];
	self.collectionView.backgroundColor = [NSColor underPageBackgroundColor];
	scrollView.documentView = _collectionView;
	[view addSubview:scrollView positioned:NSWindowBelow relativeTo:self.toggleButton];
}

-(NSUInteger)numberOfSectionsInCollectionView:(BTRCollectionView *)collectionView
{
    return [self.sections count];
}

- (NSUInteger)collectionView:(BTRCollectionView *)view numberOfItemsInSection:(NSUInteger)section;
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
	NSIndexPath *tappedCellPath = [self.collectionView indexPathForCell:cell];
	if (tappedCellPath != nil) {
		[self.sections[tappedCellPath.section] removeObjectAtIndex:tappedCellPath.item];
		[self.collectionView performBatchUpdates:^{
			[self.collectionView deleteItemsAtIndexPaths:@[tappedCellPath]];
		} completion:nil];
	}
}

- (void)changeLayout:(id)sender {
	// Wrapping new layouts in an animation block is not nessesary to get an animation.
	// This is just an example of how the animation can be changed as desired.
	[NSView btr_animateWithDuration:1.5 animationCurve:BTRViewAnimationCurveEaseInOut animations:^{
		if([self.collectionView.collectionViewLayout isKindOfClass:[CircleLayout class]]) {
			
			[self.collectionView setCollectionViewLayout:[[BTRCollectionViewFlowLayout alloc] init] animated:YES];
		}
		else {
			[self.collectionView setCollectionViewLayout:[[CircleLayout alloc] init] animated:YES];
		}
	} completion:NULL];
}

- (void)addCell:(id)sender {
	[self.sections[0] addObject:@([[self.sections[0] lastObject] unsignedIntegerValue] + 1)];
	NSIndexPath *path = [NSIndexPath btr_indexPathForRow:[self.sections[0] count] - 1 inSection:0];
	[self.collectionView insertItemsAtIndexPaths:@[path]];
}
@end
