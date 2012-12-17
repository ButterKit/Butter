//
//  BTRCollectionViewCell.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//  Header documentation is from Apple's documentation for UICollectionView: Copyright (c) 2012 Apple Inc. All Rights Reserved

#import "BTRCollectionViewCommon.h"
#import "BTRView.h"

@class BTRCollectionViewLayout, BTRCollectionView, BTRCollectionViewLayoutAttributes;

/**
 The BTRCollectionReusableView class defines the behavior for all cells and supplementary views presented by a collection view. Reusable views are so named because the collection view places them on a reuse queue rather than deleting them when they are scrolled out of the visible bounds. Such a view can then be retrieved and repurposed for a different set of content.
 */
@interface BTRCollectionReusableView : BTRView
/**
 A string that identifies the purpose of the view. (read-only)
 @discussion The collection view identifies and queues reusable views using their reuse identifiers. The collection view sets this value when it first creates the view, and the value cannot be changed later. When your data source is prompted to provide a given view, it can use the reuse identifier to dequeue a view of the appropriate type.
 */
@property (nonatomic, readonly, copy) NSString *reuseIdentifier;

/**
 Performs any clean up necessary to prepare the view for use again.
 @discussion The default implementation of this method does nothing.
 
 When a view is dequeued for use, this method is called before the corresponding dequeue method returns the view to your code. Subclasses can override this method and use it to reset properties to their default values and generally make the view ready to use again. You should not use this method to assign any new data to the view. That is the responsibility of your data source object.
 */
- (void)prepareForReuse;

/**
 Applies the specified layout attributes to the view.
 @param layoutAttributes The layout attributes to apply.
 @discussion The default implementation of this method does nothing.
 
 If the layout object supports custom layout attributes, you can use this method to apply those attributes to the view. In such a case, the layoutAttributes parameter should contain an instance of a subclass of BTRCollectionViewLayoutAttributes. You do not need to override this method to support the standard layout attributes of the BTRCollectionViewLayoutAttributes class. The collection view applies those attributes automatically.
 */
- (void)applyLayoutAttributes:(BTRCollectionViewLayoutAttributes *)layoutAttributes;

/**
 Tells your view that the layout object of the collection view is about to change.
 @param oldLayout The current layout object associated with the collection view.
 @param newLayout The new layout object that is about to be applied to the collection view.
 @discussion The default implementation of this method does nothing. Subclasses can override this method and use it to prepare for the change in layouts.
 */
- (void)willTransitionFromLayout:(BTRCollectionViewLayout *)oldLayout toLayout:(BTRCollectionViewLayout *)newLayout;

/**
 Tells your view that the layout object of the collection view changed.
 @param oldLayout The collection view’s previous layout object.
 @param newLayout The current layout object associated with the collection view.
 @discussion The default implementation of this method does nothing. Subclasses can override this method and use it to finalize any behaviors associated with the change in layouts.
 */
- (void)didTransitionFromLayout:(BTRCollectionViewLayout *)oldLayout toLayout:(BTRCollectionViewLayout *)newLayout;

@end

@interface BTRCollectionReusableView (Internal)
@property (nonatomic, unsafe_unretained) BTRCollectionView *collectionView;
@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, strong, readonly) BTRCollectionViewLayoutAttributes *layoutAttributes;
@end

/**
 A BTRCollectionViewCell object presents the content for a single data item when that item is within the collection view’s visible bounds. You can use this class as-is or subclass it to add additional properties and methods. The layout and presentation of cells is managed by the collection view and its corresponding layout object.
 */
@interface BTRCollectionViewCell : BTRCollectionReusableView

/**
 The main view to which you add your cell’s custom content. (read-only)
 @discussion When configuring a cell, you add any custom views representing your cell’s content to this view. The cell object places the content in this view in front of any background views.
 */
@property (nonatomic, readonly) BTRView *contentView;

/**
 The selection state of the cell.
 @discussion This property manages the selection state of the cell only. The default value of this property is NO, which indicates that the cell is not selected.
 
 You typically do not set the value of this property directly. Changing the value of this property programmatically does not change the appearance of the cell. The preferred way to select the cell and highlight it is to use the selection methods of the collection view object.
 */
@property (nonatomic, getter=isSelected) BOOL selected;

/**
 The highlight state of the cell.
 @discussion This property manages the highlight state of the cell only. The default value of this property is NO, which indicates that the cell is not highlighted.
 
 You typically do not set the value of this property directly. Instead, the preferred way to select the cell and highlight it is to use the selection methods of the collection view object.
 */
@property (nonatomic, getter=isHighlighted) BOOL highlighted;

/**
 The view that is displayed behind the cell’s other content.
 @discussion Use this property to assign a custom background view to the cell. The background view is placed behind the content view and its frame is automatically adjusted so that it fills the bounds of the cell.
 */
@property (nonatomic, strong) NSView *backgroundView;

/**
 The view that is displayed just above the background view when the cell is selected.
 @discussion You can use this view to give the cell a custom appearance when it is selected. When the cell is selected, this view is layered above the `backgroundView` and behind the `contentView`.
 */
@property (nonatomic, strong) NSView *selectedBackgroundView;
@end
