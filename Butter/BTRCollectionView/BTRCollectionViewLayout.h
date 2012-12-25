//
//  BTRCollectionViewLayout.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//  Header documentation is from Apple's documentation for UICollectionView: Copyright (c) 2012 Apple Inc. All Rights Reserved

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

extern NSString *const BTRCollectionElementKindSectionHeader;
extern NSString *const BTRCollectionElementKindSectionFooter;

typedef NS_ENUM(NSUInteger, BTRCollectionViewItemType) {
    BTRCollectionViewItemTypeCell,
    BTRCollectionViewItemTypeSupplementaryView,
    BTRCollectionViewItemTypeDecorationView
};

@class BTRCollectionViewLayoutAttributes, BTRCollectionView;
/**
 The BTRCollectionViewLayout class is an abstract base class that you subclass and use to generate layout information for a collection view. The job of a layout object is to determine the placement of cells, supplementary views, and decoration views inside the collection view’s bounds and to report that information to the collection view when asked. The collection view then applies the provided layout information to the corresponding views so that they can be presented onscreen.
 */
@interface BTRCollectionViewLayout : NSObject <NSCoding>

/**
 The collection view object currently using this layout object. (read-only)
 @discussion The collection view object sets the value of this property when a new layout object is assigned to it.
 */
@property (nonatomic, unsafe_unretained, readonly) BTRCollectionView *collectionView;

/**
 Invalidates the current layout and triggers a layout update.
 @discussion You can call this method at any time to update the layout information. This method invalidates the layout of the collection view itself and returns right away. Thus, you can call this method multiple times from the same block of code without triggering multiple layout updates. The actual layout update occurs during the next view layout update cycle.
 */
- (void)invalidateLayout;

/// @name Registering Decoration Views

/**
 Registers a class for use in creating decoration views for a collection view.
 @param viewClass The class to use for the supplementary view.
 @param decorationViewKind The element kind of the decoration view. You can use this string to distinguish between decoration views with different purposes in the layout. This parameter must not be nil and must not be an empty string.
 @discussion This method gives the layout object a chance to register a decoration view for use in the collection view. Decoration views provide visual adornments to a section or to the entire collection view but are not otherwise tied to the data provided by the collection view’s data source.
 
 You do not need to create decoration views explicitly. After registering one, it is up to the layout object to decide when a decoration view is needed and return the corresponding layout attributes from its layoutAttributesForElementsInRect: method. For layout attributes that specify a decoration view, the collection view creates (or reuses) a view and displays it automatically based on the registered information.
 
 If you previously registered a class or nib file with the same kind string, the class you specify in the viewClass parameter replaces the old entry. You may specify nil for viewClass if you want to unregister the decoration view.
 */
- (void)registerClass:(Class)viewClass forDecorationViewOfKind:(NSString *)decorationViewKind;

/**
 Registers a nib file for use in creating decoration views for a collection view.
 @param nib The nib object containing the cell definition. The nib file must contain only one top-level object and that object must be of the type UICollectionReusableView.
 @param decorationViewKind The element kind of the decoration view. You can use this string to distinguish between decoration views with different purposes in the layout. This parameter must not be nil and must not be an empty string.
 @discussion This method gives the layout object a chance to register a decoration view for use in the collection view. Decoration views provide visual adornments to a section or to the entire collection view but are not otherwise tied to the data provided by the collection view’s data source.
 
 You do not need to create decoration views explicitly. After registering one, it is up to the layout object to decide when a decoration view is needed and return the corresponding layout attributes from its layoutAttributesForElementsInRect: method. For layout attributes that specify a decoration view, the collection view creates (or reuses) a view and displays it automatically based on the registered information.
 
 If you previously registered a class or nib file with the same kind string, the class you specify in the viewClass parameter replaces the old entry. You may specify nil for viewClass if you want to unregister the decoration view.
 */
- (void)registerNib:(NSNib *)nib forDecorationViewOfKind:(NSString *)decorationViewKind;
@end


/**
 An BTRCollectionViewLayoutAttributes object manages the layout-related attributes for a given item in a collection view. Layout objects create instances of this class when asked to do so by the collection view. In turn, the collection view uses the layout information to position cells and supplementary views inside its bounds.
 */
@interface BTRCollectionViewLayoutAttributes : NSObject <NSCopying>

/**
 The frame rectangle of the item.
 @discussion The frame rectangle is measured in points and specified in the coordinate system of the collection view. Setting the value of this property also sets the values of the `center` and `size` properties.
 */
@property (nonatomic) CGRect frame;

/**
 The center point of the item.
 @discussion The center point is specified in the coordinate system of the collection view. Setting the value of this property also updates the origin of the rectangle in the `frame` property.
 */
@property (nonatomic) CGPoint center;

/**
 The size of the item.
 @discussion Setting the value of this property also changes the size of the rectangle returned by the `frame` property.
 */
@property (nonatomic) CGSize size;

/**
 The transform of the item.
 @discussion Setting the value of this property affects the rectangle returned by the frame property.
 */
@property (nonatomic) CATransform3D transform3D;

/**
 The transparency of the item.
 @discussion Possible values are between 0.0 (transparent) and 1.0 (opaque). The default is 1.0.
 */
@property (nonatomic) CGFloat alpha;

/**
 Specifies the item’s position on the z axis.
 @discussion The default value of this property is 0.
 */
@property (nonatomic) NSInteger zIndex;

/**
 Determines whether the item is currently displayed.
 @discussion The default value of this property is NO. As an optimization, the collection view might not create the corresponding view if this property is set to YES.
 */
@property (nonatomic, getter=isHidden) BOOL hidden;

/**
 The index path of the item in the collection view.
 @discussion The index path contains the index of the section and the index of the item within that section. These two values uniquely identify the position of the corresponding item in the collection view.
 */
@property (nonatomic, strong) NSIndexPath *indexPath;

/**
 The layout-specific identifier for the target view. (read-only)
 @discussion You can use the value in this property to identify the specific purpose of the supplementary or decoration view associated with the attributes. This property is nil if the `representedElementCategory` property contains the value BTRCollectionElementCategoryCell.
 */
@property (nonatomic, readonly) NSString *representedElementKind;

/**
 The type of the item. (read-only)
 @discussion You can use the value in this property to distinguish whether the layout attributes are intended for a cell, supplementary view, or decoration view.
 */
@property (nonatomic, readonly) BTRCollectionViewItemType representedElementCategory;

/**
 Creates and returns a layout attributes object that represents a cell with the specified index path.
 @param indexPath The index path of the cell.
 @return A new layout attributes object whose precise type matches the type of the class used to call this method.
 @discussion Use this method to create a layout attributes object for a cell in the collection view. Cells are the main type of view presented by a collection view. The index path for a cell typically includes both a section index and an item index for locating the cell’s contents in the collection view’s data source.
 */
+ (instancetype)layoutAttributesForCellWithIndexPath:(NSIndexPath *)indexPath;

/**
 Creates and returns a layout attributes object that represents the specified supplementary view.
 @param elementKind A string that identifies the type of supplementary view.
 @param indexPath The index path of the view.
 @return A new layout attributes object whose precise type matches the type of the class used to call this method.
 @discussion Use this method to create a layout attributes object for a supplementary view in the collection view. Like cells, supplementary views present data that is managed by the collection view’s data source. But unlike cells, supplementary views are typically designed for a special purpose. For example, header and footer views are laid out differently than cells and can be provided for individual sections or for the collection view as a whole.
 
 It is up to you to decide how to use the indexPath parameter to identify a given supplementary view. Typically, you use the elementKind parameter to identify the type of the supplementary view and the indexPath information to distinguish between different instances of that view.
 */
+ (instancetype)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind withIndexPath:(NSIndexPath *)indexPath;

/**
 Creates and returns a layout attributes object that represents the specified decoration view.
 @param indexPath An index path related to the decoration view.
 @param decorationViewKind The kind identifier for the specified decoration view.
 Use this method to create a layout attributes object for a decoration view in the collection view. Decoration views are a type of supplementary view but do not present data that is managed by the collection view’s data source. Instead, they mostly present visual adornments for a section or for the entire collection view.
 
 It is up to you to decide how to use the indexPath parameter to identify a given decoration view. Typically, you use the reuseIdentifier parameter to identify the type of the decoration view and the indexPath information to distinguish between different instances of that view.
 */
+ (instancetype)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind withIndexPath:(NSIndexPath*)indexPath;

/**
 @return Whether the view is a decoration view 
 */
- (BOOL)isDecorationView;

/**
 @return Whether the view is a supplementary view
 */
- (BOOL)isSupplementaryView;

/** 
 @return Whether the view is a collection view cell
 */
- (BOOL)isCell;
@end

@interface BTRCollectionViewLayout (SubclassingHooks)

/**
 Tells the layout object to update the current layout.
 @discussion Layout updates occur the first time the collection view presents its content and whenever the layout is invalidated explicitly or implicitly because of a change to the view. During each layout update, the collection view calls this method first to give your layout object a chance to prepare for the upcoming layout operation.
 
 The default implementation of this method does nothing. Subclasses can override it and use it to set up data structures or perform any initial computations needed to perform the layout later.
 */
- (void)prepareLayout;

/**
 Returns the layout attributes for all of the cells and views in the specified rectangle.
 @param rect The rectangle (specified in the collection view’s coordinate system) containing the target views.
 @return An array of UICollectionViewLayoutAttributes objects representing the layout information for the cells and views. The default implementation returns nil.
 @discussion Subclasses must override this method and use it to return layout information for all items whose view intersects the specified rectangle. Your implementation should return attributes for all visual elements, including cells, supplementary views, and decoration views.
 
 When creating the layout attributes, always create an attributes object that represents the correct element type (cell, supplementary, or decoration). The collection view differentiates between attributes for each type and uses that information to make decisions about which views to create and how to manage them.
 */
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect;

/**
 Returns the layout attributes for the item at the specified index path.
 @param indexPath The index path of the item.
 @return A layout attributes object containing the information to apply to the item’s cell.
 @discussion Subclasses must override this method and use it to return layout information for items in the collection view. You use this method to provide layout information only for items that have a corresponding cell. Do not use it for supplementary views or decoration views.
 */
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 Returns the layout attributes for the specified supplementary view.
 @param kind A string that identifies the type of the supplementary view.
 @param indexPath The index path of the view.
 @return A layout attributes object containing the information to apply to the supplementary view.
 @discussion If your layout object defines any supplementary views, you must override this method and use it to return layout information for those views.
 */
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

/**
 Returns the layout attributes for the specified decoration view.
 @param decorationViewKind A string that identifies the type of the decoration view.
 @param indexPath The index path of the decoration view.
 @return A layout attributes object containing the information to apply to the decoration view.
 @discussion If your layout object defines any decoration views, you must override this method and use it to return layout information for those views.
 */
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForDecorationViewWithReuseIdentifier:(NSString*)identifier atIndexPath:(NSIndexPath *)indexPath;

/**
 Returns the point at which to stop scrolling.
 @param proposedContentOffset The proposed point (in the collection view’s content view) at which to stop scrolling. This is the value at which scrolling would naturally stop if no adjustments were made. The point reflects the upper-left corner of the visible content.
 @param velocity The current scrolling velocity along both the horizontal and vertical axes. This value is measured in points per second.
 @return The content offset that you want to use instead. This value reflects the adjusted upper-left corner of the visible area. The default implementation of this method returns the value in the proposedContentOffset parameter.
 @discussion If you want the scrolling behavior to snap to specific boundaries, you can override this method and use it to change the point at which to stop. For example, you might use this method to always stop scrolling on a boundary between items, as opposed to stopping in the middle of an item.
 */
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity;

/**
 Asks the layout object if the new bounds require a layout update.
 @param newBounds The new bounds of the collection view.
 @return YES if the collection view requires a layout update or NO if the layout does not need to change.
 @discussion The default implementation of this method returns NO. Subclasses should override it and return an appropriate value based on whether changes in the bounds of the collection view require changes to the layout of cells and supplementary views.
 */
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds; 

/**
 Returns the width and height of the collection view’s contents.
 @return The width and height of the collection view’s contents.
 @discussion Subclasses must override this method and use it to return the width and height of the collection view’s content. These values represent the width and height of all the content, not just the content that is currently visible. The collection view uses this information to configure its own content size for scrolling purposes.
 
 The default implementation of this method returns CGSizeZero.
 */
- (CGSize)collectionViewContentSize;
@end

@interface BTRCollectionViewLayout (UpdateSupportHooks)

/**
 Prepares the layout object to receive changes to the contents of the collection view.
 @param updateItems An array of UICollectionViewUpdateItem objects that identify the changes being made.
 @discussion When items are inserted or deleted, the collection view notifies its layout object so that it can adjust the layout as needed. The first step in that process is to call this method to let the layout object know what changes to expect. After that, additional calls are made to gather layout information for inserted, deleted, and moved items that are going to be animated around the collection view.
 */
- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems;

/**
 Performs any additional animations or clean up needed during a collection view update.
 @discussion The collection view calls this method as the last step before preceding to animate any changes into place. This method is called within the animation block used to perform all of the insertion, deletion, and move animations so you can create additional animations using this method as needed. Otherwise, you can use it to perform any last minute tasks associated with managing your layout object’s state information.
 */
- (void)finalizeCollectionViewUpdates;

/**
 Returns the starting layout information for an item being inserted into the collection view.
 @param itemIndexPath The index path of the item being inserted. You can use this path to locate the item in the collection view’s data source.
 @return A layout attributes object that describes the position at which to place the corresponding cell.
 @discussion This method is called after the prepareForCollectionViewUpdates: method and before the finalizeCollectionViewUpdates method for any items that are about to be inserted. Your implementation should return the layout information that describes the initial position and state of the item. The collection view uses this information as the starting point for any animations. (The end point of the animation is the item’s new location in the collection view.) If you return nil, the layout object uses the item’s final attributes for both the start and end points of the animation.
 
 The default implementation of this method returns nil.
 */
- (BTRCollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath*)itemIndexPath;

/**
 Returns the final layout information for an item that is about to be removed from the collection view.
 @param itemIndexPath The index path of the item being deleted.
 @return A layout attributes object that describes the position of the cell to use as the end point for animating its removal.
 @discussion This method is called after the prepareForCollectionViewUpdates: method and before the finalizeCollectionViewUpdates method for any items that are about to be deleted. Your implementation should return the layout information that describes the final position and state of the item. The collection view uses this information as the end point for any animations. (The starting point of the animation is the item’s current location.) If you return nil, the layout object uses the same attributes for both the start and end points of the animation.
 
 The default implementation of this method returns nil.
 */
- (BTRCollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath;

/**
 Returns the starting layout information for a supplementary view being inserted into the collection view.
 @param elementKind A string that identifies the type of supplementary view.
 @param elementIndexPath The index path of the item being inserted.
 @return A layout attributes object that describes the position at which to place the corresponding supplementary view.
 @discussion This method is called after the prepareForCollectionViewUpdates: method and before the finalizeCollectionViewUpdates method for any supplementary views that are about to be inserted. Your implementation should return the layout information that describes the initial position and state of the view. The collection view uses this information as the starting point for any animations. (The end point of the animation is the view’s new location in the collection view.) If you return nil, the layout object uses the item’s final attributes for both the start and end points of the animation.
 
 The default implementation of this method returns nil.
 */
- (BTRCollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath;

/**
 Returns the final layout information for a supplementary view that is about to be removed from the collection view.
 @param elementKind A string that identifies the type of supplementary view.
 @param elementIndexPath The index path of the view being deleted.
 @return A layout attributes object that describes the position of the supplementary view to use as the end point for animating its removal.
 @discussion This method is called after the prepareForCollectionViewUpdates: method and before the finalizeCollectionViewUpdates method for any supplementary views that are about to be deleted. Your implementation should return the layout information that describes the final position and state of the view. The collection view uses this information as the end point for any animations. (The starting point of the animation is the view’s current location.) If you return nil, the layout object uses the same attributes for both the start and end points of the animation.
 
 The default implementation of this method returns nil.
 */
- (BTRCollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath;

@end

@interface BTRCollectionViewLayout (Private)
- (void)setCollectionViewBoundsSize:(CGSize)size;
@end

extern NSString* const BTRCollectionViewOldModelKey;
extern NSString* const BTRCollectionViewNewModelKey;
extern NSString *const BTRCollectionViewOldToNewIndexMapKey;
extern NSString* const BTRCollectionViewNewToOldIndexMapKey;