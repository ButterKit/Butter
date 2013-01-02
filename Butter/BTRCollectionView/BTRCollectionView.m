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

#pragma mark Internal Constants

static NSString* const BTRCollectionViewDeletedItemsCount = @"BTRCollectionViewDeletedItemsCount";
static NSString* const BTRCollectionViewInsertedItemsCount = @"BTRCollectionViewInsertedItemsCount";
static NSString* const BTRCollectionViewMovedOutCount = @"BTRCollectionViewMovedOutCount";
static NSString* const BTRCollectionViewMovedInCount = @"BTRCollectionViewMovedInCount";
static NSString* const BTRCollectionViewPreviousLayoutInfoKey = @"BTRCollectionViewPreviousLayoutInfoKey";
static NSString* const BTRCollectionViewNewLayoutInfoKey = @"BTRCollectionViewNewLayoutInfoKey";
static NSString* const BTRCollectionViewViewKey = @"BTRCollectionViewViewKey";

@interface BTRCollectionViewLayout (Internal)
@property (nonatomic, unsafe_unretained) BTRCollectionView *collectionView;
@end

@interface BTRCollectionViewData (Internal)
- (void)prepareToLoadData;
@end

@interface BTRCollectionView ()
// Stores all the data associated with collection view layout
@property (nonatomic, strong) BTRCollectionViewData *collectionViewData;
// Mapped to the ivar _allVisibleViewsDict (dictionary of all visible views)
@property (nonatomic, readonly) NSDictionary *visibleViewsDict;
// Stores the information associated with an update of the collection view's items
@property (nonatomic, strong) NSDictionary *currentUpdate;
@end

@implementation BTRCollectionView {
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

@synthesize collectionViewLayout = _layout;
@synthesize visibleViewsDict = _allVisibleViewsDict;

#pragma mark - NSObject

- (void)BTRCollectionViewCommonSetup {
	// Allocate storage variables, configure default settings
	self.allowsSelection = YES;
	self.flipped = YES;

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

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
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
		if ([self.collectionViewLayout shouldInvalidateLayoutForBoundsChange:(CGRect){.size=frame.size}]) {
			[self invalidateLayout];
		}
	}
	[super setFrame:frame];
}

- (void)addCollectionViewSubview:(NSView *)subview
{
	if ([subview isKindOfClass:[BTRCollectionViewCell class]]) {
		[self addSubview:subview positioned:NSWindowBelow relativeTo:nil];
	} else {
		[self addSubview:subview];
	}
}

#pragma mark - NSResponder

// Need to override these to receive keyboard events

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)canBecomeKeyView {
	return YES;
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
	__block BOOL containsCell = NO;
	[topLevelObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if ([obj isKindOfClass:[BTRCollectionViewCell class]]) {
			containsCell = YES;
			*stop = YES;
		}
	}];
	NSAssert(containsCell, @"must contain a BTRCollectionViewCell object");
	
	_cellNibDict[identifier] = nib;
}

- (void)registerNib:(NSNib *)nib forSupplementaryViewOfKind:(NSString *)kind withReuseIdentifier:(NSString *)identifier {
	NSArray *topLevelObjects = nil;
	[nib instantiateWithOwner:nil topLevelObjects:&topLevelObjects];
	__block BOOL containsView = NO;
	[topLevelObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if ([obj isKindOfClass:[BTRCollectionReusableView class]]) {
			containsView = YES;
			*stop = YES;
		}
	}];
	NSAssert(containsView, @"must contain a BTRCollectionReusableView object");
	
	NSString *kindAndIdentifier = [NSString stringWithFormat:@"%@/%@", kind, identifier];
	_supplementaryViewNibDict[kindAndIdentifier] = nib;
}

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
	// Check to see if there is already a reusable cell in the reuse queue
	NSMutableArray *reusableCells = _cellReuseQueues[identifier];
	__block BTRCollectionViewCell *cell = [reusableCells lastObject];
	if (cell) {
		[reusableCells removeObjectAtIndex:[reusableCells count]-1];
	}else {
		// If a NIB was registered for the cell, instantiate the NIB and retrieve the view from there
		if (_cellNibDict[identifier]) {
			// Cell was registered via registerNib:forCellWithReuseIdentifier:
			NSNib *cellNib = _cellNibDict[identifier];
			NSArray *topLevelObjects = nil;
			[cellNib instantiateWithOwner:self topLevelObjects:&topLevelObjects];
			[topLevelObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if ([obj isKindOfClass:[BTRCollectionViewCell class]]) {
					cell = obj;
					*stop = YES;
				}
			}];
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
	__block BTRCollectionReusableView *view = [reusableViews lastObject];
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
			[topLevelObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if ([obj isKindOfClass:[BTRCollectionReusableView class]]) {
					view = obj;
					*stop = YES;
				}
			}];
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
	[_indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
		BTRCollectionViewCell *selectedCell = [self cellForItemAtIndexPath:indexPath];
		selectedCell.selected = NO;
		selectedCell.highlighted = NO;
	}];
	[_indexPathsForSelectedItems removeAllObjects];
	[_indexPathsForHighlightedItems removeAllObjects];
	// Layout
	[self setNeedsLayout:YES];
}


#pragma mark - Query Grid

// A bunch of methods that query the collection view's layout for information

- (NSUInteger)numberOfSections {
	return [_collectionViewData numberOfSections];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section {
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
	
	if (scrollPosition == BTRCollectionViewScrollPositionNone) return;
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

- (CGRect)adjustRect:(CGRect)targetRect forScrollPosition:(BTRCollectionViewScrollPosition)scrollPosition {
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
	return adjustedRect;
}

#pragma mark - Mouse Event Handling

- (void)mouseDown:(NSEvent *)theEvent {
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
			NSIndexPath *one = _indexPathsForSelectedItems[0];
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
			[selectionRange enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
				for (NSIndexPath *indexPath in selectionRange) {
					highlightBlock(indexPath);
				}
			}];
		}
	}
	
}

- (void)mouseUp:(NSEvent *)theEvent {
	[super mouseUp:theEvent];
	if (!self.allowsSelection) return;
	// "Commit" all the changes by selecting/deselecting the highlight/unhighlighted cells
	[_indexPathsForNewlyUnhighlightedItems enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
		[self deselectItemAtIndexPath:indexPath animated:self.animatesSelection notifyDelegate:YES];
	}];
	[_indexPathsForNewlyHighlightedItems enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
		[self selectItemAtIndexPath:indexPath
						   animated:self.animatesSelection
					 scrollPosition:BTRCollectionViewScrollPositionNone
					 notifyDelegate:YES];
	}];
	_indexPathsForNewlyHighlightedItems = nil;
	_indexPathsForNewlyUnhighlightedItems = nil;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[super mouseDragged:theEvent];
	if (!self.allowsSelection) return;
	// TODO: Implement a dragging rectangle
}

#pragma mark - Key Events

// Stubs for keyboard event implementation

- (void)keyDown:(NSEvent *)theEvent {
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)moveUp:(id)sender {
	
}

- (void)moveDown:(id)sender {
	
}

#pragma mark - Selection and Highlighting

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
					 animated:(BOOL)animated
			   scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition
			   notifyDelegate:(BOOL)notifyDelegate {
	// Deselect everything else if only single selection is supported
	if (!self.allowsMultipleSelection) {
		[[_indexPathsForSelectedItems copy] enumerateObjectsUsingBlock:^(NSIndexPath *selectedIndexPath, NSUInteger idx, BOOL *stop) {
			if (![indexPath isEqual:selectedIndexPath]) {
				[self deselectItemAtIndexPath:selectedIndexPath animated:animated notifyDelegate:notifyDelegate];
			}
		}];
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
		[self scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
	}
	[self unhighlightItemAtIndexPath:indexPath animated:animated notifyDelegate:YES];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
					 animated:(BOOL)animated
			   scrollPosition:(BTRCollectionViewScrollPosition)scrollPosition {
	[self selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition notifyDelegate:NO];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
	[self deselectItemAtIndexPath:indexPath animated:animated notifyDelegate:NO];
}

- (BOOL)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated notifyDelegate:(BOOL)notify {
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
				  notifyDelegate:(BOOL)notifyDelegate {
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
		[self scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
	}
	return shouldHighlight;
}

- (void)unhighlightItemAtIndexPath:(NSIndexPath *)indexPath
						  animated:(BOOL)animated
					notifyDelegate:(BOOL)notifyDelegate {
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

- (void)unhighlightAllItems {
	[[_indexPathsForHighlightedItems copy] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
		[self unhighlightItemAtIndexPath:indexPath animated:NO notifyDelegate:YES];
	}];
}

- (void)deselectAllItems {
	[[_indexPathsForSelectedItems copy] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
		[self deselectItemAtIndexPath:indexPath animated:NO notifyDelegate:YES];
	}];
}

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

- (void)moveSection:(NSUInteger)section toSection:(NSUInteger)newSection {
	NSMutableArray *moveUpdateItems = [self arrayForUpdateAction:BTRCollectionUpdateActionMove];
	NSIndexPath *from = [NSIndexPath btr_indexPathForItem:NSNotFound inSection:section];
	NSIndexPath *to = [NSIndexPath btr_indexPathForItem:NSNotFound inSection:newSection];
	BTRCollectionViewUpdateItem *update = [[BTRCollectionViewUpdateItem alloc] initWithInitialIndexPath:from finalIndexPath:to updateAction:BTRCollectionUpdateActionMove];
	[moveUpdateItems addObject:update];
	if (!_collectionViewFlags.updating) {
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
	NSMutableArray *moveUpdateItems = [self arrayForUpdateAction:BTRCollectionUpdateActionMove];
	BTRCollectionViewUpdateItem *update = [[BTRCollectionViewUpdateItem alloc] initWithInitialIndexPath:indexPath finalIndexPath:newIndexPath updateAction:BTRCollectionUpdateActionMove];
	[moveUpdateItems addObject:update];
	if (!_collectionViewFlags.updating) {
		[self setupCellAnimations];
		[self endItemAnimations];
	}
}

- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(void))completion {
	if (!updates) return;
	[self setupCellAnimations];
	updates();
	if (completion) _updateCompletionHandler = [completion copy];
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

- (void)setCollectionViewLayout:(BTRCollectionViewLayout *)layout animated:(BOOL)animated {
	if (layout == _layout) return;
	layout.collectionView = self;
	
	_collectionViewData = [[BTRCollectionViewData alloc] initWithCollectionView:self layout:layout];
	[_collectionViewData prepareToLoadData];
	NSArray *previouslySelectedIndexPaths = [self indexPathsForSelectedItems];
	NSMutableSet *selectedCellKeys = [NSMutableSet setWithCapacity:[previouslySelectedIndexPaths count]];
	[previouslySelectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
		[selectedCellKeys addObject:[BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath]];
	}];
	NSArray *previouslyVisibleItemsKeys = [_allVisibleViewsDict allKeys];
	NSSet *previouslyVisibleItemsKeysSet = [NSSet setWithArray:previouslyVisibleItemsKeys];
	NSMutableSet *previouslyVisibleItemsKeysSetMutable = [NSMutableSet setWithArray:previouslyVisibleItemsKeys];
	if ([selectedCellKeys intersectsSet:selectedCellKeys]) {
		[previouslyVisibleItemsKeysSetMutable intersectSet:previouslyVisibleItemsKeysSetMutable];
	}
	
	CGRect rect = [_collectionViewData collectionViewContentRect];
	NSArray *newlyVisibleLayoutAttrs = [_collectionViewData layoutAttributesForElementsInRect:rect];
	NSMutableDictionary *layoutInterchangeData = [NSMutableDictionary dictionaryWithCapacity:[newlyVisibleLayoutAttrs count] + [previouslyVisibleItemsKeysSet count]];
	
	NSMutableSet *newlyVisibleItemsKeys = [NSMutableSet set];
	[newlyVisibleLayoutAttrs enumerateObjectsUsingBlock:^(BTRCollectionViewLayoutAttributes *attr, NSUInteger idx, BOOL *stop) {
		BTRCollectionViewItemKey *newKey = [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:attr];
		[newlyVisibleItemsKeys addObject:newKey];
		
		BTRCollectionViewLayoutAttributes *prevAttr = nil;
		BTRCollectionViewLayoutAttributes *newAttr = nil;
		if (newKey.type == BTRCollectionViewItemTypeDecorationView) {
			prevAttr = [self.collectionViewLayout layoutAttributesForDecorationViewWithReuseIdentifier:attr.representedElementKind atIndexPath:newKey.indexPath];
			newAttr = [layout layoutAttributesForDecorationViewWithReuseIdentifier:attr.representedElementKind atIndexPath:newKey.indexPath];
		} else if (newKey.type == BTRCollectionViewItemTypeCell) {
			prevAttr = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:newKey.indexPath];
			newAttr = [layout layoutAttributesForItemAtIndexPath:newKey.indexPath];
		} else {
			prevAttr = [self.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:attr.representedElementKind atIndexPath:newKey.indexPath];
			newAttr = [layout layoutAttributesForSupplementaryViewOfKind:attr.representedElementKind atIndexPath:newKey.indexPath];
		}
		if (prevAttr && newAttr) {
			layoutInterchangeData[newKey] = [NSDictionary dictionaryWithObjects:@[prevAttr, newAttr] forKeys:@[BTRCollectionViewPreviousLayoutInfoKey, BTRCollectionViewNewLayoutInfoKey]];
		}
	}];
	
	[previouslyVisibleItemsKeysSet enumerateObjectsUsingBlock:^(BTRCollectionViewItemKey *key, BOOL *stop) {
		BTRCollectionViewLayoutAttributes *prevAttr = nil;
		BTRCollectionViewLayoutAttributes *newAttr = nil;
		
		if (key.type == BTRCollectionViewItemTypeDecorationView) {
			BTRCollectionReusableView *decorView = _allVisibleViewsDict[key];
			prevAttr = [self.collectionViewLayout layoutAttributesForDecorationViewWithReuseIdentifier:decorView.reuseIdentifier atIndexPath:key.indexPath];
			newAttr = [layout layoutAttributesForDecorationViewWithReuseIdentifier:decorView.reuseIdentifier atIndexPath:key.indexPath];
		} else if (key.type == BTRCollectionViewItemTypeCell) {
			prevAttr = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:key.indexPath];
			newAttr = [layout layoutAttributesForItemAtIndexPath:key.indexPath];
		} else {
			BTRCollectionReusableView *supplView = _allVisibleViewsDict[key];
			prevAttr = [self.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:supplView.layoutAttributes.representedElementKind atIndexPath:key.indexPath];
			newAttr = [layout layoutAttributesForSupplementaryViewOfKind:supplView.layoutAttributes.representedElementKind atIndexPath:key.indexPath];
		}
		layoutInterchangeData[key] = [NSDictionary dictionaryWithObjects:@[prevAttr, newAttr] forKeys:@[BTRCollectionViewPreviousLayoutInfoKey, BTRCollectionViewNewLayoutInfoKey]];
	}];
	
	[layoutInterchangeData enumerateKeysAndObjectsUsingBlock:^(BTRCollectionViewItemKey *key, id obj, BOOL *stop) {
		if (key.type == BTRCollectionViewItemTypeCell) {
			BTRCollectionViewCell* cell = _allVisibleViewsDict[key];
			if (!cell) {
				cell = [self createPreparedCellForItemAtIndexPath:key.indexPath withLayoutAttributes:layoutInterchangeData[key][BTRCollectionViewPreviousLayoutInfoKey]];
				_allVisibleViewsDict[key] = cell;
				[self addCollectionViewSubview:cell];
			} else {
				[cell applyLayoutAttributes:layoutInterchangeData[key][BTRCollectionViewPreviousLayoutInfoKey]];
			}
		} else if (key.type == BTRCollectionViewItemTypeSupplementaryView) {
			BTRCollectionReusableView *view = _allVisibleViewsDict[key];
			if (!view) {
				BTRCollectionViewLayoutAttributes *attrs = layoutInterchangeData[key][BTRCollectionViewPreviousLayoutInfoKey];
				view = [self createPreparedSupplementaryViewForElementOfKind:attrs.representedElementKind
																 atIndexPath:attrs.indexPath
														withLayoutAttributes:attrs];
			}
		}
	}];
	
	CGRect contentRect = [_collectionViewData collectionViewContentRect];
	
	[self setFrameSize:contentRect.size];
	[self scrollPoint:contentRect.origin];
	
	void (^applyNewLayoutBlock)(void) = ^{
		[layoutInterchangeData enumerateKeysAndObjectsUsingBlock:^(BTRCollectionViewItemKey *key, id obj, BOOL *stop) {
			BTRCollectionViewCell *cell = (BTRCollectionViewCell *)_allVisibleViewsDict[key];
			[cell willTransitionFromLayout:_layout toLayout:layout];
			[cell applyLayoutAttributes:layoutInterchangeData[key][BTRCollectionViewNewLayoutInfoKey]];
			[cell didTransitionFromLayout:_layout toLayout:layout];
		}];
	};
	
	void (^freeUnusedViews)(void) = ^ {
		[_allVisibleViewsDict enumerateKeysAndObjectsUsingBlock:^(BTRCollectionViewItemKey *key, id obj, BOOL *stop) {
			if (![newlyVisibleItemsKeys containsObject:key]) {
				if (key.type == BTRCollectionViewItemTypeCell)
					[self reuseCell:_allVisibleViewsDict[key]];
				else if (key.type == BTRCollectionViewItemTypeSupplementaryView)
					[self reuseSupplementaryView:_allVisibleViewsDict[key]];
			}
		}];
	};
	
	if (animated) {
		[NSView btr_animate:^{
			_collectionViewFlags.updatingLayout = YES;
			applyNewLayoutBlock();
		} completion:^{
			freeUnusedViews();
			_collectionViewFlags.updatingLayout = NO;
		}];
	} else {
		applyNewLayoutBlock();
		freeUnusedViews();
	}
	
	_layout.collectionView = nil;
	_layout = layout;
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
		[[_indexPathsForSelectedItems copy] enumerateObjectsUsingBlock:^(NSIndexPath *selectedIndexPath, NSUInteger idx, BOOL *stop) {
			if (_indexPathsForSelectedItems.count == 1) {
				*stop = YES;
			} else {
				[self deselectItemAtIndexPath:selectedIndexPath animated:YES notifyDelegate:YES];
			}
		}];
	}
}

#pragma mark - Private

- (void)invalidateLayout {
	[self.collectionViewLayout invalidateLayout];
	[self.collectionViewData invalidate];
}

- (void)updateVisibleCells {
	// Build an array of the items that need to be made visible
	NSArray *layoutAttributesArray = [_collectionViewData layoutAttributesForElementsInRect:self.visibleRect];
	NSMutableDictionary *itemKeysToAddDict = [NSMutableDictionary dictionary];
	[layoutAttributesArray enumerateObjectsUsingBlock:^(BTRCollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
		BTRCollectionViewItemKey *itemKey = [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:layoutAttributes];
		itemKeysToAddDict[itemKey] = layoutAttributes;
	}];
	// Build a set of the currently visible items that need to be removed and reused
	NSMutableSet *allVisibleItemKeys = [NSMutableSet setWithArray:[_allVisibleViewsDict allKeys]];
	[allVisibleItemKeys minusSet:[NSSet setWithArray:[itemKeysToAddDict allKeys]]];
	
	// Remove views that are no longer visible and queue them for reuse
	[allVisibleItemKeys enumerateObjectsUsingBlock:^(BTRCollectionViewItemKey *itemKey, BOOL *stop) {
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
	}];
	
	// Add new cells
	[itemKeysToAddDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		BTRCollectionViewItemKey *itemKey = key;
		BTRCollectionViewLayoutAttributes *layoutAttributes = obj;
		BTRCollectionReusableView *view = _allVisibleViewsDict[itemKey];
		if (!view) {
			if (itemKey.type == BTRCollectionViewItemTypeCell) {
				view = [self createPreparedCellForItemAtIndexPath:itemKey.indexPath withLayoutAttributes:layoutAttributes];
			} else if (itemKey.type == BTRCollectionViewItemTypeSupplementaryView) {
				view = [self createPreparedSupplementaryViewForElementOfKind:layoutAttributes.representedElementKind
																 atIndexPath:layoutAttributes.indexPath
														withLayoutAttributes:layoutAttributes];
			}
			if (view) {
				_allVisibleViewsDict[itemKey] = view;
				[self addCollectionViewSubview:view];
			}
		}else {
			[view applyLayoutAttributes:layoutAttributes];
		}
	}];
}

- (BTRCollectionViewCell *)createPreparedCellForItemAtIndexPath:(NSIndexPath *)indexPath withLayoutAttributes:(BTRCollectionViewLayoutAttributes *)layoutAttributes {
	BTRCollectionViewCell *cell = [self.dataSource collectionView:self cellForItemAtIndexPath:indexPath];
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

- (void)queueReusableView:(BTRCollectionReusableView *)reusableView inQueue:(NSMutableDictionary *)queue {
	NSString *cellIdentifier = reusableView.reuseIdentifier;
	NSParameterAssert([cellIdentifier length]);
	
	[reusableView removeFromSuperview];
	[reusableView prepareForReuse];
	
	NSMutableArray *reuseableViews = queue[cellIdentifier];
	if (!reuseableViews) {
		reuseableViews = [NSMutableArray array];
		queue[cellIdentifier] = reuseableViews;
	}
	[reuseableViews addObject:reusableView];
}

- (void)reuseCell:(BTRCollectionViewCell *)cell {
	[self queueReusableView:cell inQueue:_cellReuseQueues];
}

- (void)reuseSupplementaryView:(BTRCollectionReusableView *)supplementaryView {
	[self queueReusableView:supplementaryView inQueue:_supplementaryViewReuseQueues];
}

#pragma mark - Updating grid internal functionality

- (void)suspendReloads {
	_reloadingSuspendedCount++;
}

- (void)resumeReloads {
	if (_reloadingSuspendedCount > 0)
		_reloadingSuspendedCount--;
}

-(NSMutableArray *)arrayForUpdateAction:(BTRCollectionUpdateAction)updateAction {
	NSMutableArray *ret = nil;
	
	switch (updateAction) {
		case BTRCollectionUpdateActionInsert:
			if (!_insertItems) _insertItems = [NSMutableArray new];
			ret = _insertItems;
			break;
		case BTRCollectionUpdateActionDelete:
			if (!_deleteItems) _deleteItems = [NSMutableArray new];
			ret = _deleteItems;
			break;
		case BTRCollectionUpdateActionMove:
			if (_moveItems) _moveItems = [NSMutableArray new];
			ret = _moveItems;
			break;
		case BTRCollectionUpdateActionReload:
			if (!_reloadItems) _reloadItems = [NSMutableArray new];
			ret = _reloadItems;
			break;
		default: break;
	}
	return ret;
}


- (void)prepareLayoutForUpdates {
	NSMutableArray *arr = [NSMutableArray new];
	[arr addObjectsFromArray: [_originalDeleteItems sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)]];
	[arr addObjectsFromArray:[_originalInsertItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
	[arr addObjectsFromArray:[_reloadItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
	[arr addObjectsFromArray: [_moveItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
	[_layout prepareForCollectionViewUpdates:arr];
}

- (void)updateWithItems:(NSArray *) items {
	[self prepareLayoutForUpdates];
	
	NSMutableArray *animations = [NSMutableArray new];
	NSMutableDictionary *newAllVisibleView = [NSMutableDictionary new];
	
	[items enumerateObjectsUsingBlock:^(BTRCollectionViewUpdateItem *updateItem, NSUInteger idx, BOOL *stop) {
		if (!updateItem.isSectionOperation) {
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
					[animations addObject:@{BTRCollectionViewViewKey: view,
					 BTRCollectionViewPreviousLayoutInfoKey: startAttrs, BTRCollectionViewNewLayoutInfoKey: finalAttrs}];
					[_allVisibleViewsDict removeObjectForKey:key];
				}
			} else if (updateItem.updateAction == BTRCollectionUpdateActionInsert) {
				NSIndexPath *indexPath = updateItem.indexPathAfterUpdate;
				BTRCollectionViewItemKey *key = [BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath];
				BTRCollectionViewLayoutAttributes *startAttrs = [_layout initialLayoutAttributesForAppearingItemAtIndexPath:indexPath];
				BTRCollectionViewLayoutAttributes *finalAttrs = [_layout layoutAttributesForItemAtIndexPath:indexPath];
				CGRect startRect = CGRectMake(CGRectGetMidX(startAttrs.frame) - startAttrs.center.x,
											  CGRectGetMidY(startAttrs.frame) - startAttrs.center.y,
											  startAttrs.frame.size.width,
											  startAttrs.frame.size.height);
				CGRect finalRect = CGRectMake(CGRectGetMidX(finalAttrs.frame) - finalAttrs.center.x,
											  CGRectGetMidY(finalAttrs.frame) - finalAttrs.center.y,
											  finalAttrs.frame.size.width,
											  finalAttrs.frame.size.height);
				
				if (CGRectIntersectsRect(self.visibleRect, startRect) || CGRectIntersectsRect(self.visibleRect, finalRect)) {
					BTRCollectionReusableView *view = [self createPreparedCellForItemAtIndexPath:indexPath withLayoutAttributes:startAttrs];
					[self addCollectionViewSubview:view];
					
					newAllVisibleView[key] = view;
					[animations addObject:@{BTRCollectionViewViewKey : view, BTRCollectionViewPreviousLayoutInfoKey : startAttrs ?: finalAttrs, BTRCollectionViewNewLayoutInfoKey: finalAttrs}];
				}
			} else if (updateItem.updateAction == BTRCollectionUpdateActionMove) {
				NSIndexPath *indexPathBefore = updateItem.indexPathBeforeUpdate;
				NSIndexPath *indexPathAfter = updateItem.indexPathAfterUpdate;
				
				BTRCollectionViewItemKey *keyBefore = [BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPathBefore];
				BTRCollectionViewItemKey *keyAfter = [BTRCollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPathAfter];
				BTRCollectionReusableView *view = _allVisibleViewsDict[keyBefore];
				
				BTRCollectionViewLayoutAttributes *startAttrs = nil;
				BTRCollectionViewLayoutAttributes *finalAttrs = [_layout layoutAttributesForItemAtIndexPath:indexPathAfter];
				
				if (view) {
					startAttrs = view.layoutAttributes;
					[_allVisibleViewsDict removeObjectForKey:keyBefore];
					newAllVisibleView[keyAfter] = view;
				} else {
					startAttrs = [finalAttrs copy];
					startAttrs.alpha = 0;
					view = [self createPreparedCellForItemAtIndexPath:indexPathAfter withLayoutAttributes:startAttrs];
					[self addCollectionViewSubview:view];
					newAllVisibleView[keyAfter] = view;
				}
				[animations addObject:@{BTRCollectionViewViewKey : view, BTRCollectionViewPreviousLayoutInfoKey : startAttrs, BTRCollectionViewNewLayoutInfoKey : finalAttrs}];
			}
		}
	}];
	[_allVisibleViewsDict enumerateKeysAndObjectsUsingBlock:^(BTRCollectionViewItemKey *key, id obj, BOOL *stop) {
		BTRCollectionReusableView *view = _allVisibleViewsDict[key];
		NSUInteger oldGlobalIndex = [_currentUpdate[BTRCollectionViewOldModelKey] globalIndexForItemAtIndexPath:key.indexPath];
		NSUInteger newGlobalIndex = NSNotFound;
		if (oldGlobalIndex != NSNotFound) {
			newGlobalIndex = [_currentUpdate[BTRCollectionViewOldToNewIndexMapKey][oldGlobalIndex] unsignedIntegerValue];
		}
		if (newGlobalIndex != NSNotFound) {
			NSIndexPath *newIndexPath = [_currentUpdate[BTRCollectionViewNewModelKey] indexPathForItemAtGlobalIndex:newGlobalIndex];
			
			BTRCollectionViewLayoutAttributes* startAttrs =
			[_layout initialLayoutAttributesForAppearingItemAtIndexPath:newIndexPath];
			
			BTRCollectionViewLayoutAttributes* finalAttrs =
			[_layout layoutAttributesForItemAtIndexPath:newIndexPath];
			
			NSMutableDictionary *animation = [NSMutableDictionary dictionaryWithDictionary:@{BTRCollectionViewViewKey : view}];
			if (startAttrs) [animation setObject:startAttrs forKey:BTRCollectionViewPreviousLayoutInfoKey];
			if (finalAttrs) [animation setObject:finalAttrs forKey:BTRCollectionViewNewLayoutInfoKey];
			[animations addObject:animation];
			BTRCollectionViewItemKey* newKey = [key copy];
			[newKey setIndexPath:newIndexPath];
			newAllVisibleView[newKey] = view;
		}
	}];
	
	NSArray *allNewlyVisibleItems = [_layout layoutAttributesForElementsInRect:self.visibleRect];
	[allNewlyVisibleItems enumerateObjectsUsingBlock:^(BTRCollectionViewLayoutAttributes *attrs, NSUInteger idx, BOOL *stop) {
		BTRCollectionViewItemKey *key = [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:attrs];
		if (![[newAllVisibleView allKeys] containsObject:key]) {
			BTRCollectionViewLayoutAttributes* startAttrs =
			[_layout initialLayoutAttributesForAppearingItemAtIndexPath:attrs.indexPath];
			BTRCollectionReusableView *view = [self createPreparedCellForItemAtIndexPath:attrs.indexPath
																	withLayoutAttributes:startAttrs];
			[self addCollectionViewSubview:view];
			newAllVisibleView[key] = view;
			[animations addObject:@{BTRCollectionViewViewKey : view, BTRCollectionViewPreviousLayoutInfoKey : startAttrs?startAttrs:attrs, BTRCollectionViewNewLayoutInfoKey : attrs}];
		}
	}];

	_allVisibleViewsDict = newAllVisibleView;
	
	[animations enumerateObjectsUsingBlock:^(NSDictionary *animation, NSUInteger idx, BOOL *stop) {
		BTRCollectionReusableView *view = animation[BTRCollectionViewViewKey];
		BTRCollectionViewLayoutAttributes *attr = animation[BTRCollectionViewPreviousLayoutInfoKey];
		[view applyLayoutAttributes:attr];
	}];
	
	[NSView btr_animate:^{
		_collectionViewFlags.updatingLayout = YES;
		[animations enumerateObjectsUsingBlock:^(NSDictionary *animation, NSUInteger idx, BOOL *stop) {
			BTRCollectionReusableView* view = animation[BTRCollectionViewViewKey];
			BTRCollectionViewLayoutAttributes* attrs = animation[BTRCollectionViewNewLayoutInfoKey];
			[view applyLayoutAttributes:attrs];
		}];
	} completion:^{
		NSMutableSet *set = [NSMutableSet set];
		NSArray *visibleItems = [_layout layoutAttributesForElementsInRect:self.visibleRect];
		[visibleItems enumerateObjectsUsingBlock:^(BTRCollectionViewLayoutAttributes *attrs, NSUInteger idx, BOOL *stop) {
			[set addObject: [BTRCollectionViewItemKey collectionItemKeyForLayoutAttributes:attrs]];
		}];
		NSMutableSet *toRemove = [NSMutableSet set];
		[_allVisibleViewsDict enumerateKeysAndObjectsUsingBlock:^(BTRCollectionViewItemKey *key, id obj, BOOL *stop) {
			if (![set containsObject:key]) {
				[self reuseCell:_allVisibleViewsDict[key]];
				[toRemove addObject:key];
			}
		}];
		[toRemove enumerateObjectsUsingBlock:^(id key, BOOL *stop) {
			[_allVisibleViewsDict removeObjectForKey:key];
		}];
		_collectionViewFlags.updatingLayout = NO;
		
		if (_updateCompletionHandler) {
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
	NSUInteger oldNumberOfSections = [oldCollectionViewData numberOfSections];
	NSUInteger newNumberOfSections = [_collectionViewData numberOfSections];
	
	[_layout invalidateLayout];
	[_collectionViewData prepareToLoadData];
	
	NSArray *removeUpdateItems = [[self arrayForUpdateAction:BTRCollectionUpdateActionDelete]
								  sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)];
	NSArray *insertUpdateItems = [[self arrayForUpdateAction:BTRCollectionUpdateActionInsert]
								  sortedArrayUsingSelector:@selector(compareIndexPaths:)];
	NSMutableArray *sortedMutableReloadItems = [[_reloadItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
	NSMutableArray *sortedMutableMoveItems = [[_moveItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
	_originalDeleteItems = [removeUpdateItems copy];
	_originalInsertItems = [insertUpdateItems copy];
	NSMutableArray *removedReloadItems = [NSMutableArray array]; // someMutableArr2
	NSMutableArray *insertedReloadItems = [NSMutableArray array]; // someMutableArr3
	
	[sortedMutableReloadItems enumerateObjectsUsingBlock:^(BTRCollectionViewUpdateItem *updateItem, NSUInteger idx, BOOL *stop) {
		
		NSAssert(updateItem.indexPathBeforeUpdate.section < oldNumberOfSections,
				 @"Attempting to reload an item (%@) in a section that does not exist. The total number of sections is %ld.", updateItem.indexPathBeforeUpdate, oldNumberOfSections);
		NSUInteger numberOfItems = [oldCollectionViewData numberOfItemsInSection:updateItem.indexPathBeforeUpdate.section];
		NSAssert(updateItem.indexPathBeforeUpdate.item < numberOfItems,
				 @"Attempting to reload an item (%@) that does not exist. There are only %ld items in section %ld.",
				 updateItem.indexPathBeforeUpdate, numberOfItems, updateItem.indexPathBeforeUpdate.section);
		BTRCollectionViewUpdateItem *remove = [[BTRCollectionViewUpdateItem alloc] initWithAction:BTRCollectionUpdateActionDelete forIndexPath:updateItem.indexPathBeforeUpdate];
		BTRCollectionViewUpdateItem *insert = [[BTRCollectionViewUpdateItem alloc] initWithAction:BTRCollectionUpdateActionInsert forIndexPath:updateItem.indexPathAfterUpdate];
		[removedReloadItems addObject:remove];
		[insertedReloadItems addObject:insert];
	}];
	
	NSMutableArray *sortedMutableDeleteItems = [[_deleteItems sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)] mutableCopy];
	NSMutableArray *sortedMutableInsertItems = [[_insertItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
	NSMutableDictionary *operations = [NSMutableDictionary dictionary];
	
	[sortedMutableDeleteItems enumerateObjectsUsingBlock:^(BTRCollectionViewUpdateItem *deleteItem, NSUInteger idx, BOOL *stop) {
		if (deleteItem.isSectionOperation) {
			NSAssert(deleteItem.indexPathBeforeUpdate.section < oldNumberOfSections,
					 @"Attempting to delete a section (%ld) that does not exist. The total number of sections is %ld.",
					 deleteItem.indexPathBeforeUpdate.section, oldNumberOfSections);
			[sortedMutableMoveItems enumerateObjectsUsingBlock:^(BTRCollectionViewUpdateItem *moveItem, NSUInteger midx, BOOL *mstop) {
				if (moveItem.indexPathBeforeUpdate.section == deleteItem.indexPathBeforeUpdate.section) {
					if (moveItem.isSectionOperation) {
						NSAssert(NO, @"Attempting to move and delete the same section (%ld)", deleteItem.indexPathBeforeUpdate.section);
					} else {
						NSAssert(NO, @"Attempting to move an item in a section that is also being deleted (%@)", moveItem.indexPathBeforeUpdate);
					}
				}
			}];
		} else {
			NSAssert(deleteItem.indexPathBeforeUpdate.section < oldNumberOfSections,
					 @"Attempting to delete an item (%@) in a section that does not exist. The total number of sections is %ld",
					 deleteItem.indexPathBeforeUpdate, oldNumberOfSections);
			NSUInteger numberOfItems = [oldCollectionViewData numberOfItemsInSection:deleteItem.indexPathBeforeUpdate.section];
			NSAssert(deleteItem.indexPathBeforeUpdate.item < numberOfItems,
					 @"Attempting to reload an item (%@) that does not exist. There are only %ld items in section %ld.",
					 deleteItem.indexPathBeforeUpdate, numberOfItems, deleteItem.indexPathBeforeUpdate.section);
			[sortedMutableMoveItems enumerateObjectsUsingBlock:^(BTRCollectionViewUpdateItem *moveItem, NSUInteger midx, BOOL *mstop) {
				NSAssert([deleteItem.indexPathBeforeUpdate isEqual:moveItem.indexPathBeforeUpdate],
						 @"Attempting to move and delete the same item (%@)", deleteItem.indexPathBeforeUpdate);
			}];
			
			NSNumber *section = @(deleteItem.indexPathBeforeUpdate.section);
			if (!operations[section])
				operations[section] = [NSMutableDictionary dictionary];
			// Used to track the number of deleted items in a particular section
			operations[section][BTRCollectionViewDeletedItemsCount] =
			@([operations[section][BTRCollectionViewDeletedItemsCount] unsignedIntegerValue] + 1);
		}
	}];
	
	for (NSUInteger i = 0; i < [sortedMutableInsertItems count]; i++) {
		BTRCollectionViewUpdateItem *insertItem = sortedMutableInsertItems[i];
		NSIndexPath *indexPath = insertItem.indexPathAfterUpdate;
		
		if (insertItem.isSectionOperation) {
			NSAssert(indexPath.section < newNumberOfSections, @"Attempting to insert section %ld but the total number of sections is %ld.", indexPath.section, newNumberOfSections);
			[sortedMutableMoveItems enumerateObjectsUsingBlock:^(BTRCollectionViewUpdateItem *moveItem, NSUInteger idx, BOOL *stop) {
				if ([moveItem.indexPathAfterUpdate isEqual:indexPath] && moveItem.isSectionOperation) {
					NSAssert(NO, @"Attempting to insert and move the same section (%ld)", indexPath.section);
				}
			}];
			// Enumerate the items in the inserted array that come after the current item
			NSUInteger j = i + 1;
			while (j < [sortedMutableInsertItems count]) {
				BTRCollectionViewUpdateItem *nextInsertItem = sortedMutableInsertItems[j];
				// We're looking for inserted items that will be inserted 
				if (nextInsertItem.indexPathAfterUpdate.section == indexPath.section) {
					NSUInteger numberOfItems = [_collectionViewData numberOfItemsInSection:indexPath.section];
					NSAssert(nextInsertItem.indexPathAfterUpdate.item < numberOfItems, @"Attempting to insert item %ld into section %ld but there are only %ld items in the section after the update.", nextInsertItem.indexPathAfterUpdate.item, indexPath.section, numberOfItems, indexPath.section);
					[sortedMutableInsertItems removeObjectAtIndex:j];
				} else break;
			}
		} else {
			NSUInteger numberOfItems = [_collectionViewData numberOfItemsInSection:indexPath.section];
			NSAssert(indexPath.item < numberOfItems, @"Attempting to insert item at %@, but there are only %ld items total in section %ld after the update.", indexPath, numberOfItems, indexPath.section);
			NSNumber *section = @(indexPath.section);
			if (!operations[section])
				operations[section] = [NSMutableDictionary dictionary];
			
			operations[section][BTRCollectionViewInsertedItemsCount] = @([operations[section][BTRCollectionViewInsertedItemsCount] unsignedIntegerValue] + 1);
		}
	}
	
	[sortedMutableMoveItems enumerateObjectsUsingBlock:^(BTRCollectionViewUpdateItem *sortedItem, NSUInteger idx, BOOL *stop) {
		if (sortedItem.isSectionOperation) {
			NSAssert(sortedItem.indexPathBeforeUpdate.section < oldNumberOfSections,
					 @"Attempting to move a section (%ld) but the total number of sections before update is %ld",
					 sortedItem.indexPathBeforeUpdate.section, oldNumberOfSections);
			NSAssert(sortedItem.indexPathAfterUpdate.section < newNumberOfSections,
					 @"Attempting to move a section to %ld but there are only %ld sections after update",
					 sortedItem.indexPathAfterUpdate.section, newNumberOfSections);
		} else {
			NSAssert(sortedItem.indexPathBeforeUpdate.section < oldNumberOfSections,
					 @"Attempting to move an item (%@) that doesn't exist. The total number of sections before updating is %ld.", sortedItem, oldNumberOfSections);
			NSUInteger numberOfItemsBefore = [oldCollectionViewData numberOfItemsInSection:sortedItem.indexPathBeforeUpdate.section];
			NSAssert(sortedItem.indexPathBeforeUpdate.item < numberOfItemsBefore,
					 @"Attempting to move an item (%@) that doesn't exist. There are %ld items in section %ld before update.",
					 sortedItem, numberOfItemsBefore, sortedItem.indexPathBeforeUpdate.section);
			NSAssert(sortedItem.indexPathAfterUpdate.section < newNumberOfSections,
					 @"Attempting to move an item to (%@) but there are only %ld sections after update.", sortedItem.indexPathAfterUpdate, newNumberOfSections);
			NSUInteger numberOfItemsAfter = [_collectionViewData numberOfItemsInSection:sortedItem.indexPathAfterUpdate.section];
			NSAssert(sortedItem.indexPathAfterUpdate.item < numberOfItemsAfter,
					 @"Attempting to move an item to (%@) but there are only %ld items in section %ld after update.",
					 sortedItem, numberOfItemsAfter, sortedItem.indexPathAfterUpdate.section);
		}
		
		NSNumber *beforeSection = @(sortedItem.indexPathBeforeUpdate.section);
		NSNumber *afterSection = @(sortedItem.indexPathAfterUpdate.section);
		if (!operations[beforeSection])
			operations[beforeSection] = [NSMutableDictionary dictionary];
		if (!operations[afterSection])
			operations[afterSection] = [NSMutableDictionary dictionary];
		
		operations[beforeSection][BTRCollectionViewMovedOutCount] =
		@([operations[beforeSection][BTRCollectionViewMovedOutCount] unsignedIntegerValue] + 1);
		
		operations[afterSection][BTRCollectionViewMovedInCount] =
		@([operations[afterSection][BTRCollectionViewMovedInCount] unsignedIntegerValue] + 1);
	}];
	
#if !defined  NS_BLOCK_ASSERTIONS
	[operations enumerateKeysAndObjectsUsingBlock:^(NSNumber *sectionKey, id obj, BOOL *stop) {
		NSUInteger section = [sectionKey unsignedIntegerValue];
		
		NSUInteger insertedCount = [operations[sectionKey][BTRCollectionViewInsertedItemsCount] unsignedIntegerValue];
		NSUInteger deletedCount = [operations[sectionKey][BTRCollectionViewDeletedItemsCount] unsignedIntegerValue];
		NSUInteger movedInCount = [operations[sectionKey][BTRCollectionViewMovedInCount] unsignedIntegerValue];
		NSUInteger movedOutCount = [operations[sectionKey][BTRCollectionViewMovedOutCount] unsignedIntegerValue];
		
		NSUInteger newNumberOfItems = [_collectionViewData numberOfItemsInSection:section];
		NSUInteger oldNumberOfItems = [oldCollectionViewData numberOfItemsInSection:section];
		NSAssert([oldCollectionViewData numberOfItemsInSection:section] + insertedCount - deletedCount + movedInCount -movedOutCount == newNumberOfItems, @"Invalid update in section %ld: number of items after update (%ld) should be equal to the number of items before update (%ld) plus the count of inserted items (%ld), minus the count of deleted items (%ld), plus the count of items moved in (%ld), minus the count of items moved out (%ld)",
				 section, newNumberOfItems, oldNumberOfItems, insertedCount, deletedCount, movedInCount, movedOutCount);
	}];
#endif
	
	[removedReloadItems addObjectsFromArray:sortedMutableDeleteItems];
	[insertedReloadItems addObjectsFromArray:sortedMutableInsertItems];

	NSMutableArray *items = [NSMutableArray array];
	[items addObjectsFromArray:[removedReloadItems sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)]];
	[items addObjectsFromArray:sortedMutableMoveItems];
	[items addObjectsFromArray:[insertedReloadItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
	
	NSMutableArray *layoutUpdateItems = [NSMutableArray new];
	[layoutUpdateItems addObjectsFromArray:sortedMutableDeleteItems];
	[layoutUpdateItems addObjectsFromArray:sortedMutableMoveItems];
	[layoutUpdateItems addObjectsFromArray:sortedMutableInsertItems];
	
	NSMutableArray *newModel = [NSMutableArray array];
	for (NSUInteger i = 0; i < oldNumberOfSections; i++) {
		NSMutableArray *sectionArr = [NSMutableArray array];
		for (NSUInteger j = 0; j < [oldCollectionViewData numberOfItemsInSection:i]; j++)
			[sectionArr addObject:@([oldCollectionViewData globalIndexForItemAtIndexPath:[NSIndexPath btr_indexPathForItem:j inSection:i]])];
		[newModel addObject:sectionArr];
	}
	
	[layoutUpdateItems enumerateObjectsUsingBlock:^(BTRCollectionViewUpdateItem *updateItem, NSUInteger idx, BOOL *stop) {
		switch (updateItem.updateAction) {
			case BTRCollectionUpdateActionDelete: {
				if (updateItem.isSectionOperation) {
					[newModel removeObjectAtIndex:updateItem.indexPathBeforeUpdate.section];
				} else {
					[newModel[updateItem.indexPathBeforeUpdate.section] removeObjectAtIndex:updateItem.indexPathBeforeUpdate.item];
				}
			} break;
			case BTRCollectionUpdateActionInsert: {
				if (updateItem.isSectionOperation) {
					[newModel insertObject:[NSMutableArray new] atIndex:updateItem.indexPathAfterUpdate.section];
				} else {
					[newModel[updateItem.indexPathAfterUpdate.section] insertObject:@(NSNotFound) atIndex:updateItem.indexPathAfterUpdate.item];
				}
			} break;
			case BTRCollectionUpdateActionMove: {
				if (updateItem.isSectionOperation) {
					id section = newModel[updateItem.indexPathBeforeUpdate.section];
					[newModel insertObject:section atIndex:updateItem.indexPathAfterUpdate.section];
				} else {
					id object = newModel[updateItem.indexPathBeforeUpdate.section][updateItem.indexPathBeforeUpdate.item];
					[newModel[updateItem.indexPathBeforeUpdate.section] removeObjectAtIndex:updateItem.indexPathBeforeUpdate.item];
					[newModel[updateItem.indexPathAfterUpdate.section] insertObject:object atIndex:updateItem.indexPathAfterUpdate.item];
				}
			} break;
			default: break;
		}
	}];

	
	NSMutableArray *oldToNewMap = [NSMutableArray arrayWithCapacity:[oldCollectionViewData numberOfItems]];
	NSMutableArray *newToOldMap = [NSMutableArray arrayWithCapacity:[_collectionViewData numberOfItems]];
	
	for (NSUInteger i = 0; i < [oldCollectionViewData numberOfItems]; i++)
		[oldToNewMap addObject:@(NSNotFound)];
	
	for (NSUInteger i = 0; i < [_collectionViewData numberOfItems]; i++)
		[newToOldMap addObject:@(NSNotFound)];
	
	for (NSUInteger i = 0; i < [newModel count]; i++) {
		NSMutableArray *section = newModel[i];
		for (NSUInteger j = 0; j < [section count]; j++) {
			NSUInteger newGlobalIndex = [_collectionViewData globalIndexForItemAtIndexPath:[NSIndexPath btr_indexPathForItem:j inSection:i]];
			if ([section[j] unsignedIntegerValue] != NSNotFound)
				oldToNewMap[[section[j] unsignedIntegerValue]] = @(newGlobalIndex);
			if (newGlobalIndex != NSNotFound)
				newToOldMap[newGlobalIndex] = section[j];
		}
	}
	NSMutableDictionary *update = @{ BTRCollectionViewNewModelKey : _collectionViewData,
			 BTRCollectionViewOldToNewIndexMapKey : oldToNewMap,
			 BTRCollectionViewNewToOldIndexMapKey : newToOldMap}.mutableCopy;
	if (oldCollectionViewData) update[BTRCollectionViewOldModelKey] = oldCollectionViewData;
	_currentUpdate = update;
	
	[self updateWithItems:items];
	
	_originalInsertItems = nil;
	_originalDeleteItems = nil;
	_insertItems = nil;
	_deleteItems = nil;
	_moveItems = nil;
	_reloadItems = nil;
	_currentUpdate = nil;
	_updateCount--;
	_collectionViewFlags.updating = NO;
	[self resumeReloads];
}


- (void)updateRowsAtIndexPaths:(NSArray *)indexPaths updateAction:(BTRCollectionUpdateAction)updateAction {
	BOOL updating = _collectionViewFlags.updating;
	if (!updating) {
		[self setupCellAnimations];
	}
	NSMutableArray *array = [self arrayForUpdateAction:updateAction];
	[indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
		BTRCollectionViewUpdateItem *updateItem = [[BTRCollectionViewUpdateItem alloc] initWithAction:updateAction
																						 forIndexPath:indexPath];
		[array addObject:updateItem];
	}];
	if (!updating) [self endItemAnimations];
}


- (void)updateSections:(NSIndexSet *)sections updateAction:(BTRCollectionUpdateAction)updateAction {
	BOOL updating = _collectionViewFlags.updating;
	if (!updating) {
		[self setupCellAnimations];
	}
	
	NSMutableArray *updateActions = [self arrayForUpdateAction:updateAction];
	NSUInteger section = [sections firstIndex];
	
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
	
	NSUInteger _numberOfItems;
	NSUInteger _numberOfSections;
	NSUInteger *_sectionItemCounts;
	NSArray *_globalItems;
	NSArray *_cellLayoutAttributes;
	
	CGSize _contentSize;
	struct {
	 	unsigned int itemCountsAreValid:1;
	 	unsigned int layoutIsPrepared:1;
	} _collectionViewDataFlags;
}
@property (nonatomic, unsafe_unretained) BTRCollectionView *collectionView;
@property (nonatomic, unsafe_unretained) BTRCollectionViewLayout *layout;
@end

@implementation BTRCollectionViewData

#pragma mark - NSObject

- (id)initWithCollectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)layout {
	if ((self = [super init])) {
		_globalItems = [NSArray new];
		_collectionView = collectionView;
		_layout = layout;
	}
	return self;
}

- (void)dealloc {
	if (_sectionItemCounts) free(_sectionItemCounts);
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p numItems:%ld numSections:%ld globalItems:%@>", NSStringFromClass([self class]), self, self.numberOfItems, self.numberOfSections, _globalItems];
}

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
	rect.size.width = fminf(rect.size.width, _contentSize.width);
	rect.size.height = fminf(rect.size.height, _contentSize.height);
	
	// TODO: check if we need to fetch data from layout
	if (!CGRectEqualToRect(_validLayoutRect, rect)) {
		_validLayoutRect = rect;
		_cellLayoutAttributes = [self.layout layoutAttributesForElementsInRect:rect];
	}
}

- (NSUInteger)numberOfItems {
	[self validateItemCounts];
	return _numberOfItems;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section {
	[self validateItemCounts];
	if (section > _numberOfSections) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Section %ld out of range: 0...%ld", section, _numberOfSections] userInfo:nil];
	}
	
	NSUInteger numberOfItemsInSection = 0;
	if (_sectionItemCounts) {
		numberOfItemsInSection = _sectionItemCounts[section];
	}
	return numberOfItemsInSection;
}

- (NSUInteger)numberOfSections {
	[self validateItemCounts];
	return _numberOfSections;
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath {
	return CGRectZero;
}

- (NSIndexPath *)indexPathForItemAtGlobalIndex:(NSUInteger)index {
	return _globalItems[index];
}

- (NSUInteger)globalIndexForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [_globalItems indexOfObject:indexPath];
}

- (BOOL)layoutIsPrepared {
	return _collectionViewDataFlags.layoutIsPrepared;
}

- (void)setLayoutIsPrepared:(BOOL)layoutIsPrepared {
	_collectionViewDataFlags.layoutIsPrepared = layoutIsPrepared;
}

#pragma mark - Fetch Layout Attributes

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	[self validateLayoutInRect:rect];
	return _cellLayoutAttributes;
}

#pragma mark - Private

- (void)validateItemCounts {
	if (!_collectionViewDataFlags.itemCountsAreValid) {
		[self updateItemCounts];
	}
}

- (void)updateItemCounts {
	// Assume one section by default
	_numberOfSections = 1;
	if ([self.collectionView.dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
		_numberOfSections = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
	}
	if (_numberOfSections <= 0) { // early bail-out
		_numberOfItems = 0;
		free(_sectionItemCounts); _sectionItemCounts = 0;
		return;
	}
	// Allocate space for the arrays
	if (!_sectionItemCounts) {
		_sectionItemCounts = malloc(_numberOfSections * sizeof(NSUInteger));
	}else {
		_sectionItemCounts = realloc(_sectionItemCounts, _numberOfSections * sizeof(NSUInteger));
	}
	
	// Query the number of cells per section
	_numberOfItems = 0;
	for (NSUInteger i = 0; i <_numberOfSections; i++) {
		NSUInteger cellCount = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:i];
		_sectionItemCounts[i] = cellCount;
		_numberOfItems += cellCount;
	}
	// Create the global index paths array
	NSMutableArray *globalIndexPaths = [[NSMutableArray alloc] initWithCapacity:_numberOfItems];
	for (NSUInteger section = 0; section < _numberOfSections; section++)
		for (NSUInteger item = 0; item < _sectionItemCounts[section]; item++)
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
		if (_identifier && _type == otherKeyItem.type && [_indexPath isEqual:otherKeyItem.indexPath] && ([_identifier isEqualToString:otherKeyItem.identifier] || _identifier == otherKeyItem.identifier)) {
			return YES;
		}
	}
	return NO;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	BTRCollectionViewItemKey *itemKey = [[self class] new];
	itemKey.indexPath = self.indexPath;
	itemKey.type = self.type;
	itemKey.identifier = self.identifier;
	return itemKey;
}

@end

@implementation BTRCollectionViewUpdateItem

@synthesize updateAction = _updateAction;

- (id)initWithInitialIndexPath:(NSIndexPath *)initialIndexPath finalIndexPath:(NSIndexPath *)finalIndexPath updateAction:(BTRCollectionUpdateAction)updateAction {
	if ((self = [super init])) {
		_indexPathBeforeUpdate = initialIndexPath;
		_indexPathAfterUpdate = finalIndexPath;
		_updateAction = updateAction;
	}
	return self;
}

- (id)initWithAction:(BTRCollectionUpdateAction)updateAction forIndexPath:(NSIndexPath*)indexPath {
	if (updateAction == BTRCollectionUpdateActionInsert)
		return [self initWithInitialIndexPath:nil finalIndexPath:indexPath updateAction:updateAction];
	else if (updateAction == BTRCollectionUpdateActionDelete)
		return [self initWithInitialIndexPath:indexPath finalIndexPath:nil updateAction:updateAction];
	else if (updateAction == BTRCollectionUpdateActionReload)
		return [self initWithInitialIndexPath:indexPath finalIndexPath:indexPath updateAction:updateAction];
	
	return nil;
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
	
	return [NSString stringWithFormat:@"Index path before update (%@) index path after update (%@) action (%@).",  _indexPathBeforeUpdate, _indexPathAfterUpdate, action];
}

- (BOOL)isSectionOperation {
	return (_indexPathBeforeUpdate.item == NSNotFound || _indexPathAfterUpdate.item == NSNotFound);
}

- (NSComparisonResult)compareIndexPaths:(BTRCollectionViewUpdateItem *)otherItem {
	NSComparisonResult result = NSOrderedSame;
	NSIndexPath *selfIndexPath = nil;
	NSIndexPath *otherIndexPath = nil;
	
	switch (_updateAction) {
		case BTRCollectionUpdateActionInsert:
			selfIndexPath = _indexPathAfterUpdate;
			otherIndexPath = otherItem.indexPathAfterUpdate;
			break;
		case BTRCollectionUpdateActionDelete:
			selfIndexPath = _indexPathBeforeUpdate;
			otherIndexPath = otherItem.indexPathBeforeUpdate;
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
