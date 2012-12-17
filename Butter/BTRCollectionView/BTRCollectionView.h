//
//  BTRCollectionView.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//  Header documentation is from Apple's documentation for UICollectionView: Copyright (c) 2012 Apple Inc. All Rights Reserved

#import "BTRCollectionViewLayout.h"
#import "BTRCollectionViewFlowLayout.h"
#import "BTRCollectionViewCell.h"
#import "BTRCollectionViewCommon.h"
#import "NSIndexPath+BTRAdditions.h"

#import "BTRView.h"

typedef NS_OPTIONS(NSUInteger, BTRCollectionViewScrollPosition) {
	/**
	 Do not scroll the item into view.
	 */
    BTRCollectionViewScrollPositionNone                 = 0,

    // The vertical positions are mutually exclusive to each other, but are bitwise or-able with the horizontal scroll positions.
    // Combining positions from the same grouping (horizontal or vertical) will result in an NSInvalidArgumentException.
	
	/**
	 Scroll so that the item is positioned at the top of the collection view’s bounds. This option is mutually exclusive with the BTRCollectionViewScrollPositionCenteredVertically and BTRCollectionViewScrollPositionBottom options.
	 */
    BTRCollectionViewScrollPositionTop                  = 1 << 0,
	/**
	 Scroll so that the item is centered vertically in the collection view. This option is mutually exclusive with the BTRCollectionViewScrollPositionTop and BTRCollectionViewScrollPositionBottom options.
	 */
    BTRCollectionViewScrollPositionCenteredVertically   = 1 << 1,
	/**
	 Scroll so that the item is positioned at the bottom of the collection view’s bounds. This option is mutually exclusive with the BTRCollectionViewScrollPositionTop and BTRCollectionViewScrollPositionCenteredVertically options.
	 */
    BTRCollectionViewScrollPositionBottom               = 1 << 2,

    // Likewise, the horizontal positions are mutually exclusive to each other.
	
	/**
	 Scroll so that the item is positioned at the left edge of the collection view’s bounds. This option is mutually exclusive with the BTRCollectionViewScrollPositionCenteredHorizontally and BTRCollectionViewScrollPositionRight options.
	 */
    BTRCollectionViewScrollPositionLeft                 = 1 << 3,
	
	/**
	 Scroll so that the item is centered horizontally in the collection view. This option is mutually exclusive with the BTRCollectionViewScrollPositionLeft and BTRCollectionViewScrollPositionRight options.
	 */
    BTRCollectionViewScrollPositionCenteredHorizontally = 1 << 4,
	
	/**
	 Scroll so that the item is positioned at the right edge of the collection view’s bounds. This option is mutually exclusive with the BTRCollectionViewScrollPositionLeft and BTRCollectionViewScrollPositionCenteredHorizontally options.
	 */
    BTRCollectionViewScrollPositionRight                = 1 << 5
};

@interface BTRCollectionView : BTRView

/** @name Initializing a Collection View */

/** 
 Initializes and returns a newly allocated collection view object with the specified frame and layout.
 @param frame The frame rectangle for the collection view, measured in points. The origin of the frame is relative to the superview in which you plan to add it. This frame is passed to the superclass during initialization.
 @param layout The layout object to use for organizing items. The collection view stores a strong reference to the specified object. You may specify nil for this parameter.
 @return An initialized collection view object or nil if the object could not be created.
 @discussion Use this method when initializing a collection view object programmatically. If you specify nil for the layout parameter, you must assign a layout object to the collectionViewLayout property before displaying the collection view onscreen. If you do not, the collection view will be unable to present any items onscreen.
 
 This method is the designated initializer.
 */
- (id)initWithFrame:(CGRect)frame collectionViewLayout:(BTRCollectionViewLayout *)layout;

/** @name Configuring the Collection View */

/**
 The layout used to organize the collected view’s items.
 @discussion Assigning a new layout object to this property causes the new layout to be applied (without animations) to the collection view’s items.
 */
@property (nonatomic, strong) BTRCollectionViewLayout *collectionViewLayout;

/**
 Assigns a new layout object to the collection view and optionally animates the change.
 @param layout The new layout object to use to organize the collected views.
 @param animated Specify YES if you want to animate changes from the current layout to the new layout specified by the layout parameter. Specify NO to make the change without animations.
 @discussion When animating layout changes, the animation timing and parameters are controlled by the collection view.
 */
- (void)setCollectionViewLayout:(BTRCollectionViewLayout *)layout animated:(BOOL)animated;

/**
 The object that acts as the delegate of the collection view.
 @discussion The delegate must adopt the BTRCollectionViewDelegate protocol. The collection view maintains a weak reference to the delegate object.
 
 The delegate object is responsible for managing selection behavior and interactions with individual items.
 */
@property (nonatomic, assign) IBOutlet id <BTRCollectionViewDelegate> delegate;

/**
 The object that provides the data for the collection view.
 @discussion The data source must adopt the BTRCollectionViewDataSource protocol. The collection view maintains a weak reference to the data source object.
 */
@property (nonatomic, assign) IBOutlet id <BTRCollectionViewDataSource> dataSource;

/**
 The view that provides the background appearance.
 @discussion The view (if any) in this property is positioned underneath all of the other content and sized automatically to fill the entire bounds of the collection view. The background view does not scroll with the collection view’s other content. The collection view maintains a strong reference to the background view object.
 */
@property (nonatomic, strong) NSView *backgroundView;

/** @name Creating Collection View Cells */

/**
 Register a class for use in creating new collection view cells.
 @param cellClass The class of a cell that you want to use in the collection view.
 @param identifier The reuse identifier to associate with the specified class. This parameter must not be nil and must not be an empty string.
 @discussion Prior to calling the dequeueReusableCellWithReuseIdentifier:forIndexPath: method of the collection view, you must use this method or the registerNib:forCellWithReuseIdentifier: method to tell the collection view how to create a new cell of the given type. If a cell of the specified type is not currently in a reuse queue, the collection view uses the provided information to create a new cell object automatically.
 
 If you previously registered a class or nib file with the same reuse identifier, the class you specify in the cellClass parameter replaces the old entry. You may specify nil for cellClass if you want to unregister the class from the specified reuse identifier.
 */
- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;

/**
 Register a nib file for use in creating new collection view cells.
 @param nib The nib object containing the cell object. The nib file must contain only one top-level object and that object must be of the type BTRCollectionViewCell.
 @param identifier The reuse identifier to associate with the specified nib file. This parameter must not be nil and must not be an empty string.
 @discussion Prior to calling the `dequeueReusableCellWithReuseIdentifier:forIndexPath:` method of the collection view, you must use this method or the registerClass:forCellWithReuseIdentifier: method to tell the collection view how to create a new cell of the given type. If a cell of the specified type is not currently in a reuse queue, the collection view uses the provided information to create a new cell object automatically.
 
 If you previously registered a class or nib file with the same reuse identifier, the object you specify in the nib parameter replaces the old entry. You may specify nil for nib if you want to unregister the nib file from the specified reuse identifier.
 */
- (void)registerNib:(NSNib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

/**
 Registers a class for use in creating supplementary views for the collection view.
 @param viewClass The class to use for the supplementary view.
 @param elementKind The kind of supplementary view to create. This value is defined by the layout object. This parameter must not be nil.
 @param identifier The reuse identifier to associate with the specified class. This parameter must not be nil and must not be an empty string.
 @discussion Prior to calling the `dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:` method of the collection view, you must use this method or the `registerNib:forSupplementaryViewOfKind:withReuseIdentifier:` method to tell the collection view how to create a supplementary view of the given type. If a view of the specified type is not currently in a reuse queue, the collection view uses the provided information to create a view object automatically.
 
 If you previously registered a class or nib file with the same element kind and reuse identifier, the class you specify in the viewClass parameter replaces the old entry. You may specify nil for viewClass if you want to unregister the class from the specified element kind and reuse identifier.
 */
- (void)registerClass:(Class)viewClass forSupplementaryViewOfKind:(NSString *)elementKind withReuseIdentifier:(NSString *)identifier;

/**
 Registers a nib file for use in creating supplementary views for the collection view.
 @param nib The nib object containing the view object. The nib file must contain only one top-level object and that object must be of the type BTRCollectionViewCell.
 @param kind The kind of supplementary view to create. This value is defined by the layout object. This parameter must not be nil.
 @param identifier The reuse identifier to associate with the specified nib file. This parameter must not be nil and must not be an empty string.
 @discussion Prior to calling the `dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:` method of the collection view, you must use this method or the `registerClass:forSupplementaryViewOfKind:withReuseIdentifier:` method to tell the collection view how to create a supplementary view of the given type. If a view of the specified type is not currently in a reuse queue, the collection view uses the provided information to create a view object automatically.
 
 If you previously registered a class or nib file with the same element kind and reuse identifier, the class you specify in the viewClass parameter replaces the old entry. You may specify nil for nib if you want to unregister the class from the specified element kind and reuse identifier.
 */
- (void)registerNib:(NSNib *)nib forSupplementaryViewOfKind:(NSString *)kind withReuseIdentifier:(NSString *)identifier;

/**
 Returns a reusable cell object located by its identifier
 @param identifier The reuse identifier for the specified cell. This parameter must not be nil.
 @param indexPath The index path specifying the location of the cell. The data source receives this information when it is asked for the cell and should just pass it along. This method uses the index path to perform additional configuration based on the cell’s position in the collection view.
 @return A valid BTRCollectionReusableView object.
 @discussion Call this method from your data source object when asked to provide a new cell for the collection view. This method dequeues an existing cell if one is available or creates a new one based on the class or nib file you previously registered.
 
 @warning *Important:* You must register a class or nib file using the `registerClass:forCellWithReuseIdentifier:` or `registerNib:forCellWithReuseIdentifier:` method before calling this method.
 
 If you registered a class for the specified identifier and a new cell must be created, this method initializes the cell by calling its initWithFrame: method. For nib-based cells, this method loads the cell object from the provided nib file. If an existing cell was available for reuse, this method calls the cell’s `prepareForReuse` method instead.
 */
- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

/**
 Returns a reusable supplementary view located by its identifier and kind.
 @param elementKind The kind of supplementary view to retrieve. This value is defined by the layout object. This parameter must not be nil.
 @param identifier The reuse identifier for the specified view. This parameter must not be nil.
 @param indexPath The index path specifying the location of the supplementary view in the collection view. The data source receives this information when it is asked for the view and should just pass it along. This method uses the information to perform additional configuration based on the view’s position in the collection view.
 @return A valid BTRCollectionReusableView object.
 @discussion Call this method from your data source object when asked to provide a new supplementary view for the collection view. This method dequeues an existing view if one is available or creates a new one based on the class or nib file you previously registered.
 
 @warning *Important:* You must register a class or nib file using the registerClass:forSupplementaryViewOfKind:withReuseIdentifier: or registerNib:forSupplementaryViewOfKind:withReuseIdentifier: method before calling this method. You can also register a set of default supplementary views with the layout object using the registerClass:forDecorationViewOfKind: or registerNib:forDecorationViewOfKind: method.
 
 If you registered a class for the specified identifier and a new cell must be created, this method initializes the cell by calling its initWithFrame: method. For nib-based cells, this method loads the cell object from the provided nib file. If an existing cell was available for reuse, this method calls the cell’s prepareForReuse method instead.
 */
- (id)dequeueReusableSupplementaryViewOfKind:(NSString *)elementKind withReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

/** @name Reloading Content */

/**
 Reloads all of the data for the collection view.
 @discussion Call this method to reload all of the items in the collection view. This causes the collection view to discard any currently visible items and redisplay them. For efficiency, the collection view only displays those cells and supplementary views that are visible. If the collection data shrinks as a result of the reload, the collection view adjusts its scrolling offsets accordingly.
 
 You should not call this method in the middle of animation blocks where items are being inserted or deleted. Insertions and deletions automatically cause the table’s data to be updated appropriately.
 */
- (void)reloadData;

/**
 Reloads the data in the specified sections of the collection view.
 @param sections The indexes of the sections to reload.
 @discussion Call this method to selectively reload only the items in the specified sections. This causes the collection view to discard any cells associated with those items and redisplay them.
 */
- (void)reloadSections:(NSIndexSet *)sections;

/**
 Reloads just the items at the specified index paths.
 @param indexPaths An array of NSIndexPath objects identifying the items you want to update.
 @discussion Call this method to selectively reload only the specified items. This causes the collection view to discard any cells associated with those items and redisplay them.
 */
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;

/** @name Getting the State of the Collection View */

/** 
 Returns the number of sections displayed by the collection view.
 @return The number of sections in the collection view.
 */
- (NSUInteger)numberOfSections;

/**
 Returns the number of items in the specified section.
 @param section The index of the section for which you want a count of the items.
 @return The number of items in the specified section.
 */
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;

/** 
 Returns an array of visible cells currently displayed by the collection view.
 @return An array of BTRCollectionViewCell objects. If no cells are visible, this method returns an empty array.
 @discussion This method returns the complete list of visible cells displayed by the collection view.
 */
- (NSArray *)visibleCells;

/** @name Inserting, Moving, and Deleting Items */

/**
 Inserts new items at the specified index paths.
 @param indexPaths An array of NSIndexPath objects, each of which contains a section index and item index at which to insert a new cell. This parameter must not be nil.
 @discussion Call this method to insert one or more new items into the collection view. You might do this when your data source object receives data for new items or in response to user interactions with the collection view. The collection view gets the layout information for the new cells as part of calling this method. And if the layout information indicates that the cells should appear onscreen, the collection view asks your data source to provide the appropriate views, animating them into position as needed.
 
 You can also call this method from a block passed to the `performBatchUpdates:completion:` method when you want to animate multiple separate changes into place at the same time. See the description of that method for more information.
 */
- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths;

/**
 Moves an item from one location to another in the collection view.
 @param indexPath The index path of the item you want to move. This parameter must not be nil.
 @param newIndexPath The index path of the item’s new location. This parameter must not be nil.
 @discussion Use this method to reorganize existing data items. You might do this when you rearrange the items within your data source object or in response to user interactions with the collection view. You can move items between sections or within the same section. The collection view updates the layout as needed to account for the move, animating cells into position as needed.
 
 You can also call this method from a block passed to the `performBatchUpdates:completion:` method when you want to animate multiple separate changes into place at the same time. See the description of that method for more information.
 */
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

/**
 Deletes the items at the specified index paths.
 @param indexPaths An array of NSIndexPath objects, each of which contains a section index and item index for the item you want to delete from the collection view. This parameter must not be nil.
 @discussion Use this method to remove items from the collection view. You might do this when you remove the items from your data source object or in response to user interactions with the collection view. The collection view updates the layout of the remaining items to account for the deletions, animating the remaining items into position as needed.
 
 You can also call this method from a block passed to the `performBatchUpdates:completion:` method when you want to animate multiple separate changes into place at the same time. See the description of that method for more information.
 */
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths;

/** @name Inserting, Moving, and Deleting Sections */

/**
 Inserts new sections at the specified indexes.
 @param sections An array of NSIndexPath objects, each of which contains the index of a section you want to insert. This parameter must not be nil.
 @discussion Use this method to insert one or more sections into the collection view. This method adds the sections, and it is up to your data source to report the number of items in each section when asked for the information. The collection view then uses that information to get updated layout attributes for the newly inserted sections and items. If the insertions cause a change in the collection view’s visible content, those changes are animated into place.
 
 You can also call this method from a block passed to the `performBatchUpdates:completion:` method when you want to animate multiple separate changes into place at the same time. See the description of that method for more information.
 */
- (void)insertSections:(NSIndexSet *)sections;

/**
 Moves a section from one location to another in the collection view.
 @param section The index path of the section you want to move. This parameter must not be nil.
 @param newSection The index path of the section’s new location. This parameter must not be nil.
 @param discussion Use this method to reorganize existing sections and their contained items. You might do this when you rearrange sections within your data source object or in response to user interactions with the collection view. The collection view updates the layout as needed to account for the move, animating new views into position as needed.
 
 You can also call this method from a block passed to the `performBatchUpdates:completion:` method when you want to animate multiple separate changes into place at the same time. See the description of that method for more information.
 */
- (void)moveSection:(NSUInteger)section toSection:(NSUInteger)newSection;

/**
 Deletes the sections at the specified indexes.
 @param sections The indexes of the sections you want to delete. This parameter must not be nil.
 @discussion Use this method to remove the sections and their items from the collection view. You might do this when you remove the sections from your data source object or in response to user interactions with the collection view. The collection view updates the layout of the remaining sections and items to account for the deletions, animating the remaining items into position as needed.
 
 You can also call this method from a block passed to the performBatchUpdates:completion: method when you want to animate multiple separate changes into place at the same time. See the description of that method for more information.
 */
- (void)deleteSections:(NSIndexSet *)sections;

/** @name Managing the Selection */

/**
 A Boolean value that indicates whether users can select items in the collection view.
 @discussion If the value of this property is YES (the default), users can select items. If you want more fine-grained control over the selection of items, you must provide a delegate object and implement the appropriate methods of the BTRCollectionViewDelegate protocol.
 */
@property (nonatomic) BOOL allowsSelection;

/**
 A Boolean value that determines whether users can select more than one item in the collection view.
 @discussion This property controls whether multiple items can be selected simultaneously. The default value of this property is NO.
 
 When the value of this property is YES, tapping a cell adds it to the current selection (assuming the delegate permits the cell to be selected). Tapping the cell again removes it from the selection.
 */
@property (nonatomic) BOOL allowsMultipleSelection;

/**
 A Boolean value that determines whether selections and highlighting are animated. 
 @discussion This property controls the animation behaviour of cell selection. The default value of this property is NO.
 */
@property (nonatomic) BOOL animatesSelection;

/**
 Returns the index paths for the selected items.
 @return An array of NSIndexPath objects, each of which corresponds to a single selected item. If there are no selected items, this method returns an empty array.
 */
- (NSArray *)indexPathsForSelectedItems;

/**
 Selects the item at the specified index path and optionally scrolls it into view.
 @param indexPath The index path of the item to select. Specifying nil for this parameter clears the current selection.
 @param animated Specify YES to animate the change in the selection or NO to make the change without animating it.
 @param scrollPosition An option that specifies where the item should be positioned when scrolling finishes. For a list of possible values, see “BTRCollectionViewScrollPosition”.
 @discussion If the `allowsSelection` property is NO, calling this method has no effect. If there is an existing selection with a different index path and the `allowsMultipleSelection` property is NO, calling this method replaces the previous selection.
 
 This method does not cause any selection-related delegate methods to be called.
 */
- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition;

/**
 Deselects the item at the specified index.
 @param indexPath The index path of the item to select. Specifying nil for this parameter removes the current selection.
 @param animated Specify YES to animate the change in the selection or NO to make the change without animating it.
 @discussion If the `allowsSelection` property is NO, calling this method has no effect.
 
 This method does not cause any selection-related delegate methods to be called.
 */
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

/** @name Locating Items in the Collection View */

/**
 Returns the index path of the item at the specified point in the collection view.
 @param point A point in the collection view’s coordinate system.
 @return The index path of the item at the specified point or nil if no item was found at the specified point.
 @discussion This method relies on the layout information provided by the associated layout object to determine which item contains the point.
 */
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;

/**
 Returns an array of the visible items in the collection view.
 @return An array of NSIndexPath objects, each of which corresponds to a visible cell in the collection view. This array does not include any supplementary views that are currently visible. If there are no visible items, this method returns an empty array.
 */
- (NSArray *)indexPathsForVisibleItems;

/**
 Returns the index path of the specified cell.
 @param cell The cell object whose index path you want.
 @return The index path of the cell or nil if the specified cell is not in the collection view.
 */
- (NSIndexPath *)indexPathForCell:(BTRCollectionViewCell *)cell;

/**
 Returns the cell object at the specified index path.
 @param indexPath The index path that specifies the section and item number of the cell.
 @return The cell object at the corresponding index path or nil if no cell was found at that location.
 */
- (BTRCollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;

/** @name Getting Layout Information */

/**
 Returns the layout information for the item at the specified index path.
 @param indexPath The index path of the item.
 @return The layout attributes for the item or nil if no item exists at the specified path.
 @discussion Use this method to retrieve the layout information for a particular item. You should always use this method instead of querying the layout object directly.
 */
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 Returns the layout information for the specified supplementary view.
 @param kind A string specifying the kind of supplementary view whose layout attributes you want. Layout classes are responsible for defining the kinds of supplementary views they support.
 @param indexPath The index path of the supplementary view. The interpretation of this value depends on how the layout implements the view. For example, a view associated with a section might contain just a section value.
 @return The layout attributes of the supplementary view or nil if the specified supplementary view does not exist.
 @discussion Use this method to retrieve the layout information for a particular supplementary view. You should always use this method instead of querying the layout object directly.
 */
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

/** @name Scrolling an Item Into View */

/**
 Scrolls the collection view contents until the specified item is visible.
 @param indexPath The index path of the item to scroll into view.
 @param scrollPosition An option that specifies where the item should be positioned when scrolling finishes. For a list of possible values, see “BTRCollectionViewScrollPosition”.
 @param animated Specify YES to animate the scrolling behavior or NO to adjust the scroll view’s visible content immediately.
 */
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(BTRCollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;

/** @name Animating Multiple Changes to the Collection View **/

/**
 Animates multiple insert, delete, reload, and move operations as a group.
 @param updates The block that performs the relevant insert, delete, reload, or move operations.
 @param completion A completion handler block to execute when all of the operations are finished. This block takes a single Boolean parameter that contains the value YES if all of the related animations completed successfully or NO if they were interrupted. This parameter may be nil.
 @discussion You can use this method in cases where you want to insert, delete, reload or move cells around the collection view in one single animated operation, as opposed to in several separate animations. Use the blocked passed in the updates parameter to specify all of the operations you want to perform.
 
 When you group operations to insert, delete, reload, or move sections inside a single batch job, all operations are performed based on the current indexes of the collection view. This is unlike modifying a mutable array where the insertion or deletion of items affects the indexes of successive operations. Therefore, you do not have to remember which items or sections were inserted, deleted, or moved and adjust the indexes of all other operations accordingly.
 */
- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(void))completion;

@end

extern NSString *const BTRCollectionElementKindCell;
extern NSString *const BTRCollectionElementKindDecorationView;

@interface BTRCollectionViewData : NSObject
/// Designated initializer.
- (id)initWithCollectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)layout;
// Ensure data is valid. may fetches items from dataSource and layout.
- (void)validateLayoutInRect:(CGRect)rect;
- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)globalIndexForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItemAtGlobalIndex:(NSUInteger)index;
// Fetch layout attributes
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect;
// Make data to re-evaluate dataSources.
- (void)invalidate;
// Access cached item data
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;
- (NSUInteger)numberOfItems;
- (NSUInteger)numberOfSections;
// Total size of the content.
- (CGRect)collectionViewContentRect;
@property (readonly) BOOL layoutIsPrepared;
@end

typedef NS_ENUM(NSInteger, BTRCollectionUpdateAction) {
    BTRCollectionUpdateActionInsert,
    BTRCollectionUpdateActionDelete,
    BTRCollectionUpdateActionReload,
    BTRCollectionUpdateActionMove,
    BTRCollectionUpdateActionNone
};

@interface BTRCollectionViewUpdateItem : NSObject
@property (nonatomic, readonly, strong) NSIndexPath *indexPathBeforeUpdate;
@property (nonatomic, readonly, strong) NSIndexPath *indexPathAfterUpdate;
@property (nonatomic, readonly, assign) BTRCollectionUpdateAction updateAction;
- (id)initWithInitialIndexPath:(NSIndexPath *)initialIndexPath
                finalIndexPath:(NSIndexPath *)finalIndexPath
                  updateAction:(BTRCollectionUpdateAction)updateAction;
- (id)initWithAction:(BTRCollectionUpdateAction)updateAction
        forIndexPath:(NSIndexPath *)indexPath;
- (NSComparisonResult)compareIndexPaths:(BTRCollectionViewUpdateItem*) otherItem;
- (NSComparisonResult)inverseCompareIndexPaths:(BTRCollectionViewUpdateItem*) otherItem;
- (BOOL)isSectionOperation;
@end

@interface BTRCollectionViewItemKey : NSObject <NSCopying>
+ (id)collectionItemKeyForLayoutAttributes:(BTRCollectionViewLayoutAttributes *)layoutAttributes;
+ (id)collectionItemKeyForDecorationViewOfKind:(NSString *)elementKind andIndexPath:(NSIndexPath *)indexPath;
+ (id)collectionItemKeyForSupplementaryViewOfKind:(NSString *)elementKind andIndexPath:(NSIndexPath *)indexPath;
+ (id)collectionItemKeyForCellWithIndexPath:(NSIndexPath *)indexPath;
@property (nonatomic, assign) BTRCollectionViewItemType type;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSString *identifier;
@end