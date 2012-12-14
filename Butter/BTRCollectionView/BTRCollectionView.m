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

#import "NSView+BTRAdditions.h"

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
    NSMutableArray *_indexPathsForSelectedItems;
	// Set of items that are highlighted (highlighted state comes before selected)
    NSMutableArray *_indexPathsForHighlightedItems;
	// Set of items that were newly highlighted by a mouse event
	NSMutableSet *_indexPathsForNewlyHighlightedItems;
	// Set of items that were newly unhighlighted by a mouse event
	NSMutableSet *_indexPathsForNewlyUnhighlightedItems;
	// Reuse queues for collection view cells
    NSMutableDictionary *_cellReuseQueues;
	// Reuse queues for collection view supplementary views
    NSMutableDictionary *_supplementaryViewReuseQueues;
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
@end

@implementation BTRCollectionView

@synthesize collectionViewLayout = _layout;
@synthesize visibleViewsDict = _allVisibleViewsDict;

#pragma mark - NSObject

- (void)BTRCollectionViewCommonSetup
{
	// Allocate storage variables, configure default settings
    self.allowsSelection = YES;
	self.flipped = YES;
	self.backgroundColor = [NSColor blueColor];
	
    _indexPathsForSelectedItems = [NSMutableArray new];
    _indexPathsForHighlightedItems = [NSMutableArray new];
    _cellReuseQueues = [NSMutableDictionary new];
    _supplementaryViewReuseQueues = [NSMutableDictionary new];
    _allVisibleViewsDict = [NSMutableDictionary new];
    _cellClassDict = [NSMutableDictionary new];
    _cellNibDict = [NSMutableDictionary new];
    _supplementaryViewClassDict = [NSMutableDictionary new];
	_supplementaryViewNibDict = [NSMutableDictionary new];
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
    if (!_collectionViewFlags.updatingLayout) [self updateVisibleCells];
	// Check if the content size needs to be reset
    CGSize contentSize = [_collectionViewData collectionViewContentRect].size;
    if (!CGSizeEqualToSize([self frame].size, contentSize)) {
		// Set the new content size and run layout again
        [self setFrameSize:contentSize];
        [_collectionViewData validateLayoutInRect:self.visibleRect];
        [self updateVisibleCells];
    }
	// Set the frame of the background view to the visible section of the view
	// This means that the background view moves as a backdrop as the view is scrolled
    if (_backgroundView) {
        _backgroundView.frame = self.visibleRect;
    }
	// We have now done a full layout pass, so update the flag
	if (!_collectionViewFlags.doneFirstLayout) _collectionViewFlags.doneFirstLayout = YES;
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

- (NSArray *)indexPathsForSelectedItems {
    return [_indexPathsForSelectedItems copy];
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
		targetRect = [self adjustRect:targetRect forScrollPosition:scrollPosition];
        [self btr_scrollRectToVisible:targetRect animated:animated];
    }
}

- (CGRect)adjustRect:(CGRect)targetRect forScrollPosition:(BTRCollectionViewScrollPosition)scrollPosition
{
	NSUInteger verticalPosition = scrollPosition & 0x07;   // 0000 0111
    NSUInteger horizontalPosition = scrollPosition & 0x38; // 0011 1000
    
    if (verticalPosition != BTRCollectionViewScrollPositionNone
        && verticalPosition != BTRCollectionViewScrollPositionTop
        && verticalPosition != BTRCollectionViewScrollPositionCenteredVertically
        && verticalPosition != BTRCollectionViewScrollPositionBottom) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"BTRCollectionViewScrollPosition: attempt to use a scroll position with multiple vertical positioning styles" userInfo:nil];
    }
    
    if (horizontalPosition != BTRCollectionViewScrollPositionNone
		&& horizontalPosition != BTRCollectionViewScrollPositionLeft
		&& horizontalPosition != BTRCollectionViewScrollPositionCenteredHorizontally
		&& horizontalPosition != BTRCollectionViewScrollPositionRight) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"BTRCollectionViewScrollPosition: attempt to use a scroll position with multiple horizontal positioning styles" userInfo:nil];
    }
    CGRect frame = self.visibleRect;
    CGFloat calculateX;
    CGFloat calculateY;
	CGRect adjustedRect = targetRect;
    switch (verticalPosition) {
        case BTRCollectionViewScrollPositionCenteredVertically:
            calculateY = adjustedRect.origin.y - ((frame.size.height / 2) - (adjustedRect.size.height / 2));
            adjustedRect = CGRectMake(adjustedRect.origin.x, calculateY, adjustedRect.size.width, frame.size.height);
            break;
			
		case BTRCollectionViewScrollPositionTop:
            adjustedRect = CGRectMake(adjustedRect.origin.x, adjustedRect.origin.y, adjustedRect.size.width, frame.size.height);
            break;
            
        case BTRCollectionViewScrollPositionBottom:
            calculateY = targetRect.origin.y - (frame.size.height - targetRect.size.height);
            adjustedRect = CGRectMake(adjustedRect.origin.x, calculateY, adjustedRect.size.width, frame.size.height);
            break;
	}
	switch (horizontalPosition) {
		case BTRCollectionViewScrollPositionCenteredHorizontally:
            calculateX = adjustedRect.origin.x - ((frame.size.width / 2) - (adjustedRect.size.width / 2));
            adjustedRect = CGRectMake(calculateX, adjustedRect.origin.y, frame.size.width, adjustedRect.size.height);
            break;
			
        case BTRCollectionViewScrollPositionLeft:
            adjustedRect = CGRectMake(adjustedRect.origin.x, adjustedRect.origin.y, frame.size.width, adjustedRect.size.height);
            break;
            
        case BTRCollectionViewScrollPositionRight:
            calculateX = adjustedRect.origin.x - (frame.size.width - adjustedRect.size.width);
            adjustedRect = CGRectMake(calculateX, adjustedRect.origin.y, frame.size.width, adjustedRect.size.height);
            break;
    }
    return targetRect;
}

#pragma mark - Mouse Event Handling

- (void)mouseDown:(NSEvent *)theEvent
{
	[super mouseDown:theEvent];
	if (!self.allowsSelection) return;
	//
	// A note about this whole "highlighted" state thing that seems somewhat confusing
	// The highlighted state occurs on mouseDown:. It is the intermediary step to either
	// selecting or deselecting an item. Items that are unhighlighted in this method are
	// queued to be deselected in mouseUp:, and items that are selected are queued to be
	// selected in mouseUp:
	//
	NSUInteger modifierFlags = [[NSApp currentEvent] modifierFlags];
    BOOL commandKeyDown = ((modifierFlags & NSCommandKeyMask) == NSCommandKeyMask);
    BOOL shiftKeyDown = ((modifierFlags & NSShiftKeyMask) == NSShiftKeyMask);
	
	CGPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSIndexPath *indexPath = [self indexPathForItemAtPoint:location];
	BOOL alreadySelected = [_indexPathsForSelectedItems containsObject:indexPath];
	
	// Unhighlights everything that's currently selected
	void (^unhighlightAllBlock)(void) = ^{
		_indexPathsForNewlyUnhighlightedItems = [NSMutableSet setWithArray:_indexPathsForSelectedItems];
		[self unhighlightAllItems];
	};
	// Convenience block for building the highlighted items array and highlighting an item
	void (^highlightBlock)(NSIndexPath *) = ^(NSIndexPath *path){
		if ([self highlightItemAtIndexPath:path
								  animated:self.animatesSelection
							scrollPosition:BTRCollectionViewScrollPositionNone
							notifyDelegate:YES]) {
			if (!_indexPathsForNewlyHighlightedItems) {
				_indexPathsForNewlyHighlightedItems = [NSMutableSet setWithObject:path];
			} else {
				[_indexPathsForNewlyHighlightedItems addObject:path];
			}
		}
	};
	// If the background was clicked, unhighlight everything
	if (!indexPath) {
		unhighlightAllBlock();
		return;
	}
	// If command is not being pressed, unhighlight everything
	// before highlighting the new item
	if (!commandKeyDown)
		unhighlightAllBlock();
	// If a modifier key is being held down and the item is already selected,
	// we want to inverse the selection and deselect it
	if (commandKeyDown && alreadySelected) {
		_indexPathsForNewlyUnhighlightedItems = [NSMutableSet setWithObject:indexPath];
		[self unhighlightItemAtIndexPath:indexPath animated:self.animatesSelection notifyDelegate:YES];
	} else {
		// If nothing has been highlighted yet and shift is not being pressed,
		// just highlight the single item
		if (!shiftKeyDown) {
			highlightBlock(indexPath);
		} else if (shiftKeyDown && [_indexPathsForSelectedItems count]) {
			// When shift is being held, we want multiple selection behaviour
			// Take two index paths, the first index path that was selected and the newly selected index path
			NSIndexPath *one = [_indexPathsForSelectedItems objectAtIndex:0];
			NSIndexPath *two = indexPath;
			NSIndexPath *startingIndexPath = nil;
			NSIndexPath *endingIndexPath = nil;
			// Compare to see which index comes first, and decide what the starting and ending index paths are
			// (the starting path should always be the lower one)
			if ([one compare:two] == NSOrderedAscending) {
				startingIndexPath = one;
				endingIndexPath = two;
			} else {
				startingIndexPath = two;
				endingIndexPath = one;
			}
			NSMutableArray *selectionRange = [NSMutableArray array];
			// Iterate through each section until reaching the section of the ending index path
			for (NSUInteger i = startingIndexPath.section; i <= endingIndexPath.section; i++) {
				NSUInteger numberOfItems = [self numberOfItemsInSection:i];
				NSUInteger currentItem = 0;
				// If we're currently iterating the last section, make sure the iteration
				// stops at the index of the ending index path
				if (i == endingIndexPath.section)
					numberOfItems = endingIndexPath.row + 1;
				// If we're iterating the first section, make sure the iteration starts
				// at the index of the starting index path
				if (i == startingIndexPath.section)
					currentItem = startingIndexPath.row;
				for (NSUInteger j = currentItem; j < numberOfItems; j++) {
					NSIndexPath *indexPath = [NSIndexPath btr_indexPathForItem:j inSection:i];
					[selectionRange addObject:indexPath];
				}
			}
			// Highlight the entire range
			for (NSIndexPath *indexPath in selectionRange) {
				highlightBlock(indexPath);
			}
		}
	}
	
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[super mouseUp:theEvent];
	if (!self.allowsSelection) return;
	// "Commit" all the changes by selecting/deselecting the highlight/unhighlighted cells
	for (NSIndexPath *indexPath in _indexPathsForNewlyUnhighlightedItems) {
		[self deselectItemAtIndexPath:indexPath animated:self.animatesSelection notifyDelegate:YES];
	}
	for (NSIndexPath *indexPath in _indexPathsForNewlyHighlightedItems) {
		[self selectItemAtIndexPath:indexPath
						   animated:self.animatesSelection
					 scrollPosition:BTRCollectionViewScrollPositionNone
					 notifyDelegate:YES];
	}
	_indexPathsForNewlyHighlightedItems = nil;
	_indexPathsForNewlyUnhighlightedItems = nil;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
	if (!self.allowsSelection) return;
    // TODO: Implement a dragging rectangle
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
					 animated:(BOOL)animated
			   scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition
			   notifyDelegate:(BOOL)notifyDelegate
{
	// Deselect everything else if only single selection is supported
    if (!self.allowsMultipleSelection) {
		for (NSIndexPath *selectedIndexPath in [_indexPathsForSelectedItems copy]) {
			if (![indexPath isEqual:selectedIndexPath]) {
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
		if (animated) {
			[NSView btr_animate:^{
				selectedCell.selected = YES;
			}];
		} else {
			selectedCell.selected = YES;
		}
		[_indexPathsForSelectedItems addObject:indexPath];
		if (notifyDelegate && _collectionViewFlags.delegateDidSelectItemAtIndexPath) {
			[self.delegate collectionView:self didSelectItemAtIndexPath:indexPath];
		}
	}
    [self unhighlightItemAtIndexPath:indexPath animated:animated notifyDelegate:YES];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
					 animated:(BOOL)animated
			   scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition
{
    [self selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition notifyDelegate:NO];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
	[self deselectItemAtIndexPath:indexPath animated:animated notifyDelegate:NO];
}

- (BOOL)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated notifyDelegate:(BOOL)notify
{
    if ([_indexPathsForSelectedItems containsObject:indexPath]) {
		BOOL shouldDeselect = YES;
        if (notify && _collectionViewFlags.delegateShouldDeselectItemAtIndexPath) {
            shouldDeselect = [self.delegate collectionView:self shouldDeselectItemAtIndexPath:indexPath];
        }
        if (shouldDeselect) {
            BTRCollectionViewCell *selectedCell = [self cellForItemAtIndexPath:indexPath];
			if (animated) {
				[NSView btr_animate:^{
					selectedCell.selected = NO;
				}];
			} else {
				selectedCell.selected = NO;
			}
			[_indexPathsForSelectedItems removeObject:indexPath];
			[self unhighlightItemAtIndexPath:indexPath animated:animated notifyDelegate:notify];
			if (notify && _collectionViewFlags.delegateDidDeselectItemAtIndexPath) {
				[self.delegate collectionView:self didDeselectItemAtIndexPath:indexPath];
			}
        }
		return shouldDeselect;
    }
	return NO;
}

- (BOOL)highlightItemAtIndexPath:(NSIndexPath *)indexPath
						animated:(BOOL)animated
				  scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition
				  notifyDelegate:(BOOL)notifyDelegate
{
    BOOL shouldHighlight = YES;
    if (notifyDelegate && _collectionViewFlags.delegateShouldHighlightItemAtIndexPath) {
        shouldHighlight = [self.delegate collectionView:self shouldHighlightItemAtIndexPath:indexPath];
    }
    if (shouldHighlight) {
        BTRCollectionViewCell *highlightedCell = [self cellForItemAtIndexPath:indexPath];
        if (animated) {
			[NSView btr_animate:^{
				highlightedCell.highlighted = YES;
			}];
		} else {
			highlightedCell.highlighted = YES;
		}
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
        if (animated) {
			[NSView btr_animate:^{
				highlightedCell.highlighted = NO;
			}];
		} else {
			highlightedCell.highlighted = NO;
		}
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
		[self deselectItemAtIndexPath:indexPath animated:NO notifyDelegate:YES];
	}
}

#pragma mark - Update Grid

- (void)insertSections:(NSIndexSet *)sections
{
    [self updateSections:sections updateAction:BTRCollectionUpdateActionInsert];
}

- (void)deleteSections:(NSIndexSet *)sections
{
    [self updateSections:sections updateAction:BTRCollectionUpdateActionInsert];
}

- (void)reloadSections:(NSIndexSet *)sections
{
    [self updateSections:sections updateAction:BTRCollectionUpdateActionReload];
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    NSMutableArray *moveUpdateItems = [self arrayForUpdateAction:BTRCollectionUpdateActionMove];
	NSIndexPath *from = [NSIndexPath btr_indexPathForItem:NSNotFound inSection:section];
	NSIndexPath *to = [NSIndexPath btr_indexPathForItem:NSNotFound inSection:newSection];
	BTRCollectionViewUpdateItem *update = [[BTRCollectionViewUpdateItem alloc] initWithInitialIndexPath:from finalIndexPath:to updateAction:BTRCollectionUpdateActionMove];
    [moveUpdateItems addObject:update];
    if(!_collectionViewFlags.updating) {
        [self setupCellAnimations];
        [self endItemAnimations];
    }
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self updateRowsAtIndexPaths:indexPaths updateAction:BTRCollectionUpdateActionInsert];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self updateRowsAtIndexPaths:indexPaths updateAction:BTRCollectionUpdateActionDelete];
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self updateRowsAtIndexPaths:indexPaths updateAction:BTRCollectionUpdateActionReload];
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    NSMutableArray *moveUpdateItems = [self arrayForUpdateAction:BTRCollectionUpdateActionMove];
	BTRCollectionViewUpdateItem *update = [[BTRCollectionViewUpdateItem alloc] initWithInitialIndexPath:indexPath finalIndexPath:newIndexPath updateAction:BTRCollectionUpdateActionMove];
    [moveUpdateItems addObject:update];
    if (!_collectionViewFlags.updating) {
        [self setupCellAnimations];
        [self endItemAnimations];
    }	
}

- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(void))completion
{
    if (!updates) return;
    [self setupCellAnimations];
    updates();
    if(completion) _updateCompletionHandler = completion;
    [self endItemAnimations];
}

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

- (void)setCollectionViewLayout:(BTRCollectionViewLayout *)layout animated:(BOOL)animated
{
    if (layout == _layout) return;
	// If there's no current layout state then 
    if (CGRectIsEmpty(self.bounds) || !_collectionViewFlags.doneFirstLayout) {
        _layout.collectionView = nil;
        _collectionViewData = [[BTRCollectionViewData alloc] initWithCollectionView:self layout:layout];
        layout.collectionView = self;
        _layout = layout;
		//TODO: Call -will/didTransitionFromLayout:toLayout: with a nil fromLayout.
        [self setNeedsDisplay:YES];
    } else {
        layout.collectionView = self;
        
        _collectionViewData = [[BTRCollectionViewData alloc] initWithCollectionView:self layout:layout];
        [_collectionViewData prepareToLoadData];
		
        NSArray *previouslySelectedIndexPaths = [self indexPathsForSelectedItems];
        NSMutableSet *selectedCellKeys = [NSMutableSet setWithCapacity:[previouslySelectedIndexPaths count]];
        
        for (NSIndexPath *indexPath in previouslySelectedIndexPaths) {
            [selectedCellKeys addObject:[BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath]];
        }
        
        NSArray *previouslyVisibleItemsKeys = [_allVisibleViewsDict allKeys];
        NSSet *previouslyVisibleItemsKeysSet = [NSSet setWithArray:previouslyVisibleItemsKeys];
        NSMutableSet *previouslyVisibleItemsKeysSetMutable = [NSMutableSet setWithArray:previouslyVisibleItemsKeys];
		
        if ([selectedCellKeys intersectsSet:selectedCellKeys]) {
            [previouslyVisibleItemsKeysSetMutable intersectSet:previouslyVisibleItemsKeysSetMutable];
        }

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
		
        [self setFrameSize:contentRect.size];
        [self scrollPoint:contentRect.origin];
        
        void (^applyNewLayoutBlock)(void) = ^{
            NSEnumerator *keys = [layoutInterchangeData keyEnumerator];
            for(BTRCollectionViewItemKey *key in keys) {
				BTRCollectionViewCell *cell = (BTRCollectionViewCell *)_allVisibleViewsDict[key];
				[cell willTransitionFromLayout:_layout toLayout:layout];
                [cell applyLayoutAttributes:layoutInterchangeData[key][@"newLayoutInfos"]];
				[cell didTransitionFromLayout:_layout toLayout:layout];
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
            [NSView btr_animateWithDuration:.3 animations:^{
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
	if (_delegate != delegate) {
		_delegate = delegate;
		_collectionViewFlags.delegateShouldSelectItemAtIndexPath = [_delegate respondsToSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)];
		_collectionViewFlags.delegateDidSelectItemAtIndexPath = [_delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)];
		_collectionViewFlags.delegateShouldDeselectItemAtIndexPath = [_delegate respondsToSelector:@selector(collectionView:shouldDeselectItemAtIndexPath:)];
		_collectionViewFlags.delegateDidDeselectItemAtIndexPath = [_delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)];
		_collectionViewFlags.delegateShouldHighlightItemAtIndexPath = [_delegate respondsToSelector:@selector(collectionView:shouldHighlightItemAtIndexPath:)];
		_collectionViewFlags.delegateDidHighlightItemAtIndexPath = [_delegate respondsToSelector:@selector(collectionView:didHighlightItemAtIndexPath:)];
		_collectionViewFlags.delegateDidUnhighlightItemAtIndexPath = [_delegate respondsToSelector:@selector(collectionView:didUnhighlightItemAtIndexPath:)];
		_collectionViewFlags.delegateDidEndDisplayingCell = [_delegate respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)];
		_collectionViewFlags.delegateDidEndDisplayingSupplementaryView = [_delegate respondsToSelector:@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)];
	}
}

- (void)setDataSource:(id<BTRCollectionViewDataSource>)dataSource {
    if (dataSource != _dataSource) {
		_dataSource = dataSource;
		_collectionViewFlags.dataSourceNumberOfSections = [_dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)];
		_collectionViewFlags.dataSourceViewForSupplementaryElement = [_dataSource respondsToSelector:@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)];
    }
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection {
	if (_allowsMultipleSelection != allowsMultipleSelection) {
		_allowsMultipleSelection = allowsMultipleSelection;
        for (NSIndexPath *selectedIndexPath in [_indexPathsForSelectedItems copy]) {
            if (_indexPathsForSelectedItems.count == 1) break;
            [self deselectItemAtIndexPath:selectedIndexPath animated:YES notifyDelegate:YES];
        }
    }
}

#pragma mark - Private

- (void)invalidateLayout {
    [self.collectionViewLayout invalidateLayout];
    [self.collectionViewData invalidate];
}

- (void)updateVisibleCells
{
	// Build an array of the items that need to be made visible
    NSArray *layoutAttributesArray = [_collectionViewData layoutAttributesForElementsInRect:self.visibleRect];
    NSMutableDictionary *itemKeysToAddDict = [NSMutableDictionary dictionary];
    for (BTRCollectionViewLayoutAttributes *layoutAttributes in layoutAttributesArray) {
        BTRCollectionViewItemKey *itemKey = [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:layoutAttributes];
        itemKeysToAddDict[itemKey] = layoutAttributes;
    }
	// Build a set of the currently visible items that need to be removed and reused
    NSMutableSet *allVisibleItemKeys = [NSMutableSet setWithArray:[_allVisibleViewsDict allKeys]];
    [allVisibleItemKeys minusSet:[NSSet setWithArray:[itemKeysToAddDict allKeys]]];
	
	// Remove views that are no longer visible and queue them for reuse
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
            } else if (itemKey.type == BTRCollectionViewItemTypeSupplementaryView) {
                if (_collectionViewFlags.delegateDidEndDisplayingSupplementaryView) {
                    [self.delegate collectionView:self didEndDisplayingSupplementaryView:reusableView forElementOfKind:itemKey.identifier atIndexPath:itemKey.indexPath];
                }
                [self reuseSupplementaryView:reusableView];
            }
            // TODO: Add support for decoration views
        }
    }
	
    // Add new cells
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
    [self updateVisibleCells];
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
            if([section[j] integerValue] != NSNotFound)
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
