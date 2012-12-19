//
//  BTRSplitView.h
//  BTRSplitViewDemo
//
//  Created by Robert Widmann on 12/8/12.
//  Copyright (c) 2012 CodaFi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^BTRSplitViewDrawDividerBlock)(CGRect rect, NSUInteger index);

@interface BTRSplitView : NSSplitView

/** @name Drawing A SplitView */

/**
 @param rect The rectangle specifying the region that needs redrawing within the divider.
 @param index The index of the divider being redrawn.
 @discussion Because we cannot override -dividerColor for index-based drawing,
	this is the next step up.  While it may be overkill to add an entire
	drawing block just for dividers, it's something that NSSplitView should have had
	from the get-go (or at least some way to draw with the index of the divider, not just the frame.
	Suffice to say there is some black-magic involved in getting a subview index for the block...
 */

@property (nonatomic, copy) BTRSplitViewDrawDividerBlock dividerDrawBlock;

/** @name Positioning the Panes of a Split View */

/**
 Returns the position of the divider at a given index
 @param dividerIndex The index of the divider that will be queried for it's position.
 @return The position of the divider, or 0 if an invalid index was specified or the subview is collapsed.
 */
- (CGFloat)positionOfDividerAtIndex:(NSInteger)dividerIndex;


/**
 Defaults to NSSplitView's interpretation, sans animation.
 @param position The ending position of the divider that will be moved.
 @param dividerIndex The index of the divider that will be moved.
 */
- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex;

/**
 Sets the position of the divider at the given index with or without animation.
 @param position The ending position of the divider that will be moved.
 @param dividerIndex The index of the divider that will be moved.
 @param withAnimation Specify this to have the divider animate for the default duration (0.25 sec.), else default to NSSplitView's interpretation
 @discussion Whether animation is applied or not, the frames of the views themselves are adjusted,
 meaning that we get consistent redraw behavior, and smooth collapsing because BTRSplitView defaults to having
 a Core Animation layer.  Resize is subject to the constraints outlined in your delegate, so animation reserves the
 right to adjust the frames of adjacent subviews to ensure the position request is satisfied.
 */
- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex withAnimation:(BOOL)animate;

@end
