//
//  BTRCollectionViewScrollView.m
//  BasicExample
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRCollectionViewScrollView.h"
#import "BTRCollectionViewClipView.h"

@implementation BTRCollectionViewScrollView

#pragma mark Initialization

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil) return nil;
	[self swapClipView];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil) return nil;
	[self swapClipView];
	return self;
}


#pragma mark Clip view swapping

- (void)swapClipView {
	self.wantsLayer = YES;
	id documentView = self.documentView;
	BTRCollectionViewClipView *clipView = [[BTRCollectionViewClipView alloc] initWithFrame:self.contentView.frame];
	self.contentView = clipView;
	self.documentView = documentView;
}


#pragma mark Content offset

- (void)tile {
    [super tile];
	
	if (CGPointEqualToPoint(self.contentOffset, CGPointZero))
		return;
	
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.origin = self.contentOffset;
    contentViewFrame.size.width -= self.contentOffset.x;
    contentViewFrame.size.height -= self.contentOffset.y;
    self.contentView.frame = contentViewFrame;
}

- (void)setContentOffset:(CGPoint)contentOffset {
    if (!CGPointEqualToPoint(_contentOffset, contentOffset)) {
        _contentOffset = contentOffset;
        [self tile];
    }
}

@end
