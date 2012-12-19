//
//  BTRSplitView.m
//  BTRSplitViewDemo
//
//  Created by Robert Widmann on 12/8/12.
//  Copyright (c) 2012 CodaFi. All rights reserved.
//

#import "BTRSplitView.h"

static CGFloat const kBTRSplitViewAnimationDuration = .25;

@implementation BTRSplitView

//We REEEALLY want dat layer.
- (id)init {
	self = [super init];
	if (self == nil) return nil;
	self.wantsLayer = YES;
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
	if (self == nil) return nil;
	self.wantsLayer = YES;
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
    if (self == nil) return nil;
	self.wantsLayer = YES;
    return self;
}

#pragma mark - Drawing

-(void)drawDividerInRect:(NSRect)rect {
	if (self.dividerDrawBlock) {
		self.dividerDrawBlock(rect, [self _dividerIndexFromRect:rect]);
	} else {
		[super drawDividerInRect:rect];
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
    //Don't interfere with NSSplitView's drawRect.
	//It's sad to have to do it, but it appears that NSSplitView's
	//layer doesn't redraw properly without a subview adjustion...
	//*le sigh*.
	[self adjustSubviews];
	[super drawRect:dirtyRect];
}

#pragma mark - Position

-(void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex {
	[self setPosition:position ofDividerAtIndex:dividerIndex withAnimation:NO];
}

- (void)setPosition:(CGFloat)endValue ofDividerAtIndex:(NSInteger)dividerIndex withAnimation:(BOOL)animate
{
	//No animation, no problem!
    if (!animate) {
        [super setPosition:endValue ofDividerAtIndex:dividerIndex];
    }
    else {
		//Imply that the subview we want to animate is also the index of the divider we want to animate
		//Considering dividers are always (subviews-1), we don't have to subtract that one ourselves.
		//We can also ssume that the starting value if the width of said subview
		NSView *resizingSubview = [self.subviews objectAtIndex:dividerIndex];
		CGFloat startValue = NSWidth(resizingSubview.frame);
		NSRect currentFrame, startingFrame, endingFrame;
		currentFrame = [resizingSubview frame];
		
		//If the subview is hidden (i.e. collapsed), unhide it so NSAnimation doesn't go completely bonkers
		[resizingSubview setHidden:NO];
		
		if ([self isVertical]) {
			startingFrame = (NSRect){currentFrame.origin, NSMakeSize(startValue, currentFrame.size.height)};
			endingFrame = (NSRect){currentFrame.origin, NSMakeSize(endValue, currentFrame.size.height)};
		} else {
			startingFrame = (NSRect){currentFrame.origin, NSMakeSize(currentFrame.size.width, startValue)};
			endingFrame = (NSRect){currentFrame.origin, NSMakeSize(currentFrame.size.width, endValue)};
		}
		
		//Because of our Core Animation backing layer, this should use Core Animation... theoretically.
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:kBTRSplitViewAnimationDuration];
		[[NSAnimationContext currentContext]setCompletionHandler:^{
			if (endValue == 0) {
				//If the end value is zero, we're gonna go ahead and assume a collapse, which
				//means hiding the subview
				[resizingSubview setHidden:YES];
			}
		}];
		[[resizingSubview animator] setFrame: endingFrame];
		[NSAnimationContext endGrouping];
    }
}

//OMG, finally NSSplitView has a way to get the position of the divider at a given index
- (CGFloat)positionOfDividerAtIndex:(NSInteger)dividerIndex
{
	if(dividerIndex > [[self subviews] count]){
		return 0;
	}
	
	NSView *subview = (NSView *)[[self subviews] objectAtIndex:dividerIndex];
	NSRect frame = [subview frame];
	
	if(self.isVertical) {
		return frame.origin.x + frame.size.width;
	} else {
		return frame.origin.y + frame.size.height;
	}
}

#pragma mark - Private

//This is gonna be a little crazy...
-(NSInteger)_dividerIndexFromRect:(NSRect)rect {
	//Set result equal to zero to start...
	NSInteger result = 0;
	if (self.subviews.count == 2) {
		return result; //So we can return 0 if there are only two subviews (Logic).  
	}
	//Adjust the passed in rect by it's divider thickness so we can try to ping
	//the subview adjacent to it.  (either to the left, or above it).
	NSRect adjustedRect = rect;
	if (self.isVertical) {
		adjustedRect.origin.x -= 1; //Left one pixel
	} else {
		adjustedRect.origin.y += self.dividerThickness + 1; //Up the divider's thickness plus some padding
	}
	//Loop through our subviews to get the index of the view adjacent to the divider.
	for (int i = 0; i < self.subviews.count; i++) {
		NSView *subview = [self.subviews objectAtIndex:i];
		if (!CGRectIntersectsRect(subview.frame, adjustedRect)) continue;
		result = i;
	}
	return result;
}


@end
