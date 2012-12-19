//
//  BTRSplitView.h
//  Butter
//
//  Created by Robert Widmann on 12/19/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BTRSplitView;

typedef void(^BTRSplitViewDrawDividerBlock)(BTRSplitView *splitview, CGContextRef ctx, CGRect rect, NSUInteger index);

@interface BTRSplitView : NSSplitView

/** @name Drawing A SplitView */

/**
 @param splitview A weak reference to the splitview that owns the block.
 @param ctx The drawing context for the divider.
 @param rect The rectangle specifying the region that needs redrawing within the divider.
 @param index The index of the divider being redrawn.
 @discussion Because we cannot override -dividerColor for index-based drawing, BTRSplitView
 provides this block so drawing of dividers can be done in an index-based fashion.  Dividers
 work much like subviews, in that they have zero-based indexes, however they are drawn, rather than
 added as subviews.
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
 Sets, then redraws the divider at the given index without animation.
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
- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex animated:(BOOL)animate;

@end
