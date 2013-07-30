//
//  BTRScrollView.m
//  Originally from Rebel
//
//  Created by Jonathan Willing on 12/4/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "BTRScrollView.h"
#import "BTRClipView.h"
#import <QuartzCore/CoreAnimation.h>

@implementation BTRScrollView
@synthesize contentInsets = _contentInsets;

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil) return nil;
	
	[self swapClipView];
	
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	
	if (![self.contentView isKindOfClass:BTRClipView.class] ) {
		[self swapClipView];
	}
}

#pragma mark Clip view swapping

- (void)swapClipView {
	self.wantsLayer = YES;
	id documentView = self.documentView;
	Class clipViewClass = [self.class clipViewClass];
	BTRClipView *clipView = [[clipViewClass alloc] initWithFrame:self.contentView.frame];
	clipView.backgroundColor = [self.contentView backgroundColor];
	self.contentView = clipView;
	self.documentView = documentView;
    clipView.contentInsets = self.contentInsets;
}

+ (Class)clipViewClass {
	return [BTRClipView class];
}

- (BTRClipView *)scrollClipView
{
    if ([self.contentView isKindOfClass:[BTRClipView class]]) {
        return (BTRClipView *)self.contentView;
    }
    return nil;
}

- (void)setContentInsets:(NSEdgeInsets)contentInsets
{
    NSPoint oldScrollPoint = self.contentOffset;

    [[self scrollClipView] setContentInsets:contentInsets];
    [self reflectScrolledClipView:[self scrollClipView]];

    self.contentOffset = NSMakePoint(oldScrollPoint.x, oldScrollPoint.y - contentInsets.top);
    _contentInsets = contentInsets;
}

- (void)setScrollIndicatorInsets:(NSEdgeInsets)scrollIndicatorInsets
{
    _scrollIndicatorInsets = scrollIndicatorInsets;
    [self setNeedsLayout:YES];
}

- (void)tile
{
    [super tile];

    NSRect verticalScrollerFrame = self.verticalScroller.frame;
    verticalScrollerFrame.origin.y += self.scrollIndicatorInsets.top;
    verticalScrollerFrame.size.height -= self.scrollIndicatorInsets.top + self.scrollIndicatorInsets.bottom;
    verticalScrollerFrame.origin.x -= self.scrollIndicatorInsets.right;
    self.verticalScroller.frame = verticalScrollerFrame;

    NSRect horizontalScrollerFrame = self.horizontalScroller.frame;
    horizontalScrollerFrame.origin.x += self.scrollIndicatorInsets.left;
    horizontalScrollerFrame.size.width -= self.scrollIndicatorInsets.left + self.scrollIndicatorInsets.right;
    horizontalScrollerFrame.origin.y -= self.scrollIndicatorInsets.bottom;
    self.horizontalScroller.frame = horizontalScrollerFrame;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    NSSize currentSize = self.frame.size;

    NSPoint oldScrollPoint = self.contentOffset;

    [super resizeSubviewsWithOldSize:oldSize];

    if (NSEqualSizes(oldSize, currentSize) == NO) {
        self.contentOffset = oldScrollPoint;
    }
}

- (NSPoint)contentOffset
{
    return self.contentView.bounds.origin;
}

- (void)setContentOffset:(NSPoint)contentOffset
{
    [self.contentView setBoundsOrigin:contentOffset];
}

- (id)animationForKey:(NSString *)key
{
    if ([key isEqualToString:@"contentOffset"]) {
        CABasicAnimation *animation = [CABasicAnimation animation];
        return animation;
    }

    return [super animationForKey:key];
}

@end
