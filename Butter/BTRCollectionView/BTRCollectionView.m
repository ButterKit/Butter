//
//  BTRCollectionView.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#import "BTRCollectionView.h"
#import "BTRCollectionViewCell.h"
#import "BTRCollectionViewLayout.h"
#import "BTRCollectionViewFlowLayout.h"

NSString *const BTRCollectionElementKindCell = @"BTRCollectionElementKindCell";
NSString *const BTRCollectionElementKindDecorationView = @"BTRCollectionElementKindDecorationView";

@interface BTRCollectionViewLayout (Internal)
@property (nonatomic, unsafe_unretained) BTRCollectionView *collectionView;
@end

@interface BTRCollectionViewData (Internal)
- (void)prepareToLoadData;
@end

@interface BTRCollectionView() {
    // Collection view layout
    BTRCollectionViewLayout *_layout;
	// Collection view data source
    __unsafe_unretained id<BTRCollectionViewDataSource> _dataSource;
	// Background view displayed beneath the collection view
    NSView *_backgroundView;
	// Set of index paths for the selected items
    NSMutableSet *_indexPathsForSelectedItems;
	// Reuse queues for collection view cells
    NSMutableDictionary *_cellReuseQueues;
	// Reuse queues for collection view supplementary views
    NSMutableDictionary *_supplementaryViewReuseQueues;
	// Set of items that are highlighted (highlighted state comes before selected)
    NSMutableSet *_indexPathsForHighlightedItems;
	// Tracks the state of reload suspension
    NSInteger _reloadingSuspendedCount;
	// Dictionary containing all views visible on screen
    NSMutableDictionary *_allVisibleViewsDict;
	// Container class that stores the layout data for the collection view
    BTRCollectionViewData *_collectionViewData;
	// Stores the information associated with an update of the collection view's items
    NSDictionary *_update;
	// Keeps track of state for item animations
    NSInteger _updateCount;
	// Temporary array of items that are inserted
    NSMutableArray *_insertItems;
	// Temporary array of items that are deleted
    NSMutableArray *_deleteItems;
	// Temporary array of items that are reloaded
    NSMutableArray *_reloadItems;
	// Temporary array of items that are moved
    NSMutableArray *_moveItems;
	// The original array of inserted items before the array is mutated
    NSArray *_originalInsertItems;
	// The original array of deleted items before the array is mutaed
    NSArray *_originalDeleteItems;
	// Block that is executed when updates to the collection view have been completed
    void (^_updateCompletionHandler)();
	// Maps cell classes to reuse identifiers
    NSMutableDictionary *_cellClassDict;
	// Maps cell nibs to reuse identifiers
    NSMutableDictionary *_cellNibDict;
	// Maps supplementary view classes to reuse identifiers
    NSMutableDictionary *_supplementaryViewClassDict;
	// Maps supplementary view nibs to reuse identifiers
    NSMutableDictionary *_supplementaryViewNibDict;
    struct {
		// Tracks which methods the delegate and data source implement
        unsigned int delegateShouldHighlightItemAtIndexPath : 1;
        unsigned int delegateDidHighlightItemAtIndexPath : 1;
        unsigned int delegateDidUnhighlightItemAtIndexPath : 1;
        unsigned int delegateShouldSelectItemAtIndexPath : 1;
        unsigned int delegateShouldDeselectItemAtIndexPath : 1;
        unsigned int delegateDidSelectItemAtIndexPath : 1;
        unsigned int delegateDidDeselectItemAtIndexPath : 1;
        unsigned int delegateSupportsMenus : 1;
        unsigned int delegateDidEndDisplayingCell : 1;
        unsigned int delegateDidEndDisplayingSupplementaryView : 1;
        unsigned int dataSourceNumberOfSections : 1;
        unsigned int dataSourceViewForSupplementaryElement : 1;
		// Collection view options
        unsigned int allowsSelection : 1;
        unsigned int allowsMultipleSelection : 1;
		// Tracks collection view state
        unsigned int updating : 1;
        unsigned int updatingLayout : 1;
        unsigned int needsReload : 1;
        unsigned int reloading : 1;
		unsigned int doneFirstLayout : 1;
    } _collectionViewFlags;
    
}
// Stores all the data associated with collection view layout
@property (nonatomic, strong) BTRCollectionViewData *collectionViewData;
// Mapped to the ivar _allVisibleViewsDict (dictionary of all visible views)
@property (nonatomic, readonly) NSDictionary *visibleViewsDict;
// The total content size of the collection view, used to set the view's frame size
@property (nonatomic, assign) CGSize contentSize;
// The index path that was clicked (set on mouseDown:)
@property (nonatomic, strong) NSIndexPath *clickedIndexPath;
@end

@implementation BTRCollectionView

@synthesize collectionViewLayout = _layout;
@synthesize visibleViewsDict = _allVisibleViewsDict;

#pragma mark - NSObject

- (void)BTRCollectionViewCommonSetup
{
	// Allocate storage variables, configure default settings
    self.allowsSelection = YES;
    _indexPathsForSelectedItems = [NSMutableSet new];
    _indexPathsForHighlightedItems = [NSMutableSet new];
    _cellReuseQueues = [NSMutableDictionary new];
    _supplementaryViewReuseQueues = [NSMutableDictionary new];
    _allVisibleViewsDict = [NSMutableDictionary new];
    _cellClassDict = [NSMutableDictionary new];
    _cellNibDict = [NSMutableDictionary new];
    _supplementaryViewClassDict = [NSMutableDictionary new];
	_supplementaryViewNibDict = [NSMutableDictionary new];
	
	// Make the view layer backed and set the redraw policy so that
	// the view is only redrawn when -setNeedsDisplay:YES is called
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor blueColor].CGColor;
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(BTRCollectionViewLayout *)layout {
    if ((self = [super initWithFrame:frame])) {
        [self BTRCollectionViewCommonSetup];
        self.collectionViewLayout = layout;
        _collectionViewData = [[BTRCollectionViewData alloc] initWithCollectionView:self layout:layout];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)inCoder {
    if ((self = [super initWithCoder:inCoder])) {
        [self BTRCollectionViewCommonSetup];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ collection view layout: %@",
			[super description],
			self.collectionViewLayout];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - NSView

- (BOOL)isFlipped
{
	// This view uses a flipped coordinate system with the origin at the top left corner
    return YES;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [super viewWillMoveToSuperview:newSuperview];
	// The collection view should always be placed inside a scroll view
	// Hence, it's superview should be an NSClipView
    if ([newSuperview isKindOfClass:[NSClipView class]]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        if (self.superview && [self.superview isKindOfClass:[NSClipView class]]) {
            self.superview.postsBoundsChangedNotifications = NO;
            [nc removeObserver:self name:NSViewBoundsDidChangeNotification object:self.superview];
        }
		// Tell the clip view to post bounds changed notifications so that notifications are posted
		// when the view is scrolled
        NSClipView *clipView = (NSClipView *)newSuperview;
        clipView.postsBoundsChangedNotifications = YES;
		// Register for that notification and trigger layout
        [nc addObserverForName:NSViewBoundsDidChangeNotification object:clipView queue:nil usingBlock:^(NSNotification *note) {
            [self setNeedsLayout:YES];
        }];
    }
}

- (void)layout {
    [super layout];
	// Validate the layout inside the currently visible rectangle
    [_collectionViewData validateLayoutInRect:self.visibleRect];
	// Update the visible cells 
    if (!_collectionViewFlags.updatingLayout) [self updateVisibleCellsNow:YES];
	// Check if the content size needs to be reset
    CGSize contentSize = [_collectionViewData collectionViewContentRect].size;
    if (!CGSizeEqualToSize(self.contentSize, contentSize)) {
		// Set the new content size and run layout again
        self.contentSize = contentSize;
        [_collectionViewData validateLayoutInRect:self.visibleRect];
        [self updateVisibleCellsNow:YES];
    }
	// Set the frame of the background view to the visible section of the view
	// This means that the background view moves as a backdrop as the view is scrolled
    if (_backgroundView) {
        _backgroundView.frame = self.visibleRect;
    }
}

- (void)setFrame:(NSRect)frame {
    if (!NSEqualRects(frame, self.frame)) {
		// If the frame is different, check if the layout needs to be invalidated
        if ([self.collectionViewLayout shouldInvalidateLayoutForBoundsChange:frame]) {
            [self invalidateLayout];
        }
        [super setFrame:frame];
    }
}


#pragma mark - Public

////////////////////////////////////////////////////////////
/// All of these public methods are documented in the header
////////////////////////////////////////////////////////////

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    NSParameterAssert(cellClass);
    NSParameterAssert(identifier);
    _cellClassDict[identifier] = cellClass;
}

- (void)registerClass:(Class)viewClass forSupplementaryViewOfKind:(NSString *)elementKind withReuseIdentifier:(NSString *)identifier {
    NSParameterAssert(viewClass);
    NSParameterAssert(elementKind);
    NSParameterAssert(identifier);
	NSString *kindAndIdentifier = [NSString stringWithFormat:@"%@/%@", elementKind, identifier];
    _supplementaryViewClassDict[kindAndIdentifier] = viewClass;
}

- (void)registerNib:(NSNib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    NSArray *topLevelObjects = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&topLevelObjects];
	// Check to make sure that the NIB's only top level object is the cell view
    NSAssert(topLevelObjects.count == 1 && [topLevelObjects[0] isKindOfClass:BTRCollectionViewCell.class], @"must contain exactly 1 top level object which is a BTRCollectionViewCell");

    _cellNibDict[identifier] = nib;
}

- (void)registerNib:(NSNib *)nib forSupplementaryViewOfKind:(NSString *)kind withReuseIdentifier:(NSString *)identifier {
    NSArray *topLevelObjects = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&topLevelObjects];
	// Check to make sure that the NIB's only top level object is the supplementary view
    NSAssert(topLevelObjects.count == 1 && [topLevelObjects[0] isKindOfClass:BTRCollectionReusableView.class], @"must contain exactly 1 top level object which is a BTRCollectionReusableView");

	NSString *kindAndIdentifier = [NSString stringWithFormat:@"%@/%@", kind, identifier];
    _supplementaryViewNibDict[kindAndIdentifier] = nib;
}

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
    // Check to see if there is already a reusable cell in the reuse queue
    NSMutableArray *reusableCells = _cellReuseQueues[identifier];
    BTRCollectionViewCell *cell = [reusableCells lastObject];
    if (cell) {
        [reusableCells removeObjectAtIndex:[reusableCells count]-1];
    }else {
		// If a NIB was registered for the cell, instantiate the NIB and retrieve the view from there
        if (_cellNibDict[identifier]) {
            // Cell was registered via registerNib:forCellWithReuseIdentifier:
            NSNib *cellNib = _cellNibDict[identifier];
            NSArray *topLevelObjects = nil;
			[cellNib instantiateWithOwner:self topLevelObjects:&topLevelObjects];
			cell = topLevelObjects[0];
        } else {
			// Otherwise, attempt to create a new cell view from a registered class
            Class cellClass = _cellClassDict[identifier];
            if (cellClass == nil) {
				// Throw an exception if no NIB or Class was registered for the cell class
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Class not registered for identifier %@", identifier] userInfo:nil];
            }
			// Ask the layout to supply the attributes for the new cell
            if (self.collectionViewLayout) {
                BTRCollectionViewLayoutAttributes *attributes = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
                cell = [[cellClass alloc] initWithFrame:attributes.frame];
            } else {
                cell = [cellClass new];
            }
        }
        cell.collectionView = self;
        cell.reuseIdentifier = identifier;
    }
    return cell;
}

- (id)dequeueReusableSupplementaryViewOfKind:(NSString *)elementKind withReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
	// Check to see if there's already a supplementary view of the desired type in the reuse queue
	NSString *kindAndIdentifier = [NSString stringWithFormat:@"%@/%@", elementKind, identifier];
    NSMutableArray *reusableViews = _supplementaryViewReuseQueues[kindAndIdentifier];
    BTRCollectionReusableView *view = [reusableViews lastObject];
    if (view) {
        [reusableViews removeObjectAtIndex:reusableViews.count - 1];
    } else {
		// Otherwise, check to see if a NIB was registered for the view
		// and use that to create an instance of the view
        if (_supplementaryViewNibDict[kindAndIdentifier]) {
            // supplementary view was registered via registerNib:forCellWithReuseIdentifier:
            NSNib *supplementaryViewNib = _supplementaryViewNibDict[kindAndIdentifier];
			NSArray *topLevelObjects = nil;
			[supplementaryViewNib instantiateWithOwner:self topLevelObjects:&topLevelObjects];
			view = topLevelObjects[0];
        } else {
			// Check to see if a class was registered for the view
			Class viewClass = _supplementaryViewClassDict[kindAndIdentifier];
			if (viewClass == nil) {
				// Throw an exception if neither a class nor a NIB was registered
				@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Class not registered for kind/identifier %@", kindAndIdentifier] userInfo:nil];
			}
			if (self.collectionViewLayout) {
				// Ask the collection view for the layout attributes for the view
				BTRCollectionViewLayoutAttributes *attributes = [self.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
				view = [[viewClass alloc] initWithFrame:attributes.frame];
			} else {
				view = [viewClass new];
			}
        }
        view.collectionView = self;
        view.reuseIdentifier = identifier;
    }
    return view;
}


- (NSArray *)allCells {
    return [[_allVisibleViewsDict allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[BTRCollectionViewCell class]];
    }]];
}

- (NSArray *)visibleCells {
    return [[_allVisibleViewsDict allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		// Check if the cell is within the visible rect
        return [evaluatedObject isKindOfClass:[BTRCollectionViewCell class]] && CGRectIntersectsRect(self.visibleRect, [evaluatedObject frame]);
    }]];
}

- (void)reloadData {
	// Don't reload data if reloading has been suspended
    if (_reloadingSuspendedCount != 0) return;
	// Invalidate the layout
    [self invalidateLayout];
	// Remove every view from the collection view and empty the dictionary
    [_allVisibleViewsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSView class]]) {
            [obj removeFromSuperview];
        }
    }];
    [_allVisibleViewsDict removeAllObjects];
	// Deselect everything
    for (NSIndexPath *indexPath in _indexPathsForSelectedItems) {
        BTRCollectionViewCell *selectedCell = [self cellForItemAtIndexPath:indexPath];
        selectedCell.selected = NO;
        selectedCell.highlighted = NO;
    }
    [_indexPathsForSelectedItems removeAllObjects];
    [_indexPathsForHighlightedItems removeAllObjects];
	// Layout
    [self setNeedsLayout:YES];
}


#pragma mark - Query Grid

// A bunch of methods that query the collection view's layout for information

- (NSInteger)numberOfSections {
    return [_collectionViewData numberOfSections];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    return [_collectionViewData numberOfItemsInSection:section];
}

- (BTRCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[self collectionViewLayout] layoutAttributesForItemAtIndexPath:indexPath];
}

- (BTRCollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return [[self collectionViewLayout] layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
}

// Iterate through the keys until a cell with a frame that contains the given point is found
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point {
    __block NSIndexPath *indexPath = nil;
    [_allVisibleViewsDict enumerateKeysAndObjectsWithOptions:kNilOptions usingBlock:^(id key, id obj, BOOL *stop) {
        BTRCollectionViewItemKey *itemKey = (BTRCollectionViewItemKey *)key;
        if (itemKey.type == BTRCollectionViewItemTypeCell) {
            BTRCollectionViewCell *cell = (BTRCollectionViewCell *)obj;
            if (CGRectContainsPoint(cell.frame, point)) {
                indexPath = itemKey.indexPath;
                *stop = YES;
            }
        }
    }];
    return indexPath;
}

// Iterate through the keys until a cell matching the given cell is found
- (NSIndexPath *)indexPathForCell:(BTRCollectionViewCell *)cell {
    __block NSIndexPath *indexPath = nil;
    [_allVisibleViewsDict enumerateKeysAndObjectsWithOptions:kNilOptions usingBlock:^(id key, id obj, BOOL *stop) {
        BTRCollectionViewItemKey *itemKey = (BTRCollectionViewItemKey *)key;
        if (itemKey.type == BTRCollectionViewItemTypeCell) {
            BTRCollectionViewCell *currentCell = (BTRCollectionViewCell *)obj;
            if (currentCell == cell) {
                indexPath = itemKey.indexPath;
                *stop = YES;
            }
        }
    }];
    return indexPath;
}

// Iterate through the keys until a cell with an index path matching the given index path is found
- (BTRCollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    __block BTRCollectionViewCell *cell = nil;
    [_allVisibleViewsDict enumerateKeysAndObjectsWithOptions:0 usingBlock:^(id key, id obj, BOOL *stop) {
        BTRCollectionViewItemKey *itemKey = (BTRCollectionViewItemKey *)key;
        if (itemKey.type == BTRCollectionViewItemTypeCell) {
            if ([itemKey.indexPath isEqual:indexPath]) {
                cell = obj;
                *stop = YES;
            }
        }
    }];
    return cell;
}

// Iterate the views and separate the cells out from the rest
- (NSArray *)indexPathsForVisibleItems {
	NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[_allVisibleViewsDict count]];

	[_allVisibleViewsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		BTRCollectionViewItemKey *itemKey = (BTRCollectionViewItemKey *)key;
        if (itemKey.type == BTRCollectionViewItemTypeCell) {
			[indexPaths addObject:itemKey.indexPath];
		}
	}];

	return indexPaths;
}

// Returns nil or an array of selected index paths
- (NSArray *)indexPathsForSelectedItems {
    return [_indexPathsForSelectedItems allObjects];
}

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(BTRCollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {
	
	// Make sure layout is valid before scrolling
    [self layout];
    BTRCollectionViewLayoutAttributes *layoutAttributes = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
    if (layoutAttributes) {
        CGRect targetRect = layoutAttributes.frame;

        // TODO: Fix this hack to apply proper margins
        if ([self.collectionViewLayout isKindOfClass:[BTRCollectionViewFlowLayout class]]) {
            BTRCollectionViewFlowLayout *flowLayout = (BTRCollectionViewFlowLayout *)self.collectionViewLayout;
            targetRect.size.height += flowLayout.scrollDirection == BTRCollectionViewScrollDirectionVertical ? flowLayout.minimumLineSpacing : flowLayout.minimumInteritemSpacing;
            targetRect.size.width += flowLayout.scrollDirection == BTRCollectionViewScrollDirectionVertical ? flowLayout.minimumInteritemSpacing : flowLayout.minimumLineSpacing;
        }
        [self btr_scrollRectToVisible:targetRect animated:animated];
    }
}

#pragma mark - Mouse Event Handling

// TODO: All of this logic needs an overhaul to support proper desktop highlighting and selecting behaviour

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    CGPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:location];
    if (indexPath) {
        // Deselect all the other cells
        if (!self.allowsMultipleSelection) {
            for (BTRCollectionViewCell* visibleCell in [self allCells]) {
                visibleCell.highlighted = NO;
                visibleCell.selected = NO;
            }
        }
        // Highlight the clicked cell
        [self highlightItemAtIndexPath:indexPath animated:YES scrollPosition:BTRCollectionViewScrollPositionNone notifyDelegate:YES];
        self.clickedIndexPath = indexPath;
    } else {
		// If empty space was clicked, unhighlight everything
		[self unhighlightAllItems];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    // TODO: Implement a dragging rectangle
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    CGPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:location];
    if ([indexPath isEqual:self.clickedIndexPath]) {
		// On mouse down, do the _actual_ selection (highlighting != selecting)
        [self userSelectedItemAtIndexPath:indexPath];
    } else {
		// Reset the selection that was messed up in mouseDown:
		if (!self.allowsMultipleSelection) {
			for (BTRCollectionViewCell *visibleCell in [self allCells]) {
				NSIndexPath* indexPathForVisibleItem = [self indexPathForCell:visibleCell];
				visibleCell.selected = [_indexPathsForSelectedItems containsObject:indexPathForVisibleItem];
			}
		}
    }
	[self unhighlightAllItems];
	self.clickedIndexPath = nil;
}

- (void)userSelectedItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.allowsMultipleSelection && [_indexPathsForSelectedItems containsObject:indexPath]) {
        [self deselectItemAtIndexPath:indexPath animated:YES notifyDelegate:YES];
    }
    else {
        [self selectItemAtIndexPath:indexPath animated:YES scrollPosition:BTRCollectionViewScrollPositionNone notifyDelegate:YES];
    }
}

// select item, notify delegate (internal)
- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition notifyDelegate:(BOOL)notifyDelegate {

    if (self.allowsMultipleSelection && [_indexPathsForSelectedItems containsObject:indexPath]) {

        BOOL shouldDeselect = YES;
        if (notifyDelegate && _collectionViewFlags.delegateShouldDeselectItemAtIndexPath) {
            shouldDeselect = [self.delegate collectionView:self shouldDeselectItemAtIndexPath:indexPath];
        }

        if (shouldDeselect) {
            [self deselectItemAtIndexPath:indexPath animated:animated];

            if (notifyDelegate && _collectionViewFlags.delegateDidDeselectItemAtIndexPath) {
                [self.delegate collectionView:self didDeselectItemAtIndexPath:indexPath];
            }
        }

    } else {
        // either single selection, or wasn't already selected in multiple selection mode
        
        if (!self.allowsMultipleSelection) {
            for (NSIndexPath *selectedIndexPath in [_indexPathsForSelectedItems copy]) {
                if(![indexPath isEqual:selectedIndexPath]) {
                    [self deselectItemAtIndexPath:selectedIndexPath animated:animated notifyDelegate:notifyDelegate];
                }
            }
        }

        BOOL shouldSelect = YES;
        if (notifyDelegate && _collectionViewFlags.delegateShouldSelectItemAtIndexPath) {
            shouldSelect = [self.delegate collectionView:self shouldSelectItemAtIndexPath:indexPath];
        }

        if (shouldSelect) {
            BTRCollectionViewCell *selectedCell = [self cellForItemAtIndexPath:indexPath];
            selectedCell.selected = YES;
            [_indexPathsForSelectedItems addObject:indexPath];

            if (notifyDelegate && _collectionViewFlags.delegateDidSelectItemAtIndexPath) {
                [self.delegate collectionView:self didSelectItemAtIndexPath:indexPath];
            }
        }
    }

    [self unhighlightItemAtIndexPath:indexPath animated:animated notifyDelegate:YES];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition {
    [self selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition notifyDelegate:NO];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    [self deselectItemAtIndexPath:indexPath animated:animated notifyDelegate:NO];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated notifyDelegate:(BOOL)notify {
    if ([_indexPathsForSelectedItems containsObject:indexPath]) {
        BTRCollectionViewCell *selectedCell = [self cellForItemAtIndexPath:indexPath];
        selectedCell.selected = NO;
        [_indexPathsForSelectedItems removeObject:indexPath];

        [self unhighlightItemAtIndexPath:indexPath animated:animated notifyDelegate:notify];

        if (notify && _collectionViewFlags.delegateDidDeselectItemAtIndexPath) {
            [self.delegate collectionView:self didDeselectItemAtIndexPath:indexPath];
        }
    }
}

- (BOOL)highlightItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition notifyDelegate:(BOOL)notifyDelegate {
    BOOL shouldHighlight = YES;
    if (notifyDelegate && _collectionViewFlags.delegateShouldHighlightItemAtIndexPath) {
        shouldHighlight = [self.delegate collectionView:self shouldHighlightItemAtIndexPath:indexPath];
    }

    if (shouldHighlight) {
        BTRCollectionViewCell *highlightedCell = [self cellForItemAtIndexPath:indexPath];
        highlightedCell.highlighted = YES;
        [_indexPathsForHighlightedItems addObject:indexPath];

        if (notifyDelegate && _collectionViewFlags.delegateDidHighlightItemAtIndexPath) {
            [self.delegate collectionView:self didHighlightItemAtIndexPath:indexPath];
        }
    }
    return shouldHighlight;
}

- (void)unhighlightItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated notifyDelegate:(BOOL)notifyDelegate {
    if ([_indexPathsForHighlightedItems containsObject:indexPath]) {
        BTRCollectionViewCell *highlightedCell = [self cellForItemAtIndexPath:indexPath];
        highlightedCell.highlighted = NO;
        [_indexPathsForHighlightedItems removeObject:indexPath];

        if (notifyDelegate && _collectionViewFlags.delegateDidUnhighlightItemAtIndexPath) {
            [self.delegate collectionView:self didUnhighlightItemAtIndexPath:indexPath];
        }
    }
}

- (void)unhighlightAllItems
{
    for (NSIndexPath *indexPath in [_indexPathsForHighlightedItems copy]) {
        [self unhighlightItemAtIndexPath:indexPath animated:NO notifyDelegate:YES];
    }
}

- (void)deselectAllItems
{
	for (NSIndexPath *indexPath in [_indexPathsForSelectedItems copy]) {
		[self deselectItemAtIndexPath:indexPath animated:NO notifyDelegate:NO];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Update Grid

- (void)insertSections:(NSIndexSet *)sections {
    [self updateSections:sections updateAction:BTRCollectionUpdateActionInsert];
}

- (void)deleteSections:(NSIndexSet *)sections {
    [self updateSections:sections updateAction:BTRCollectionUpdateActionInsert];
}

- (void)reloadSections:(NSIndexSet *)sections {
    [self updateSections:sections updateAction:BTRCollectionUpdateActionReload];
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection {
    NSMutableArray *moveUpdateItems = [self arrayForUpdateAction:BTRCollectionUpdateActionMove];
    [moveUpdateItems addObject:
     [[BTRCollectionViewUpdateItem alloc] initWithInitialIndexPath:[NSIndexPath btr_indexPathForItem:NSNotFound inSection:section]
                                                    finalIndexPath:[NSIndexPath btr_indexPathForItem:NSNotFound inSection:newSection]
                                                      updateAction:BTRCollectionUpdateActionMove]];
    if(!_collectionViewFlags.updating) {
        [self setupCellAnimations];
        [self endItemAnimations];
    }
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths {
    [self updateRowsAtIndexPaths:indexPaths updateAction:BTRCollectionUpdateActionInsert];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths {
    [self updateRowsAtIndexPaths:indexPaths updateAction:BTRCollectionUpdateActionDelete];

}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths {
    [self updateRowsAtIndexPaths:indexPaths updateAction:BTRCollectionUpdateActionReload];
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    NSMutableArray* moveUpdateItems = [self arrayForUpdateAction:BTRCollectionUpdateActionMove];
    [moveUpdateItems addObject:
     [[BTRCollectionViewUpdateItem alloc] initWithInitialIndexPath:indexPath
                                                    finalIndexPath:newIndexPath
                                                      updateAction:BTRCollectionUpdateActionMove]];
    if(!_collectionViewFlags.updating) {
        [self setupCellAnimations];
        [self endItemAnimations];
    }

}

- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(void))completion {
    if(!updates) return;
    
    [self setupCellAnimations];

    updates();
    
    if(completion) _updateCompletionHandler = completion;
        
    [self endItemAnimations];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Properties

- (void)setBackgroundView:(NSView *)backgroundView {
    if (backgroundView != _backgroundView) {
        [_backgroundView removeFromSuperview];
        _backgroundView = backgroundView;
        backgroundView.frame = self.visibleRect;
        backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:backgroundView positioned:NSWindowBelow relativeTo:nil];
    }
}

- (void)setCollectionViewLayout:(BTRCollectionViewLayout *)layout animated:(BOOL)animated {
    if (layout == _layout) return;

    // not sure it was it original code, but here this prevents crash
    // in case we switch layout before previous one was initially loaded
    if (CGRectIsEmpty(self.bounds) || !_collectionViewFlags.doneFirstLayout) {
        _layout.collectionView = nil;
        _collectionViewData = [[BTRCollectionViewData alloc] initWithCollectionView:self layout:layout];
        layout.collectionView = self;
        _layout = layout;
        [self setNeedsDisplay:YES];
    }
    else {
        layout.collectionView = self;
        
        _collectionViewData = [[BTRCollectionViewData alloc] initWithCollectionView:self layout:layout];
        [_collectionViewData prepareToLoadData];

        NSArray *previouslySelectedIndexPaths = [self indexPathsForSelectedItems];
        NSMutableSet *selectedCellKeys = [NSMutableSet setWithCapacity:[previouslySelectedIndexPaths count]];
        
        for(NSIndexPath *indexPath in previouslySelectedIndexPaths) {
            [selectedCellKeys addObject:[BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath]];
        }
        
        NSArray *previouslyVisibleItemsKeys = [_allVisibleViewsDict allKeys];
        NSSet *previouslyVisibleItemsKeysSet = [NSSet setWithArray:previouslyVisibleItemsKeys];
        NSMutableSet *previouslyVisibleItemsKeysSetMutable = [NSMutableSet setWithArray:previouslyVisibleItemsKeys];

        if([selectedCellKeys intersectsSet:selectedCellKeys]) {
            [previouslyVisibleItemsKeysSetMutable intersectSet:previouslyVisibleItemsKeysSetMutable];
        }
        
        NSView *previouslyVisibleView = _allVisibleViewsDict[[previouslyVisibleItemsKeysSetMutable anyObject]];
        [previouslyVisibleView removeFromSuperview];
        [self addSubview:previouslyVisibleView positioned:NSWindowAbove relativeTo:nil];
        
        CGRect rect = [_collectionViewData collectionViewContentRect];
        NSArray *newlyVisibleLayoutAttrs = [_collectionViewData layoutAttributesForElementsInRect:rect];
        
        NSMutableDictionary *layoutInterchangeData = [NSMutableDictionary dictionaryWithCapacity:
                                                     [newlyVisibleLayoutAttrs count] + [previouslyVisibleItemsKeysSet count]];
        
        NSMutableSet *newlyVisibleItemsKeys = [NSMutableSet set];
        for(BTRCollectionViewLayoutAttributes *attr in newlyVisibleLayoutAttrs) {
            BTRCollectionViewItemKey *newKey = [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:attr];
            [newlyVisibleItemsKeys addObject:newKey];
            
            BTRCollectionViewLayoutAttributes *prevAttr = nil;
            BTRCollectionViewLayoutAttributes *newAttr = nil;
            
            if(newKey.type == BTRCollectionViewItemTypeDecorationView) {
                prevAttr = [self.collectionViewLayout layoutAttributesForDecorationViewWithReuseIdentifier:attr.representedElementKind
                                                                                               atIndexPath:newKey.indexPath];
                newAttr = [layout layoutAttributesForDecorationViewWithReuseIdentifier:attr.representedElementKind
                                                                           atIndexPath:newKey.indexPath];
            }
            else if(newKey.type == BTRCollectionViewItemTypeCell) {
                prevAttr = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:newKey.indexPath];
                newAttr = [layout layoutAttributesForItemAtIndexPath:newKey.indexPath];
            }
            else {
                prevAttr = [self.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:attr.representedElementKind
                                                                                     atIndexPath:newKey.indexPath];
                newAttr = [layout layoutAttributesForSupplementaryViewOfKind:attr.representedElementKind
                                                                 atIndexPath:newKey.indexPath];
            }
            
            layoutInterchangeData[newKey] = [NSDictionary dictionaryWithObjects:@[prevAttr,newAttr]
                                                                        forKeys:@[@"previousLayoutInfos", @"newLayoutInfos"]];
        }
        
        for(BTRCollectionViewItemKey *key in previouslyVisibleItemsKeysSet) {
            BTRCollectionViewLayoutAttributes *prevAttr = nil;
            BTRCollectionViewLayoutAttributes *newAttr = nil;
            
            if(key.type == BTRCollectionViewItemTypeDecorationView) {
                BTRCollectionReusableView *decorView = _allVisibleViewsDict[key];
                prevAttr = [self.collectionViewLayout layoutAttributesForDecorationViewWithReuseIdentifier:decorView.reuseIdentifier
                                                                                               atIndexPath:key.indexPath];
                newAttr = [layout layoutAttributesForDecorationViewWithReuseIdentifier:decorView.reuseIdentifier
                                                                           atIndexPath:key.indexPath];
            }
            else if(key.type == BTRCollectionViewItemTypeCell) {
                prevAttr = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:key.indexPath];
                newAttr = [layout layoutAttributesForItemAtIndexPath:key.indexPath];
            }
            else {
                BTRCollectionReusableView* suuplView = _allVisibleViewsDict[key];
                prevAttr = [self.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:suuplView.layoutAttributes.representedElementKind
                                                                                     atIndexPath:key.indexPath];
                newAttr = [layout layoutAttributesForSupplementaryViewOfKind:suuplView.layoutAttributes.representedElementKind
                                                                 atIndexPath:key.indexPath];
            }
            
            layoutInterchangeData[key] = [NSDictionary dictionaryWithObjects:@[prevAttr,newAttr]
                                                                     forKeys:@[@"previousLayoutInfos", @"newLayoutInfos"]];
        }

        for(BTRCollectionViewItemKey *key in [layoutInterchangeData keyEnumerator]) {
            if(key.type == BTRCollectionViewItemTypeCell) {
                BTRCollectionViewCell* cell = _allVisibleViewsDict[key];
                
                if (!cell) {
                    cell = [self createPreparedCellForItemAtIndexPath:key.indexPath
                                                 withLayoutAttributes:layoutInterchangeData[key][@"previousLayoutInfos"]];
                    _allVisibleViewsDict[key] = cell;
                    [self addControlledSubview:cell];
                }
                else [cell applyLayoutAttributes:layoutInterchangeData[key][@"previousLayoutInfos"]];
            }
            else if(key.type == BTRCollectionViewItemTypeSupplementaryView) {
                BTRCollectionReusableView *view = _allVisibleViewsDict[key];
                if (!view) {
                    BTRCollectionViewLayoutAttributes *attrs = layoutInterchangeData[key][@"previousLayoutInfos"];
                    view = [self createPreparedSupplementaryViewForElementOfKind:attrs.representedElementKind
                                                                     atIndexPath:attrs.indexPath
                                                            withLayoutAttributes:attrs];
                }
            }
        };
        
        CGRect contentRect = [_collectionViewData collectionViewContentRect];

        [self setContentSize:contentRect.size];
        [self scrollPoint:contentRect.origin];
        
        void (^applyNewLayoutBlock)(void) = ^{
            NSEnumerator *keys = [layoutInterchangeData keyEnumerator];
            for(BTRCollectionViewItemKey *key in keys) {
                [(BTRCollectionViewCell *)_allVisibleViewsDict[key] applyLayoutAttributes:layoutInterchangeData[key][@"newLayoutInfos"]];
            }
        };
        
        void (^freeUnusedViews)(void) = ^ {
            for(BTRCollectionViewItemKey *key in [_allVisibleViewsDict keyEnumerator]) {
                if(![newlyVisibleItemsKeys containsObject:key]) {
                    if(key.type == BTRCollectionViewItemTypeCell) [self reuseCell:_allVisibleViewsDict[key]];
                    else if(key.type == BTRCollectionViewItemTypeSupplementaryView)
                        [self reuseSupplementaryView:_allVisibleViewsDict[key]];
                }
            }
        };
        
        if(animated) {
            [NSView btr_animateWithDuration:.3 animations:^ {
                 _collectionViewFlags.updatingLayout = YES;
                 applyNewLayoutBlock();
             } completion:^ {
                 freeUnusedViews();
                 _collectionViewFlags.updatingLayout = NO;
             }];
        }
        else {
            applyNewLayoutBlock();
            freeUnusedViews();
        }
        
        _layout.collectionView = nil;
        _layout = layout;
    }
}

- (void)setCollectionViewLayout:(BTRCollectionViewLayout *)layout {
    [self setCollectionViewLayout:layout animated:NO];
}

- (void)setDelegate:(id<BTRCollectionViewDelegate>)delegate {
	//	Managing the Selected Cells
	_collectionViewFlags.delegateShouldSelectItemAtIndexPath       = [self.delegate respondsToSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)];
	_collectionViewFlags.delegateDidSelectItemAtIndexPath          = [self.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)];
	_collectionViewFlags.delegateShouldDeselectItemAtIndexPath     = [self.delegate respondsToSelector:@selector(collectionView:shouldDeselectItemAtIndexPath:)];
	_collectionViewFlags.delegateDidDeselectItemAtIndexPath        = [self.delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)];

	//	Managing Cell Highlighting
	_collectionViewFlags.delegateShouldHighlightItemAtIndexPath    = [self.delegate respondsToSelector:@selector(collectionView:shouldHighlightItemAtIndexPath:)];
	_collectionViewFlags.delegateDidHighlightItemAtIndexPath       = [self.delegate respondsToSelector:@selector(collectionView:didHighlightItemAtIndexPath:)];
	_collectionViewFlags.delegateDidUnhighlightItemAtIndexPath     = [self.delegate respondsToSelector:@selector(collectionView:didUnhighlightItemAtIndexPath:)];

	//	Tracking the Removal of Views
	_collectionViewFlags.delegateDidEndDisplayingCell              = [self.delegate respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)];
	_collectionViewFlags.delegateDidEndDisplayingSupplementaryView = [self.delegate respondsToSelector:@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)];

	//	Managing Actions for Cells
	_collectionViewFlags.delegateSupportsMenus                     = [self.delegate respondsToSelector:@selector(collectionView:shouldShowMenuForItemAtIndexPath:)];

	// These aren't present in the flags which is a little strange. Not adding them because thet will mess with byte alignment which will affect cross compatibility.
	// The flag names are guesses and are there for documentation purposes.
	//
	// _collectionViewFlags.delegateCanPerformActionForItemAtIndexPath	= [self.delegate respondsToSelector:@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)];
	// _collectionViewFlags.delegatePerformActionForItemAtIndexPath		= [self.delegate respondsToSelector:@selector(collectionView:performAction:forItemAtIndexPath:withSender:)];
}

// Might be overkill since two are required and two are handled by BTRCollectionViewData leaving only one flag we actually need to check for
- (void)setDataSource:(id<BTRCollectionViewDataSource>)dataSource {
    if (dataSource != _dataSource) {
		_dataSource = dataSource;

		//	Getting Item and Section Metrics
		_collectionViewFlags.dataSourceNumberOfSections = [_dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)];

		//	Getting Views for Items
		_collectionViewFlags.dataSourceViewForSupplementaryElement = [_dataSource respondsToSelector:@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)];
    }
}

- (BOOL)allowsSelection {
    return _collectionViewFlags.allowsSelection;
}

- (void)setAllowsSelection:(BOOL)allowsSelection {
    _collectionViewFlags.allowsSelection = allowsSelection;
}

- (BOOL)allowsMultipleSelection {
    return _collectionViewFlags.allowsMultipleSelection;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection {
    _collectionViewFlags.allowsMultipleSelection = allowsMultipleSelection;

    // Deselect all objects if allows multiple selection is false
    if (!allowsMultipleSelection && _indexPathsForSelectedItems.count) {

        // Note: Apple's implementation leaves a mostly random item selected. Presumably they
        //       have a good reason for this, but I guess it's just skipping the last or first index.
        for (NSIndexPath *selectedIndexPath in [_indexPathsForSelectedItems copy]) {
            if (_indexPathsForSelectedItems.count == 1) continue;
            [self deselectItemAtIndexPath:selectedIndexPath animated:YES notifyDelegate:YES];
        }
    }
}

- (void)setContentSize:(CGSize)contentSize
{
    if (!CGSizeEqualToSize(_contentSize, contentSize)) {
        [self setFrameSize:contentSize];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (void)invalidateLayout {
    [self.collectionViewLayout invalidateLayout];
    [self.collectionViewData invalidate]; // invalidate layout cache
}

// update currently visible cells, fetches new cells if needed
// TODO: use now parameter.
- (void)updateVisibleCellsNow:(BOOL)now {
    NSArray *layoutAttributesArray = [_collectionViewData layoutAttributesForElementsInRect:self.visibleRect];

    // create ItemKey/Attributes dictionary
    NSMutableDictionary *itemKeysToAddDict = [NSMutableDictionary dictionary];
    for (BTRCollectionViewLayoutAttributes *layoutAttributes in layoutAttributesArray) {
        BTRCollectionViewItemKey *itemKey = [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:layoutAttributes];
        itemKeysToAddDict[itemKey] = layoutAttributes;
    }

    // detect what items should be removed and queued back.
    NSMutableSet *allVisibleItemKeys = [NSMutableSet setWithArray:[_allVisibleViewsDict allKeys]];
    [allVisibleItemKeys minusSet:[NSSet setWithArray:[itemKeysToAddDict allKeys]]];

    // remove views that have not been processed and prepare them for re-use.
    for (BTRCollectionViewItemKey *itemKey in allVisibleItemKeys) {
        BTRCollectionReusableView *reusableView = _allVisibleViewsDict[itemKey];
        if (reusableView) {
            [reusableView removeFromSuperview];
            [_allVisibleViewsDict removeObjectForKey:itemKey];
            if (itemKey.type == BTRCollectionViewItemTypeCell) {
                if (_collectionViewFlags.delegateDidEndDisplayingCell) {
                    [self.delegate collectionView:self didEndDisplayingCell:(BTRCollectionViewCell *)reusableView forItemAtIndexPath:itemKey.indexPath];
                }
                [self reuseCell:(BTRCollectionViewCell *)reusableView];
            }else if(itemKey.type == BTRCollectionViewItemTypeSupplementaryView) {
                if (_collectionViewFlags.delegateDidEndDisplayingSupplementaryView) {
                    [self.delegate collectionView:self didEndDisplayingSupplementaryView:reusableView forElementOfKind:itemKey.identifier atIndexPath:itemKey.indexPath];
                }
                [self reuseSupplementaryView:reusableView];
            }
            // TODO: decoration views etc?
        }
    }

    // finally add new cells.
    [itemKeysToAddDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        BTRCollectionViewItemKey *itemKey = key;
        BTRCollectionViewLayoutAttributes *layoutAttributes = obj;

        // check if cell is in visible dict; add it if not.
        BTRCollectionReusableView *view = _allVisibleViewsDict[itemKey];
        if (!view) {
            if (itemKey.type == BTRCollectionViewItemTypeCell) {
                view = [self createPreparedCellForItemAtIndexPath:itemKey.indexPath withLayoutAttributes:layoutAttributes];

            } else if (itemKey.type == BTRCollectionViewItemTypeSupplementaryView) {
                view = [self createPreparedSupplementaryViewForElementOfKind:layoutAttributes.representedElementKind
																 atIndexPath:layoutAttributes.indexPath
														withLayoutAttributes:layoutAttributes];
            }

			//Supplementary views are optional
			if (view) {
				_allVisibleViewsDict[itemKey] = view;
				[self addControlledSubview:view];
			}
        }else {
            // just update cell
            [view applyLayoutAttributes:layoutAttributes];
        }
    }];
}

// fetches a cell from the dataSource and sets the layoutAttributes
- (BTRCollectionViewCell *)createPreparedCellForItemAtIndexPath:(NSIndexPath *)indexPath withLayoutAttributes:(BTRCollectionViewLayoutAttributes *)layoutAttributes {

    BTRCollectionViewCell *cell = [self.dataSource collectionView:self cellForItemAtIndexPath:indexPath];

    // reset selected/highlight state
    [cell setHighlighted:[_indexPathsForHighlightedItems containsObject:indexPath]];
    [cell setSelected:[_indexPathsForSelectedItems containsObject:indexPath]];

    [cell applyLayoutAttributes:layoutAttributes];
    return cell;
}

- (BTRCollectionReusableView *)createPreparedSupplementaryViewForElementOfKind:(NSString *)kind
																   atIndexPath:(NSIndexPath *)indexPath
														  withLayoutAttributes:(BTRCollectionViewLayoutAttributes *)layoutAttributes {
	if (_collectionViewFlags.dataSourceViewForSupplementaryElement) {
		BTRCollectionReusableView *view = [self.dataSource collectionView:self
										viewForSupplementaryElementOfKind:kind
															  atIndexPath:indexPath];
		[view applyLayoutAttributes:layoutAttributes];
		return view;
	}
	return nil;
}

// @steipete optimization
- (void)queueReusableView:(BTRCollectionReusableView *)reusableView inQueue:(NSMutableDictionary *)queue {
    NSString *cellIdentifier = reusableView.reuseIdentifier;
    NSParameterAssert([cellIdentifier length]);

    [reusableView removeFromSuperview];
    [reusableView prepareForReuse];

    // enqueue cell
    NSMutableArray *reuseableViews = queue[cellIdentifier];
    if (!reuseableViews) {
        reuseableViews = [NSMutableArray array];
        queue[cellIdentifier] = reuseableViews;
    }
    [reuseableViews addObject:reusableView];
}

// enqueue cell for reuse
- (void)reuseCell:(BTRCollectionViewCell *)cell {
    [self queueReusableView:cell inQueue:_cellReuseQueues];
}

// enqueue supplementary view for reuse
- (void)reuseSupplementaryView:(BTRCollectionReusableView *)supplementaryView {
    [self queueReusableView:supplementaryView inQueue:_supplementaryViewReuseQueues];
}

- (void)addControlledSubview:(BTRCollectionReusableView *)subview {
	// avoids placing views above the scroll indicator
    [self addSubview:subview];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Updating grid internal functionality

- (void)suspendReloads {
    _reloadingSuspendedCount++;
}

- (void)resumeReloads {
    _reloadingSuspendedCount--;
}

-(NSMutableArray *)arrayForUpdateAction:(BTRCollectionUpdateAction)updateAction {
    NSMutableArray *ret = nil;

    switch (updateAction) {
        case BTRCollectionUpdateActionInsert:
            if(!_insertItems) _insertItems = [[NSMutableArray alloc] init];
            ret = _insertItems;
            break;
        case BTRCollectionUpdateActionDelete:
            if(!_deleteItems) _deleteItems = [[NSMutableArray alloc] init];
            ret = _deleteItems;
            break;
        case BTRCollectionUpdateActionMove:
            if(_moveItems) _moveItems = [[NSMutableArray alloc] init];
            ret = _moveItems;
            break;
        case BTRCollectionUpdateActionReload:
            if(!_reloadItems) _reloadItems = [[NSMutableArray alloc] init];
            ret = _reloadItems;
            break;
        default: break;
    }
    return ret;
}


- (void)prepareLayoutForUpdates {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [arr addObjectsFromArray: [_originalDeleteItems sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)]];
    [arr addObjectsFromArray:[_originalInsertItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
    [arr addObjectsFromArray:[_reloadItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
    [arr addObjectsFromArray: [_moveItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
    [_layout prepareForCollectionViewUpdates:arr];
}

- (void)updateWithItems:(NSArray *) items {
    [self prepareLayoutForUpdates];
    
    NSMutableArray *animations = [[NSMutableArray alloc] init];
    NSMutableDictionary *newAllVisibleView = [[NSMutableDictionary alloc] init];

    for (BTRCollectionViewUpdateItem *updateItem in items) {
        if (updateItem.isSectionOperation) continue;
        
        if (updateItem.updateAction == BTRCollectionUpdateActionDelete) {
            NSIndexPath *indexPath = updateItem.indexPathBeforeUpdate;
            
            BTRCollectionViewLayoutAttributes *finalAttrs = [_layout finalLayoutAttributesForDisappearingItemAtIndexPath:indexPath];
            BTRCollectionViewItemKey *key = [BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath];
            BTRCollectionReusableView *view = _allVisibleViewsDict[key];
            if (view) {
                BTRCollectionViewLayoutAttributes *startAttrs = view.layoutAttributes;
                
                if (!finalAttrs) {
                    finalAttrs = [startAttrs copy];
                    finalAttrs.alpha = 0;
                }
                [animations addObject:@{@"view": view, @"previousLayoutInfos": startAttrs, @"newLayoutInfos": finalAttrs}];
                [_allVisibleViewsDict removeObjectForKey:key];
            }
        }
        else if(updateItem.updateAction == BTRCollectionUpdateActionInsert) {
            NSIndexPath *indexPath = updateItem.indexPathAfterUpdate;
            BTRCollectionViewItemKey *key = [BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath];
            BTRCollectionViewLayoutAttributes *startAttrs = [_layout initialLayoutAttributesForAppearingItemAtIndexPath:indexPath];
            BTRCollectionViewLayoutAttributes *finalAttrs = [_layout layoutAttributesForItemAtIndexPath:indexPath];
            
            CGRect startRect = CGRectMake(CGRectGetMidX(startAttrs.frame)-startAttrs.center.x,
                                          CGRectGetMidY(startAttrs.frame)-startAttrs.center.y,
                                          startAttrs.frame.size.width,
                                          startAttrs.frame.size.height);
            CGRect finalRect = CGRectMake(CGRectGetMidX(finalAttrs.frame)-finalAttrs.center.x,
                                         CGRectGetMidY(finalAttrs.frame)-finalAttrs.center.y,
                                         finalAttrs.frame.size.width,
                                         finalAttrs.frame.size.height);
            
            if(CGRectIntersectsRect(self.visibleRect, startRect) || CGRectIntersectsRect(self.visibleRect, finalRect)) {
                BTRCollectionReusableView *view = [self createPreparedCellForItemAtIndexPath:indexPath
                                                                        withLayoutAttributes:startAttrs];
                [self addControlledSubview:view];
                
                newAllVisibleView[key] = view;
                [animations addObject:@{@"view": view, @"previousLayoutInfos": startAttrs?startAttrs:finalAttrs, @"newLayoutInfos": finalAttrs}];
            }
        }
        else if(updateItem.updateAction == BTRCollectionUpdateActionMove) {
            NSIndexPath *indexPathBefore = updateItem.indexPathBeforeUpdate;
            NSIndexPath *indexPathAfter = updateItem.indexPathAfterUpdate;
            
            BTRCollectionViewItemKey *keyBefore = [BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPathBefore];
            BTRCollectionViewItemKey *keyAfter = [BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPathAfter];
            BTRCollectionReusableView *view = _allVisibleViewsDict[keyBefore];
            
            BTRCollectionViewLayoutAttributes *startAttrs = nil;
            BTRCollectionViewLayoutAttributes *finalAttrs = [_layout layoutAttributesForItemAtIndexPath:indexPathAfter];
            
            if(view) {
                startAttrs = view.layoutAttributes;
                [_allVisibleViewsDict removeObjectForKey:keyBefore];
                newAllVisibleView[keyAfter] = view;
            }
            else {
                startAttrs = [finalAttrs copy];
                startAttrs.alpha = 0;
                view = [self createPreparedCellForItemAtIndexPath:indexPathAfter withLayoutAttributes:startAttrs];
                [self addControlledSubview:view];
                newAllVisibleView[keyAfter] = view;
            }
            
            [animations addObject:@{@"view": view, @"previousLayoutInfos": startAttrs, @"newLayoutInfos": finalAttrs}];
        }
    }
    
    for (BTRCollectionViewItemKey *key in [_allVisibleViewsDict keyEnumerator]) {
        BTRCollectionReusableView *view = _allVisibleViewsDict[key];
        NSInteger oldGlobalIndex = [_update[@"oldModel"] globalIndexForItemAtIndexPath:key.indexPath];
        NSInteger newGlobalIndex = [_update[@"oldToNewIndexMap"][oldGlobalIndex] intValue];
        NSIndexPath *newIndexPath = [_update[@"newModel"] indexPathForItemAtGlobalIndex:newGlobalIndex];
        
        BTRCollectionViewLayoutAttributes* startAttrs =
        [_layout initialLayoutAttributesForAppearingItemAtIndexPath:newIndexPath];
        
        BTRCollectionViewLayoutAttributes* finalAttrs =
        [_layout layoutAttributesForItemAtIndexPath:newIndexPath];
        
        [animations addObject:@{@"view":view, @"previousLayoutInfos": startAttrs, @"newLayoutInfos": finalAttrs}];
        BTRCollectionViewItemKey* newKey = [key copy];
        [newKey setIndexPath:newIndexPath];
        newAllVisibleView[newKey] = view;
    }

    NSArray *allNewlyVisibleItems = [_layout layoutAttributesForElementsInRect:self.visibleRect];
    for (BTRCollectionViewLayoutAttributes *attrs in allNewlyVisibleItems) {
        BTRCollectionViewItemKey *key = [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:attrs];
        
        if (![[newAllVisibleView allKeys] containsObject:key]) {
            BTRCollectionViewLayoutAttributes* startAttrs =
            [_layout initialLayoutAttributesForAppearingItemAtIndexPath:attrs.indexPath];
            
            BTRCollectionReusableView *view = [self createPreparedCellForItemAtIndexPath:attrs.indexPath
                                                                    withLayoutAttributes:startAttrs];
            [self addControlledSubview:view];
            newAllVisibleView[key] = view;
            
            [animations addObject:@{@"view":view, @"previousLayoutInfos": startAttrs?startAttrs:attrs, @"newLayoutInfos": attrs}];
        }
    }
    
    _allVisibleViewsDict = newAllVisibleView;

    for(NSDictionary *animation in animations) {
        BTRCollectionReusableView *view = animation[@"view"];
        BTRCollectionViewLayoutAttributes *attr = animation[@"previousLayoutInfos"];
        [view applyLayoutAttributes:attr];
    };

    [NSView btr_animateWithDuration:.3 animations:^{
         _collectionViewFlags.updatingLayout = YES;
         for(NSDictionary *animation in animations) {
             BTRCollectionReusableView* view = animation[@"view"];
             BTRCollectionViewLayoutAttributes* attrs = animation[@"newLayoutInfos"];
             [view applyLayoutAttributes:attrs];
         }
     } completion:^ {
         NSMutableSet *set = [NSMutableSet set];
         NSArray *visibleItems = [_layout layoutAttributesForElementsInRect:self.visibleRect];
         for(BTRCollectionViewLayoutAttributes *attrs in visibleItems)
             [set addObject: [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:attrs]];

         NSMutableSet *toRemove =  [NSMutableSet set];
         for(BTRCollectionViewItemKey *key in [_allVisibleViewsDict keyEnumerator]) {
             if(![set containsObject:key]) {
                 [self reuseCell:_allVisibleViewsDict[key]];
                 [toRemove addObject:key];
             }
         }
         for(id key in toRemove)
             [_allVisibleViewsDict removeObjectForKey:key];
         
         _collectionViewFlags.updatingLayout = NO;
         
         if(_updateCompletionHandler) {
             _updateCompletionHandler();
             _updateCompletionHandler = nil;
         }
     }];

    [_layout finalizeCollectionViewUpdates];
}

- (void)setupCellAnimations {
    [self updateVisibleCellsNow:YES];
    [self suspendReloads];
    _collectionViewFlags.updating = YES;
}

- (void)endItemAnimations {
    _updateCount++;
    BTRCollectionViewData *oldCollectionViewData = _collectionViewData;
    _collectionViewData = [[BTRCollectionViewData alloc] initWithCollectionView:self layout:_layout];
    
    [_layout invalidateLayout];
    [_collectionViewData prepareToLoadData];

    NSMutableArray *someMutableArr1 = [[NSMutableArray alloc] init];

    NSArray *removeUpdateItems = [[self arrayForUpdateAction:BTRCollectionUpdateActionDelete]
                                  sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)];
    
    NSArray *insertUpdateItems = [[self arrayForUpdateAction:BTRCollectionUpdateActionInsert]
                                  sortedArrayUsingSelector:@selector(compareIndexPaths:)];

    NSMutableArray *sortedMutableReloadItems = [[_reloadItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
    NSMutableArray *sortedMutableMoveItems = [[_moveItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
    
    _originalDeleteItems = [removeUpdateItems copy];
    _originalInsertItems = [insertUpdateItems copy];

    NSMutableArray *someMutableArr2 = [[NSMutableArray alloc] init];
    NSMutableArray *someMutableArr3 =[[NSMutableArray alloc] init];
    NSMutableDictionary *operations = [[NSMutableDictionary alloc] init];
    
    for(BTRCollectionViewUpdateItem *updateItem in sortedMutableReloadItems) {
        NSAssert(updateItem.indexPathBeforeUpdate.section< [oldCollectionViewData numberOfSections],
                 @"attempt to reload item (%@) that doesn't exist (there are only %ld sections before update)",
                 updateItem.indexPathBeforeUpdate, [oldCollectionViewData numberOfSections]);
        NSAssert(updateItem.indexPathBeforeUpdate.item<[oldCollectionViewData numberOfItemsInSection:updateItem.indexPathBeforeUpdate.section],
                 @"attempt to reload item (%@) that doesn't exist (there are only %ld items in section %ld before udpate)",
                 updateItem.indexPathBeforeUpdate,
                 [oldCollectionViewData numberOfItemsInSection:updateItem.indexPathBeforeUpdate.section],
                 updateItem.indexPathBeforeUpdate.section);
        
        [someMutableArr2 addObject:[[BTRCollectionViewUpdateItem alloc] initWithAction:BTRCollectionUpdateActionDelete
                                                                          forIndexPath:updateItem.indexPathBeforeUpdate]];
        [someMutableArr3 addObject:[[BTRCollectionViewUpdateItem alloc] initWithAction:BTRCollectionUpdateActionInsert
                                                                          forIndexPath:updateItem.indexPathAfterUpdate]];
    }
    
    NSMutableArray *sortedDeletedMutableItems = [[_deleteItems sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)] mutableCopy];
    NSMutableArray *sortedInsertMutableItems = [[_insertItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
    
    for(BTRCollectionViewUpdateItem *deleteItem in sortedDeletedMutableItems) {
        if([deleteItem isSectionOperation]) {
            NSAssert(deleteItem.indexPathBeforeUpdate.section<[oldCollectionViewData numberOfSections],
                     @"attempt to delete section (%ld) that doesn't exist (there are only %ld sections before update)",
                     deleteItem.indexPathBeforeUpdate.section,
                     [oldCollectionViewData numberOfSections]);
            
            for(BTRCollectionViewUpdateItem *moveItem in sortedMutableMoveItems) {
                if(moveItem.indexPathBeforeUpdate.section == deleteItem.indexPathBeforeUpdate.section) {
                    if(moveItem.isSectionOperation)
                        NSAssert(NO, @"attempt to delete and move from the same section %ld", deleteItem.indexPathBeforeUpdate.section);
                    else
                        NSAssert(NO, @"attempt to delete and move from the same section (%@)", moveItem.indexPathBeforeUpdate);
                }
            }
        } else {
            NSAssert(deleteItem.indexPathBeforeUpdate.section<[oldCollectionViewData numberOfSections],
                     @"attempt to delete item (%@) that doesn't exist (there are only %ld sections before update)",
                     deleteItem.indexPathBeforeUpdate,
                     [oldCollectionViewData numberOfSections]);
            NSAssert(deleteItem.indexPathBeforeUpdate.item<[oldCollectionViewData numberOfItemsInSection:deleteItem.indexPathBeforeUpdate.section],
                     @"attempt to delete item (%@) that doesn't exist (there are only %ld items in section %ld before update)",
                     deleteItem.indexPathBeforeUpdate,
                     [oldCollectionViewData numberOfItemsInSection:deleteItem.indexPathBeforeUpdate.section],
                     deleteItem.indexPathBeforeUpdate.section);
            
            for(BTRCollectionViewUpdateItem *moveItem in sortedMutableMoveItems) {
                NSAssert([deleteItem.indexPathBeforeUpdate isEqual:moveItem.indexPathBeforeUpdate],
                         @"attempt to delete and move the same item (%@)", deleteItem.indexPathBeforeUpdate);
            }
            
            if(!operations[@(deleteItem.indexPathBeforeUpdate.section)])
                operations[@(deleteItem.indexPathBeforeUpdate.section)] = [NSMutableDictionary dictionary];
            
            operations[@(deleteItem.indexPathBeforeUpdate.section)][@"deleted"] =
            @([operations[@(deleteItem.indexPathBeforeUpdate.section)][@"deleted"] intValue]+1);
        }
    }
                      
    for(NSInteger i=0; i<[sortedInsertMutableItems count]; i++) {
        BTRCollectionViewUpdateItem *insertItem = sortedInsertMutableItems[i];
        NSIndexPath *indexPath = insertItem.indexPathAfterUpdate;

        BOOL sectionOperation = [insertItem isSectionOperation];
        if(sectionOperation) {
            NSAssert([indexPath section]<[_collectionViewData numberOfSections],
                     @"attempt to insert %ld but there are only %ld sections after update",
                     [indexPath section], [_collectionViewData numberOfSections]);
            
            for(BTRCollectionViewUpdateItem *moveItem in sortedMutableMoveItems) {
                if([moveItem.indexPathAfterUpdate isEqual:indexPath]) {
                    if(moveItem.isSectionOperation)
                        NSAssert(NO, @"attempt to perform an insert and a move to the same section (%ld)",indexPath.section);
//                    else
//                        NSAssert(NO, @"attempt to perform an insert and a move to the same index path (%@)",indexPath);
                }
            }
            
            NSInteger j=i+1;
            while(j<[sortedInsertMutableItems count]) {
                BTRCollectionViewUpdateItem *nextInsertItem = sortedInsertMutableItems[j];
                
                if(nextInsertItem.indexPathAfterUpdate.section == indexPath.section) {
                    NSAssert(nextInsertItem.indexPathAfterUpdate.item<[_collectionViewData numberOfItemsInSection:indexPath.section],
                             @"attempt to insert item %ld into section %ld, but there are only %ld items in section %ld after the update",
                             nextInsertItem.indexPathAfterUpdate.item,
                             indexPath.section,
                             [_collectionViewData numberOfItemsInSection:indexPath.section],
                             indexPath.section);
                    [sortedInsertMutableItems removeObjectAtIndex:j];
                }
                else break;
            }
        } else {
            NSAssert(indexPath.item< [_collectionViewData numberOfItemsInSection:indexPath.section],
                     @"attempt to insert item to (%@) but there are only %ld items in section %ld after update",
                     indexPath,
                     [_collectionViewData numberOfItemsInSection:indexPath.section],
                     indexPath.section);
            
            if(!operations[@(indexPath.section)])
                operations[@(indexPath.section)] = [NSMutableDictionary dictionary];

            operations[@(indexPath.section)][@"inserted"] =
            @([operations[@(indexPath.section)][@"inserted"] intValue]+1);
        }
    }

    for(BTRCollectionViewUpdateItem * sortedItem in sortedMutableMoveItems) {
        if(sortedItem.isSectionOperation) {
            NSAssert(sortedItem.indexPathBeforeUpdate.section<[oldCollectionViewData numberOfSections],
                     @"attempt to move section (%ld) that doesn't exist (%ld sections before update)",
                     sortedItem.indexPathBeforeUpdate.section,
                     [oldCollectionViewData numberOfSections]);
            NSAssert(sortedItem.indexPathAfterUpdate.section<[_collectionViewData numberOfSections],
                     @"attempt to move section to %ld but there are only %ld sections after update",
                     sortedItem.indexPathAfterUpdate.section,
                     [_collectionViewData numberOfSections]);
        } else {
            NSAssert(sortedItem.indexPathBeforeUpdate.section<[oldCollectionViewData numberOfSections],
                     @"attempt to move item (%@) that doesn't exist (%ld sections before update)",
                     sortedItem, [oldCollectionViewData numberOfSections]);
            NSAssert(sortedItem.indexPathBeforeUpdate.item<[oldCollectionViewData numberOfItemsInSection:sortedItem.indexPathBeforeUpdate.section],
                     @"attempt to move item (%@) that doesn't exist (%ld items in section %ld before update)",
                     sortedItem,
                     [oldCollectionViewData numberOfItemsInSection:sortedItem.indexPathBeforeUpdate.section],
                     sortedItem.indexPathBeforeUpdate.section);
            
            NSAssert(sortedItem.indexPathAfterUpdate.section<[_collectionViewData numberOfSections],
                     @"attempt to move item to (%@) but there are only %ld sections after update",
                     sortedItem.indexPathAfterUpdate,
                     [_collectionViewData numberOfSections]);
            NSAssert(sortedItem.indexPathAfterUpdate.item<[_collectionViewData numberOfItemsInSection:sortedItem.indexPathAfterUpdate.section],
                     @"attempt to move item to (%@) but there are only %ld items in section %ld after update",
                     sortedItem,
                     [_collectionViewData numberOfItemsInSection:sortedItem.indexPathAfterUpdate.section],
                     sortedItem.indexPathAfterUpdate.section);
        }
        
        if(!operations[@(sortedItem.indexPathBeforeUpdate.section)])
            operations[@(sortedItem.indexPathBeforeUpdate.section)] = [NSMutableDictionary dictionary];
        if(!operations[@(sortedItem.indexPathAfterUpdate.section)])
            operations[@(sortedItem.indexPathAfterUpdate.section)] = [NSMutableDictionary dictionary];
        
        operations[@(sortedItem.indexPathBeforeUpdate.section)][@"movedOut"] =
        @([operations[@(sortedItem.indexPathBeforeUpdate.section)][@"movedOut"] intValue]+1);

        operations[@(sortedItem.indexPathAfterUpdate.section)][@"movedIn"] =
        @([operations[@(sortedItem.indexPathAfterUpdate.section)][@"movedIn"] intValue]+1);
    }

#if !defined  NS_BLOCK_ASSERTIONS
    for(NSNumber *sectionKey in [operations keyEnumerator]) {
        NSInteger section = [sectionKey intValue];
        
        NSInteger insertedCount = [operations[sectionKey][@"inserted"] intValue];
        NSInteger deletedCount = [operations[sectionKey][@"deleted"] intValue];
        NSInteger movedInCount = [operations[sectionKey][@"movedIn"] intValue];
        NSInteger movedOutCount = [operations[sectionKey][@"movedOut"] intValue];
        
        NSAssert([oldCollectionViewData numberOfItemsInSection:section]+insertedCount-deletedCount+movedInCount-movedOutCount ==
                 [_collectionViewData numberOfItemsInSection:section],
                 @"invalide update in section %ld: number of items after update (%ld) should be equal to the number of items before update (%ld) "\
                 "plus count of inserted items (%ld), minus count of deleted items (%ld), plus count of items moved in (%ld), minus count of items moved out (%ld)",
                 section,
                  [_collectionViewData numberOfItemsInSection:section],
                 [oldCollectionViewData numberOfItemsInSection:section],
                 insertedCount,deletedCount,movedInCount, movedOutCount);
    }
#endif

    [someMutableArr2 addObjectsFromArray:sortedDeletedMutableItems];
    [someMutableArr3 addObjectsFromArray:sortedInsertMutableItems];
    [someMutableArr1 addObjectsFromArray:[someMutableArr2 sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)]];
    [someMutableArr1 addObjectsFromArray:sortedMutableMoveItems];
    [someMutableArr1 addObjectsFromArray:[someMutableArr3 sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
    
    NSMutableArray *layoutUpdateItems = [[NSMutableArray alloc] init];

    [layoutUpdateItems addObjectsFromArray:sortedDeletedMutableItems];
    [layoutUpdateItems addObjectsFromArray:sortedMutableMoveItems];
    [layoutUpdateItems addObjectsFromArray:sortedInsertMutableItems];
    
    
    NSMutableArray* newModel = [NSMutableArray array];
    for(NSInteger i=0;i<[oldCollectionViewData numberOfSections];i++) {
        NSMutableArray * sectionArr = [NSMutableArray array];
        for(NSInteger j=0;j< [oldCollectionViewData numberOfItemsInSection:i];j++)
            [sectionArr addObject: @([oldCollectionViewData globalIndexForItemAtIndexPath:[NSIndexPath btr_indexPathForItem:j inSection:i]])];
        [newModel addObject:sectionArr];
    }
    
    for(BTRCollectionViewUpdateItem *updateItem in layoutUpdateItems) {
        switch (updateItem.updateAction) {
            case BTRCollectionUpdateActionDelete: {
                if(updateItem.isSectionOperation) {
                    [newModel removeObjectAtIndex:updateItem.indexPathBeforeUpdate.section];
                } else {
                    [(NSMutableArray*)newModel[updateItem.indexPathBeforeUpdate.section]
                     removeObjectAtIndex:updateItem.indexPathBeforeUpdate.item];
                }
            }break;
            case BTRCollectionUpdateActionInsert: {
                if(updateItem.isSectionOperation) {
                    [newModel insertObject:[[NSMutableArray alloc] init]
                                   atIndex:updateItem.indexPathAfterUpdate.section];
                } else {
                    [(NSMutableArray *)newModel[updateItem.indexPathAfterUpdate.section]
                     insertObject:@(NSNotFound)
                     atIndex:updateItem.indexPathAfterUpdate.item];
                }
            }break;
                
            case BTRCollectionUpdateActionMove: {
                if(updateItem.isSectionOperation) {
                    id section = newModel[updateItem.indexPathBeforeUpdate.section];
                    [newModel insertObject:section atIndex:updateItem.indexPathAfterUpdate.section];
                }
                else {
                    id object = newModel[updateItem.indexPathBeforeUpdate.section][updateItem.indexPathBeforeUpdate.item];
                    [newModel[updateItem.indexPathBeforeUpdate.section] removeObjectAtIndex:updateItem.indexPathBeforeUpdate.item];
                    [newModel[updateItem.indexPathAfterUpdate.section] insertObject:object
                                                                            atIndex:updateItem.indexPathAfterUpdate.item];
                }
            }break;
            default: break;
        }
    }
    
    NSMutableArray *oldToNewMap = [NSMutableArray arrayWithCapacity:[oldCollectionViewData numberOfItems]];
    NSMutableArray *newToOldMap = [NSMutableArray arrayWithCapacity:[_collectionViewData numberOfItems]];

    for(NSInteger i=0; i < [oldCollectionViewData numberOfItems]; i++)
        [oldToNewMap addObject:@(NSNotFound)];

    for(NSInteger i=0; i < [_collectionViewData numberOfItems]; i++)
        [newToOldMap addObject:@(NSNotFound)];
    
    for(NSInteger i=0; i < [newModel count]; i++) {
        NSMutableArray* section = newModel[i];
        for(NSInteger j=0; j<[section count];j++) {
            NSInteger newGlobalIndex = [_collectionViewData globalIndexForItemAtIndexPath:[NSIndexPath btr_indexPathForItem:j inSection:i]];
            if([section[j] intValue] != NSNotFound)
                oldToNewMap[[section[j] intValue]] = @(newGlobalIndex);
            if(newGlobalIndex != NSNotFound)
                newToOldMap[newGlobalIndex] = section[j];
        }
    }

    _update = @{@"oldModel":oldCollectionViewData, @"newModel":_collectionViewData, @"oldToNewIndexMap":oldToNewMap, @"newToOldIndexMap":newToOldMap};

    [self updateWithItems:someMutableArr1];
    
    _originalInsertItems = nil;
    _originalDeleteItems = nil;
    _insertItems = nil;
    _deleteItems = nil;
    _moveItems = nil;
    _reloadItems = nil;
    _update = nil;
    _updateCount--;
    _collectionViewFlags.updating = NO;
    [self resumeReloads];
}


- (void)updateRowsAtIndexPaths:(NSArray *)indexPaths updateAction:(BTRCollectionUpdateAction)updateAction {
    BOOL updating = _collectionViewFlags.updating;
    if(!updating) {
        [self setupCellAnimations];
    }
    
    NSMutableArray *array = [self arrayForUpdateAction:updateAction]; //returns appropriate empty array if not exists
    
    for(NSIndexPath *indexPath in indexPaths) {
        BTRCollectionViewUpdateItem *updateItem = [[BTRCollectionViewUpdateItem alloc] initWithAction:updateAction
                                                                                         forIndexPath:indexPath];
        [array addObject:updateItem];
    }
    
    if(!updating) [self endItemAnimations];
}


- (void)updateSections:(NSIndexSet *)sections updateAction:(BTRCollectionUpdateAction)updateAction {
    BOOL updating = _collectionViewFlags.updating;
    if(updating) {
        [self setupCellAnimations];
    }
    
    NSMutableArray *updateActions = [self arrayForUpdateAction:updateAction];
    NSInteger section = [sections firstIndex];
    
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        BTRCollectionViewUpdateItem *updateItem =
        [[BTRCollectionViewUpdateItem alloc] initWithAction:updateAction
                                               forIndexPath:[NSIndexPath btr_indexPathForItem:NSNotFound
                                                                                inSection:section]];
        [updateActions addObject:updateItem];
    }];
    
    if (!updating) {
        [self endItemAnimations];
    }
}
@end

@interface BTRCollectionViewData () {
    CGRect _validLayoutRect;
    
    NSInteger _numItems;
    NSInteger _numSections;
    NSInteger *_sectionItemCounts;
    NSArray *_globalItems; // Apple uses id *_globalItems; - a C array?
	
	/*
	 // At this point, I've no idea how _screenPageDict is structured. Looks like some optimization for layoutAttributesForElementsInRect.
	 And why UICGPointKey? Isn't that doable with NSValue?
	 
	 "<UICGPointKey: 0x11432d40>" = "<NSMutableIndexSet: 0x11432c60>[number of indexes: 9 (in 1 ranges), indexes: (0-8)]";
	 "<UICGPointKey: 0xb94bf60>" = "<NSMutableIndexSet: 0x18dea7e0>[number of indexes: 11 (in 2 ranges), indexes: (6-15 17)]";
	 
	 (lldb) p (CGPoint)[[[[[collectionView valueForKey:@"_collectionViewData"] valueForKey:@"_screenPageDict"] allKeys] objectAtIndex:0] point]
	 (CGPoint) $11 = (x=15, y=159)
	 (lldb) p (CGPoint)[[[[[collectionView valueForKey:@"_collectionViewData"] valueForKey:@"_screenPageDict"] allKeys] objectAtIndex:1] point]
	 (CGPoint) $12 = (x=15, y=1128)
	 
	 // https://github.com/steipete/iOS6-Runtime-Headers/blob/master/UICGPointKey.h
	 
	 NSMutableDictionary *_screenPageDict;
	 */
	
    // @steipete
    NSArray *_cellLayoutAttributes;
	
    CGSize _contentSize;
    struct {
        unsigned int contentSizeIsValid:1;
        unsigned int itemCountsAreValid:1;
        unsigned int layoutIsPrepared:1;
    } _collectionViewDataFlags;
}
@property (nonatomic, unsafe_unretained) BTRCollectionView *collectionView;
@property (nonatomic, unsafe_unretained) BTRCollectionViewLayout *layout;
@end

@implementation BTRCollectionViewData

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)initWithCollectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)layout {
    if((self = [super init])) {
        _globalItems = [NSArray new];
        _collectionView = collectionView;
        _layout = layout;
    }
    return self;
}

- (void)dealloc {
    if(_sectionItemCounts) free(_sectionItemCounts);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p numItems:%ld numSections:%ld globalItems:%@>", NSStringFromClass([self class]), self, self.numberOfItems, self.numberOfSections, _globalItems];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)invalidate {
    _collectionViewDataFlags.itemCountsAreValid = NO;
    _collectionViewDataFlags.layoutIsPrepared = NO;
    _validLayoutRect = CGRectNull;  // don't set CGRectZero in case of _contentSize=CGSizeZero
}

- (CGRect)collectionViewContentRect {
    return (CGRect){.size=_contentSize};
}

- (void)validateLayoutInRect:(CGRect)rect {
    [self validateItemCounts];
    [self prepareToLoadData];
    
    // rect.size should be within _contentSize
    rect.size.width = fminf(rect.size.width, _contentSize.width);
    rect.size.height = fminf(rect.size.height, _contentSize.height);
    
    // TODO: check if we need to fetch data from layout
    if (!CGRectEqualToRect(_validLayoutRect, rect)) {
        _validLayoutRect = rect;
        _cellLayoutAttributes = [self.layout layoutAttributesForElementsInRect:rect];
    }
}

- (NSInteger)numberOfItems {
    [self validateItemCounts];
    return _numItems;
}

- (NSInteger)numberOfItemsBeforeSection:(NSInteger)section {
    return [self numberOfItemsInSection:section-1]; // ???
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    [self validateItemCounts];
    if (section > _numSections || section < 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Section %ld out of range: 0...%ld", section, _numSections] userInfo:nil];
    }
    
    NSInteger numberOfItemsInSection = 0;
    if (_sectionItemCounts) {
        numberOfItemsInSection = _sectionItemCounts[section];
    }
    return numberOfItemsInSection;
}

- (NSInteger)numberOfSections {
    [self validateItemCounts];
    return _numSections;
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectZero;
}

- (NSIndexPath *)indexPathForItemAtGlobalIndex:(NSInteger)index {
    return _globalItems[index];
}

- (NSInteger)globalIndexForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [_globalItems indexOfObject:indexPath];
}

- (BOOL)layoutIsPrepared {
    return _collectionViewDataFlags.layoutIsPrepared;
}

- (void)setLayoutIsPrepared:(BOOL)layoutIsPrepared {
    _collectionViewDataFlags.layoutIsPrepared = layoutIsPrepared;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Fetch Layout Attributes

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    [self validateLayoutInRect:rect];
    return _cellLayoutAttributes;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

// ensure item count is valid and loaded
- (void)validateItemCounts {
    if (!_collectionViewDataFlags.itemCountsAreValid) {
        [self updateItemCounts];
    }
}

// query dataSource for new data
- (void)updateItemCounts {
    // query how many sections there will be
    _numSections = 1;
    if ([self.collectionView.dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        _numSections = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
    }
    if (_numSections <= 0) { // early bail-out
        _numItems = 0;
        free(_sectionItemCounts); _sectionItemCounts = 0;
        return;
    }
    // allocate space
    if (!_sectionItemCounts) {
        _sectionItemCounts = malloc(_numSections * sizeof(NSInteger));
    }else {
        _sectionItemCounts = realloc(_sectionItemCounts, _numSections * sizeof(NSInteger));
    }
	
    // query cells per section
    _numItems = 0;
    for (NSInteger i=0; i<_numSections; i++) {
        NSInteger cellCount = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:i];
        _sectionItemCounts[i] = cellCount;
        _numItems += cellCount;
    }
    NSMutableArray* globalIndexPaths = [[NSMutableArray alloc] initWithCapacity:_numItems];
    for(NSInteger section = 0;section<_numSections;section++)
        for(NSInteger item=0;item<_sectionItemCounts[section];item++)
            [globalIndexPaths addObject:[NSIndexPath btr_indexPathForItem:item inSection:section]];
    _globalItems = [NSArray arrayWithArray:globalIndexPaths];
    _collectionViewDataFlags.itemCountsAreValid = YES;
}

- (void)prepareToLoadData {
    if (!self.layoutIsPrepared) {
        [self.layout prepareLayout];
        _contentSize = self.layout.collectionViewContentSize;
        self.layoutIsPrepared = YES;
    }
}

@end

NSString *BTRCollectionViewItemTypeToString(BTRCollectionViewItemType type) {
    switch (type) {
        case BTRCollectionViewItemTypeCell: return @"Cell";
        case BTRCollectionViewItemTypeDecorationView: return @"Decoration";
        case BTRCollectionViewItemTypeSupplementaryView: return @"Supplementary";
        default: return @"<INVALID>";
    }
}

@implementation BTRCollectionViewItemKey

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Static

+ (id)collectionItemKeyForCellWithIndexPath:(NSIndexPath *)indexPath {
    BTRCollectionViewItemKey *key = [[self class] new];
    key.indexPath = indexPath;
    key.type = BTRCollectionViewItemTypeCell;
    key.identifier = BTRCollectionElementKindCell;
    return key;
}

+ (id)collectionItemKeyForLayoutAttributes:(BTRCollectionViewLayoutAttributes *)layoutAttributes {
    BTRCollectionViewItemKey *key = [[self class] new];
    key.indexPath = layoutAttributes.indexPath;
    key.type = layoutAttributes.representedElementCategory;
    key.identifier = layoutAttributes.representedElementKind;
    return key;
}

// elementKind or reuseIdentifier?
+ (id)collectionItemKeyForDecorationViewOfKind:(NSString *)elementKind andIndexPath:(NSIndexPath *)indexPath {
    BTRCollectionViewItemKey *key = [[self class] new];
    key.indexPath = indexPath;
    key.identifier = elementKind;
    key.type = BTRCollectionViewItemTypeDecorationView;
    return key;
}

+ (id)collectionItemKeyForSupplementaryViewOfKind:(NSString *)elementKind andIndexPath:(NSIndexPath *)indexPath {
    BTRCollectionViewItemKey *key = [[self class] new];
    key.indexPath = indexPath;
    key.identifier = elementKind;
    key.type = BTRCollectionViewItemTypeSupplementaryView;
    return key;
}


///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p Type = %@ Identifier=%@ IndexPath = %@>", NSStringFromClass([self class]),
            self, BTRCollectionViewItemTypeToString(self.type), _identifier, self.indexPath];
}

- (NSUInteger)hash {
    return (([_indexPath hash] + _type) * 31) + [_identifier hash];
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[self class]]) {
        BTRCollectionViewItemKey *otherKeyItem = (BTRCollectionViewItemKey *)other;
        // identifier might be nil?
        if (_type == otherKeyItem.type && [_indexPath isEqual:otherKeyItem.indexPath] && ([_identifier isEqualToString:otherKeyItem.identifier] || _identifier == otherKeyItem.identifier)) {
            return YES;
		}
	}
    return NO;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    BTRCollectionViewItemKey *itemKey = [[self class] new];
    itemKey.indexPath = self.indexPath;
    itemKey.type = self.type;
    itemKey.identifier = self.identifier;
    return itemKey;
}

@end


@interface BTRCollectionViewUpdateItem() {
    NSIndexPath *_initialIndexPath;
    NSIndexPath *_finalIndexPath;
    BTRCollectionUpdateAction _updateAction;
    id _gap;
}
@end

@implementation BTRCollectionViewUpdateItem

@synthesize updateAction = _updateAction;
@synthesize indexPathBeforeUpdate = _initialIndexPath;
@synthesize indexPathAfterUpdate = _finalIndexPath;

- (id)initWithInitialIndexPath:(NSIndexPath *)initialIndexPath finalIndexPath:(NSIndexPath *)finalIndexPath updateAction:(BTRCollectionUpdateAction)updateAction {
    if((self = [super init])) {
        _initialIndexPath = initialIndexPath;
        _finalIndexPath = finalIndexPath;
        _updateAction = updateAction;
    }
    return self;
}

- (id)initWithAction:(BTRCollectionUpdateAction)updateAction forIndexPath:(NSIndexPath*)indexPath {
    if(updateAction == BTRCollectionUpdateActionInsert)
        return [self initWithInitialIndexPath:nil finalIndexPath:indexPath updateAction:updateAction];
    else if(updateAction == BTRCollectionUpdateActionDelete)
        return [self initWithInitialIndexPath:indexPath finalIndexPath:nil updateAction:updateAction];
    else if(updateAction == BTRCollectionUpdateActionReload)
        return [self initWithInitialIndexPath:indexPath finalIndexPath:indexPath updateAction:updateAction];
	
    return nil;
}

- (id)initWithOldIndexPath:(NSIndexPath *)oldIndexPath newIndexPath:(NSIndexPath *)newIndexPath {
    return [self initWithInitialIndexPath:oldIndexPath finalIndexPath:newIndexPath updateAction:BTRCollectionUpdateActionMove];
}

- (NSString *)description {
    NSString *action = nil;
    switch (_updateAction) {
        case BTRCollectionUpdateActionInsert: action = @"insert"; break;
        case BTRCollectionUpdateActionDelete: action = @"delete"; break;
        case BTRCollectionUpdateActionMove:   action = @"move";   break;
        case BTRCollectionUpdateActionReload: action = @"reload"; break;
        default: break;
    }
	
    return [NSString stringWithFormat:@"Index path before update (%@) index path after update (%@) action (%@).",  _initialIndexPath, _finalIndexPath, action];
}

- (void)setNewIndexPath:(NSIndexPath *)indexPath {
    _finalIndexPath = indexPath;
}

- (void)setGap:(id)gap {
    _gap = gap;
}

- (BOOL)isSectionOperation {
    return (_initialIndexPath.item == NSNotFound || _finalIndexPath.item == NSNotFound);
}

- (NSIndexPath *)newIndexPath {
    return _finalIndexPath;
}

- (id)gap {
    return _gap;
}

- (BTRCollectionUpdateAction)action {
    return _updateAction;
}

- (id)indexPath {
    //TODO: check this
    return _initialIndexPath;
}

- (NSComparisonResult)compareIndexPaths:(BTRCollectionViewUpdateItem *)otherItem {
    NSComparisonResult result = NSOrderedSame;
    NSIndexPath *selfIndexPath = nil;
    NSIndexPath *otherIndexPath = nil;
    
    switch (_updateAction) {
        case BTRCollectionUpdateActionInsert:
            selfIndexPath = _finalIndexPath;
            otherIndexPath = [otherItem newIndexPath];
            break;
        case BTRCollectionUpdateActionDelete:
            selfIndexPath = _initialIndexPath;
            otherIndexPath = [otherItem indexPath];
        default: break;
    }
	
    if (self.isSectionOperation) result = [@(selfIndexPath.section) compare:@(otherIndexPath.section)];
    else result = [selfIndexPath compare:otherIndexPath];
    return result;
}

- (NSComparisonResult)inverseCompareIndexPaths:(BTRCollectionViewUpdateItem *)otherItem {
    return (NSComparisonResult) ([self compareIndexPaths:otherItem]*-1);
}

@end
