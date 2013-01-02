//
//  BTRCollectionViewFlowLayout.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRCollectionViewFlowLayout.h"
#import "BTRCollectionView.h"
#import "BTRGeometryAdditions.h"
#import "NSIndexPath+BTRAdditions.h"
#import "NSValue+BTRAdditions.h"
#import <objc/runtime.h>

NSString *const BTRFlowLayoutCommonRowHorizontalAlignmentKey = @"BTRFlowLayoutCommonRowHorizontalAlignmentKey";
NSString *const BTRFlowLayoutLastRowHorizontalAlignmentKey = @"BTRFlowLayoutLastRowHorizontalAlignmentKey";
NSString *const BTRFlowLayoutRowVerticalAlignmentKey = @"BTRFlowLayoutRowVerticalAlignmentKey";

// Represents a single grid item; only created for non-uniform-sized grids.
@class BTRGridLayoutItem, BTRGridLayoutRow, BTRGridLayoutSection;
@interface BTRGridLayoutRow : NSObject

@property (nonatomic, unsafe_unretained) BTRGridLayoutSection *section;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, assign) CGSize rowSize;
@property (nonatomic, assign) CGRect rowFrame;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) BOOL complete;
@property (nonatomic, assign) BOOL fixedItemSize;
@property (nonatomic, assign) NSUInteger itemCount;

// Add new item to items array.
- (void)addItem:(BTRGridLayoutItem *)item;

// Layout current row (if invalid)
- (void)layoutRow;

// Returns the item rects when fixedItemSize is enabled.
- (NSArray *)itemRects;

//  Set current row frame invalid.
- (void)invalidate;
@end

@interface BTRGridLayoutSection : NSObject

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *rows;

// Triggers fast layout for equal sized items
@property (nonatomic, assign) BOOL fixedItemSize;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) NSUInteger itemsCount;

@property (nonatomic, assign) CGFloat verticalInterstice;
@property (nonatomic, assign) CGFloat horizontalInterstice;
@property (nonatomic, assign) NSEdgeInsets sectionMargins;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGRect headerFrame;
@property (nonatomic, assign) CGRect footerFrame;
@property (nonatomic, assign) CGFloat headerDimension;
@property (nonatomic, assign) CGFloat footerDimension;
@property (nonatomic, unsafe_unretained) BTRGridLayoutInfo *layoutInfo;
@property (nonatomic, strong) NSDictionary *rowAlignmentOptions;

@property (nonatomic, assign) CGFloat otherMargin;
@property (nonatomic, assign) CGFloat beginMargin;
@property (nonatomic, assign) CGFloat endMargin;
@property (nonatomic, assign) CGFloat actualGap;
@property (nonatomic, assign) CGFloat lastRowBeginMargin;
@property (nonatomic, assign) CGFloat lastRowEndMargin;
@property (nonatomic, assign) CGFloat lastRowActualGap;
@property (nonatomic, assign) BOOL lastRowIncomplete;
@property (nonatomic, assign) NSUInteger itemsByRowCount;
@property (nonatomic, assign) NSUInteger indexOfImcompleteRow; // typo as of iOS6B3

// Faster variant of invalidate/compute
- (void)recomputeFromIndex:(NSInteger)index;

// Invalidate layout. Destroys rows.
- (void)invalidate;

// Compute layout. Creates rows.
- (void)computeLayout;

- (BTRGridLayoutItem *)addItem;
- (BTRGridLayoutRow *)addRow;
@end

@interface BTRGridLayoutItem : NSObject

@property (nonatomic, unsafe_unretained) BTRGridLayoutSection *section;
@property (nonatomic, unsafe_unretained) BTRGridLayoutRow *rowObject;
@property (nonatomic, assign) CGRect itemFrame;

@end

@interface BTRGridLayoutInfo : NSObject

@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) NSDictionary *rowAlignmentOptions;
@property (nonatomic, assign) BOOL usesFloatingHeaderFooter;

// Vertical/horizontal dimension (depending on horizontal)
// Used to create row objects
@property (nonatomic, assign) CGFloat dimension;

@property (nonatomic, assign) BOOL horizontal;
@property (nonatomic, assign) BOOL leftToRight;
@property (nonatomic, assign) CGSize contentSize;

// Frame for specific BTRGridLayoutItem.
- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath;

// Add new section. Invalidates layout.
- (BTRGridLayoutSection *)addSection;

// forces the layout to recompute on next access
// TODO; what's the parameter for?
- (void)invalidate:(BOOL)arg;
@end

@implementation BTRCollectionViewFlowLayout {
    struct {
        unsigned int delegateSizeForItem : 1;
        unsigned int delegateReferenceSizeForHeader : 1;
        unsigned int delegateReferenceSizeForFooter : 1;
        unsigned int delegateInsetForSection : 1;
        unsigned int delegateInteritemSpacingForSection : 1;
        unsigned int delegateLineSpacingForSection : 1;
        unsigned int delegateAlignmentOptions : 1;
    } _gridLayoutFlags;
    CGSize _itemSize;
    BTRGridLayoutInfo *_data;
    CGSize _currentLayoutSize;
    NSMutableDictionary *_insertedItemsAttributesDict;
    NSMutableDictionary *_insertedSectionHeadersAttributesDict;
    NSMutableDictionary *_insertedSectionFootersAttributesDict;
    NSMutableDictionary *_deletedItemsAttributesDict;
    NSMutableDictionary *_deletedSectionHeadersAttributesDict;
    NSMutableDictionary *_deletedSectionFootersAttributesDict;
	NSMutableDictionary *_cachedItemRects;
    BTRCollectionViewScrollDirection _scrollDirection;
    NSDictionary *_rowAlignmentsOptionsDictionary;
}

@synthesize rowAlignmentOptions = _rowAlignmentsOptionsDictionary;

#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
        _itemSize = CGSizeMake(50.f, 50.f);
		_minimumLineSpacing = 10.f;
		_minimumInteritemSpacing = 10.f;
		_sectionInset = BTRNSEdgeInsetsZero;
		_scrollDirection = BTRCollectionViewScrollDirectionVertical;
		_headerReferenceSize = CGSizeZero;
		_footerReferenceSize = CGSizeZero;
		_cachedItemRects = [NSMutableDictionary dictionary];
        _rowAlignmentsOptionsDictionary = @{
        BTRFlowLayoutCommonRowHorizontalAlignmentKey : @(BTRFlowLayoutHorizontalAlignmentJustify),
        BTRFlowLayoutLastRowHorizontalAlignmentKey : @(BTRFlowLayoutHorizontalAlignmentJustify),
        BTRFlowLayoutRowVerticalAlignmentKey : @(1),
        };
    }
    return self;
}

#pragma mark - BTRCollectionViewLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributesArray = [NSMutableArray array];
    for (BTRGridLayoutSection *section in _data.sections) {
        if (CGRectIntersectsRect(section.frame, rect)) {
			// Calculate item sizes only once for fixed sizing using BTRFlowLayoutCommonRowHorizontalAlignmentKey alignment
            NSUInteger sectionIndex = [_data.sections indexOfObjectIdenticalTo:section];

			CGRect normalizedHeaderFrame = section.headerFrame;
			normalizedHeaderFrame.origin.x += section.frame.origin.x;
			normalizedHeaderFrame.origin.y += section.frame.origin.y;
			if (!CGRectIsEmpty(normalizedHeaderFrame) && CGRectIntersectsRect(normalizedHeaderFrame, rect)) {
				BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BTRCollectionElementKindSectionHeader withIndexPath:[NSIndexPath btr_indexPathForItem:0 inSection:sectionIndex]];
				layoutAttributes.frame = normalizedHeaderFrame;
				[layoutAttributesArray addObject:layoutAttributes];
			}

            NSArray *itemRects = _cachedItemRects[@(sectionIndex)];
            if (!itemRects && section.fixedItemSize && [section.rows count]) {
                itemRects = [(section.rows)[0] itemRects];
                if (itemRects) _cachedItemRects[@(sectionIndex)] = itemRects;
            }

			for (BTRGridLayoutRow *row in section.rows) {
                CGRect normalizedRowFrame = row.rowFrame;
                normalizedRowFrame.origin.x += section.frame.origin.x;
                normalizedRowFrame.origin.y += section.frame.origin.y;
                if (CGRectIntersectsRect(normalizedRowFrame, rect)) {
                    for (NSUInteger itemIndex = 0; itemIndex < row.itemCount; itemIndex++) {
                        BTRCollectionViewLayoutAttributes *layoutAttributes;
                        NSUInteger sectionItemIndex;
                        CGRect itemFrame;
                        if (row.fixedItemSize) {
                            itemFrame = [itemRects[itemIndex] btr_CGRectValue];
                            sectionItemIndex = row.index * section.itemsByRowCount + itemIndex;
                        }else {
                            BTRGridLayoutItem *item = row.items[itemIndex];
                            sectionItemIndex = [section.items indexOfObjectIdenticalTo:item];
                            itemFrame = item.itemFrame;
                        }
                        layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath btr_indexPathForItem:sectionItemIndex inSection:sectionIndex]];
                        layoutAttributes.frame = CGRectMake(normalizedRowFrame.origin.x + itemFrame.origin.x, normalizedRowFrame.origin.y + itemFrame.origin.y, itemFrame.size.width, itemFrame.size.height);
                        [layoutAttributesArray addObject:layoutAttributes];
                    }
                }
            }

			CGRect normalizedFooterFrame = section.footerFrame;
			normalizedFooterFrame.origin.x += section.frame.origin.x;
			normalizedFooterFrame.origin.y += section.frame.origin.y;
			if (!CGRectIsEmpty(normalizedFooterFrame) && CGRectIntersectsRect(normalizedFooterFrame, rect)) {
				BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BTRCollectionElementKindSectionFooter withIndexPath:[NSIndexPath btr_indexPathForItem:0 inSection:sectionIndex]];
				layoutAttributes.frame = normalizedFooterFrame;
				[layoutAttributesArray addObject:layoutAttributes];
			}
        }
    }
    return layoutAttributesArray;
}

- (BTRCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    BTRGridLayoutSection *section = _data.sections[indexPath.section];
    BTRGridLayoutRow *row = nil;
    CGRect itemFrame = CGRectZero;

    if (section.fixedItemSize && [section.rows count] && indexPath.item / section.itemsByRowCount < [section.rows count]) {
        row = section.rows[indexPath.item / section.itemsByRowCount];
        NSUInteger itemIndex = indexPath.item % section.itemsByRowCount;
        NSArray *itemRects = [row itemRects];
        itemFrame = [itemRects[itemIndex] btr_CGRectValue];
    } else if (indexPath.item < [section.items count]) {
        BTRGridLayoutItem *item = section.items[indexPath.item];
        row = item.rowObject;
        itemFrame = item.itemFrame;
    }

    BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    CGRect normalizedRowFrame = row.rowFrame;
    normalizedRowFrame.origin.x += section.frame.origin.x;
    normalizedRowFrame.origin.y += section.frame.origin.y;
    layoutAttributes.frame = CGRectMake(normalizedRowFrame.origin.x + itemFrame.origin.x, normalizedRowFrame.origin.y + itemFrame.origin.y, itemFrame.size.width, itemFrame.size.height);

    return layoutAttributes;
}

- (BTRCollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSUInteger sectionIndex = indexPath.section;

    if (sectionIndex < _data.sections.count) {
        BTRGridLayoutSection *section = _data.sections[sectionIndex];
        CGRect normalizedHeaderFrame = section.headerFrame;

        if (!CGRectIsEmpty(normalizedHeaderFrame)) {
            normalizedHeaderFrame.origin.x += section.frame.origin.x;
            normalizedHeaderFrame.origin.y += section.frame.origin.y;

            BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BTRCollectionElementKindSectionHeader withIndexPath:[NSIndexPath btr_indexPathForItem:0 inSection:sectionIndex]];
            layoutAttributes.frame = normalizedHeaderFrame;

            return layoutAttributes;
        }
    }

    return nil;
}

- (BTRCollectionViewLayoutAttributes *)layoutAttributesForDecorationViewWithReuseIdentifier:(NSString*)identifier atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (CGSize)collectionViewContentSize {
    return _data.contentSize;
}

#pragma mark - Invalidating the Layout

- (void)invalidateLayout {
    _cachedItemRects = [NSMutableDictionary dictionary];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size);
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    return proposedContentOffset;
}

- (void)prepareLayout {
    _data = [BTRGridLayoutInfo new];
    _data.horizontal = self.scrollDirection == BTRCollectionViewScrollDirectionHorizontal;
    CGSize collectionViewSize = self.collectionView.enclosingScrollView.bounds.size;
    _data.dimension = _data.horizontal ? collectionViewSize.height : collectionViewSize.width;
    _data.rowAlignmentOptions = _rowAlignmentsOptionsDictionary;
    [self fetchItemsInfo];
}

#pragma mark - Private

- (void)fetchItemsInfo {
    [self getSizingInfos];
    [self updateItemsLayout];
}

- (void)getSizingInfos {
    NSAssert([_data.sections count] == 0, @"Grid layout is already populated?");

    id <BTRCollectionViewDelegateFlowLayout> flowDataSource = (id <BTRCollectionViewDelegateFlowLayout>)self.collectionView.delegate;

    BOOL implementsSizeDelegate = [flowDataSource respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)];
	BOOL implementsHeaderReferenceDelegate = [flowDataSource respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)];
	BOOL implementsFooterReferenceDelegate = [flowDataSource respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)];

    NSUInteger numberOfSections = [self.collectionView numberOfSections];
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        BTRGridLayoutSection *layoutSection = [_data addSection];
        layoutSection.verticalInterstice = _data.horizontal ? self.minimumInteritemSpacing : self.minimumLineSpacing;
        layoutSection.horizontalInterstice = !_data.horizontal ? self.minimumInteritemSpacing : self.minimumLineSpacing;

        if ([flowDataSource respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
            layoutSection.sectionMargins = [flowDataSource collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
        } else {
            layoutSection.sectionMargins = self.sectionInset;
        }

        if ([flowDataSource respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
            CGFloat minimumLineSpacing = [flowDataSource collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
            if (_data.horizontal) {
                layoutSection.horizontalInterstice = minimumLineSpacing;
            } else {
                layoutSection.verticalInterstice = minimumLineSpacing;
            }
        }

        if ([flowDataSource respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
            CGFloat minimumInterimSpacing = [flowDataSource collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
            if (_data.horizontal) {
                layoutSection.verticalInterstice = minimumInterimSpacing;
            } else {
                layoutSection.horizontalInterstice = minimumInterimSpacing;
            }
        }

		CGSize headerReferenceSize;
		if (implementsHeaderReferenceDelegate) {
			headerReferenceSize = [flowDataSource collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
		} else {
			headerReferenceSize = self.headerReferenceSize;
		}
		layoutSection.headerDimension = _data.horizontal ? headerReferenceSize.width : headerReferenceSize.height;

		CGSize footerReferenceSize;
		if (implementsFooterReferenceDelegate) {
			footerReferenceSize = [flowDataSource collectionView:self.collectionView layout:self referenceSizeForFooterInSection:section];
		} else {
			footerReferenceSize = self.footerReferenceSize;
		}
		layoutSection.footerDimension = _data.horizontal ? footerReferenceSize.width : footerReferenceSize.height;

        NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        if (implementsSizeDelegate) {
            for (NSUInteger item = 0; item < numberOfItems; item++) {
                NSIndexPath *indexPath = [NSIndexPath btr_indexPathForItem:item inSection:section];
                CGSize itemSize = implementsSizeDelegate ? [flowDataSource collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath] : self.itemSize;

                BTRGridLayoutItem *layoutItem = [layoutSection addItem];
                layoutItem.itemFrame = (CGRect){.size=itemSize};
            }
        }else {
            layoutSection.fixedItemSize = YES;
            layoutSection.itemSize = self.itemSize;
            layoutSection.itemsCount = numberOfItems;
        }
    }
}

- (void)updateItemsLayout {
    CGSize contentSize = CGSizeZero;
    for (BTRGridLayoutSection *section in _data.sections) {
        [section computeLayout];
        CGRect sectionFrame = section.frame;
        if (_data.horizontal) {
            sectionFrame.origin.x += contentSize.width;
            contentSize.width += section.frame.size.width + section.frame.origin.x;
            contentSize.height = fmaxf(contentSize.height, sectionFrame.size.height + section.frame.origin.y);
        }else {
            sectionFrame.origin.y += contentSize.height;
            contentSize.height += sectionFrame.size.height + section.frame.origin.y;
            contentSize.width = fmaxf(contentSize.width, sectionFrame.size.width + section.frame.origin.x);
        }
        section.frame = sectionFrame;
    }
    NSRect scrollViewBounds = self.collectionView.enclosingScrollView.bounds;
	if (_data.horizontal) {
		contentSize.width = MAX(contentSize.width, scrollViewBounds.size.width);
        contentSize.height = scrollViewBounds.size.height;
	} else {
        contentSize.width = scrollViewBounds.size.width;
		contentSize.height = MAX(contentSize.height, scrollViewBounds.size.height);
	}
    _data.contentSize = contentSize;
}

@end

@implementation BTRGridLayoutInfo {
    NSMutableArray *_sections;
    BOOL _isValid;
}

#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _sections = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p dimension:%.1f horizontal:%d contentSize:%@ sections:%@>", NSStringFromClass([self class]), self, self.dimension, self.horizontal, BTRNSStringFromCGSize(self.contentSize), self.sections];
}

#pragma mark - Public

- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath {
    BTRGridLayoutSection *section = self.sections[indexPath.section];
    CGRect itemFrame;
    if (section.fixedItemSize) {
        itemFrame = (CGRect){.size=section.itemSize};
    }else {
        itemFrame = [section.items[indexPath.item] itemFrame];
    }
    return itemFrame;
}

- (id)addSection {
    BTRGridLayoutSection *section = [BTRGridLayoutSection new];
    section.rowAlignmentOptions = self.rowAlignmentOptions;
    section.layoutInfo = self;
    [_sections addObject:section];
    [self invalidate:NO];
    return section;
}

- (void)invalidate:(BOOL)arg {
    _isValid = NO;
}

@end

@implementation BTRGridLayoutItem

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p itemFrame:%@>", NSStringFromClass([self class]), self, BTRNSStringFromCGRect(self.itemFrame)];
}

@end

@implementation BTRGridLayoutRow {
	NSMutableArray *_items;
    BOOL _isValid;
}

#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _items = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p frame:%@ index:%ld items:%@>", NSStringFromClass([self class]), self, BTRNSStringFromCGRect(self.rowFrame), self.index, self.items];
}

#pragma mark - Public

- (void)invalidate {
    _isValid = NO;
    _rowSize = CGSizeZero;
    _rowFrame = CGRectZero;
}

- (NSArray *)itemRects {
    return [self layoutRowAndGenerateRectArray:YES];
}

- (void)layoutRow {
    [self layoutRowAndGenerateRectArray:NO];
}

- (NSArray *)layoutRowAndGenerateRectArray:(BOOL)generateRectArray {
    NSMutableArray *rects = generateRectArray ? [NSMutableArray array] : nil;
    if (!_isValid || generateRectArray) {
        // Properties for alignment (not public in UICollectionView)
        BOOL isHorizontal = self.section.layoutInfo.horizontal;
        BOOL isLastRow = self.section.indexOfImcompleteRow == self.index;
        BTRFlowLayoutHorizontalAlignment horizontalAlignment = [self.section.rowAlignmentOptions[isLastRow ? BTRFlowLayoutLastRowHorizontalAlignmentKey : BTRFlowLayoutCommonRowHorizontalAlignmentKey] integerValue];
		
        // Calculate space that's left over if we would align it from left to right.
        CGFloat leftOverSpace = self.section.layoutInfo.dimension;
        if (isHorizontal) {
            leftOverSpace -= self.section.sectionMargins.top + self.section.sectionMargins.bottom;
        } else {
            leftOverSpace -= self.section.sectionMargins.left + self.section.sectionMargins.right;
        }
		
        // Calculate the space that we have left after counting all items.
        // UICollectionView is smart and lays out items like they would have been placed on a full row
        // So we need to calculate the "usedItemCount" with using the last item as a reference size.
        // This allows us to correctly justify-place the items in the grid.
        NSUInteger usedItemCount = 0;
        NSUInteger itemIndex = 0;
        CGFloat spacing = isHorizontal ? self.section.verticalInterstice : self.section.horizontalInterstice;
        // The last row should justify as if it is filled with more (invisible) items so that the whole
        // UICollectionView feels more like a grid than a random line of blocks
        while (itemIndex < self.itemCount || isLastRow) {
            CGFloat nextItemSize;
            // First we need to find the size (width/height) of the next item to fit
            if (!self.fixedItemSize) {
                BTRGridLayoutItem *item = self.items[MIN(itemIndex, self.itemCount - 1)];
                nextItemSize = isHorizontal ? item.itemFrame.size.height : item.itemFrame.size.width;
            } else {
                nextItemSize = isHorizontal ? self.section.itemSize.height : self.section.itemSize.width;
            }
            // The first item does not add a separator spacing,
            // Every one afterwards in the same row will need this spacing constant
            if (itemIndex > 0) {
                nextItemSize += spacing;
            }
            // Check to see if we can at least fit an item (+separator if necessary)
            if (leftOverSpace < nextItemSize) {
                break;
            }
            // We need to maintain the leftover space after the maximum amount of items have
            // occupied, so we know how to adjust equal spacing among all the items in a row
            leftOverSpace -= nextItemSize;
            
            itemIndex++;
            usedItemCount = itemIndex;
        }
        // Push everything to the right if right-aligning and divide in half for centered
        // Currently there is no public API supporting this behavior
        CGPoint itemOffset = CGPointZero;
        if (horizontalAlignment == BTRFlowLayoutHorizontalAlignmentRight) {
            itemOffset.x += leftOverSpace;
        } else if (horizontalAlignment == BTRFlowLayoutHorizontalAlignmentCentered ||
                 (horizontalAlignment == BTRFlowLayoutHorizontalAlignmentJustify && usedItemCount == 1)) {
            // Special case one item row to split leftover space in half
            itemOffset.x += leftOverSpace/2;
        }
        
        // Calculate the justified spacing among all items in a row if we are using
        // the default BTRFlowLayoutHorizontalAlignmentJustify layout
        CGFloat interSpacing = usedItemCount <= 1 ? 0 : leftOverSpace/(CGFloat)(usedItemCount-1);
		
        // Calculate row frame as union of all items
        CGRect frame = CGRectZero;
        CGRect itemFrame = (CGRect){.size=self.section.itemSize};
        for (itemIndex = 0; itemIndex < self.itemCount; itemIndex++) {
            BTRGridLayoutItem *item = nil;
            if (!self.fixedItemSize) {
                item = self.items[itemIndex];
                itemFrame = [item itemFrame];
            }
            // depending on horizontal/vertical for an item size (height/width),
            // we add the minimum separator then an equally distributed spacing
            // (since our default mode is justify) calculated from the total leftover
            // space divided by the number of intervals
            if (isHorizontal) {
                itemFrame.origin.y = itemOffset.y;
                itemOffset.y += itemFrame.size.height + self.section.verticalInterstice;
                if (horizontalAlignment == BTRFlowLayoutHorizontalAlignmentJustify) {
                    itemOffset.y += interSpacing;
                }
            }else {
                itemFrame.origin.x = itemOffset.x;
                itemOffset.x += itemFrame.size.width + self.section.horizontalInterstice;
                if (horizontalAlignment == BTRFlowLayoutHorizontalAlignmentJustify) {
                    itemOffset.x += interSpacing;
                }
            }
            item.itemFrame = CGRectIntegral(itemFrame); // might call nil; don't care
            [rects addObject:[NSValue btr_valueWithCGRect:CGRectIntegral(itemFrame)]];
            frame = CGRectUnion(frame, itemFrame);
        }
        _rowSize = frame.size;
        _isValid = YES;
    }
    return rects;
}

- (void)addItem:(BTRGridLayoutItem *)item {
    [_items addObject:item];
    item.rowObject = self;
    [self invalidate];
}

- (NSUInteger)itemCount {
    if (self.fixedItemSize)
        return _itemCount;
    else
        return [self.items count];
}

@end

@implementation BTRGridLayoutSection {
	NSMutableArray *_items;
    NSMutableArray *_rows;
    BOOL _isValid;
}

#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _items = [NSMutableArray new];
        _rows = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p itemCount:%ld frame:%@ rows:%@>", NSStringFromClass([self class]), self, self.itemsCount, BTRNSStringFromCGRect(self.frame), self.rows];
}

#pragma mark - Public

- (void)invalidate {
    _isValid = NO;
    self.rows = [NSMutableArray array];
}

- (void)computeLayout {
    if (!_isValid) {
        NSAssert([self.rows count] == 0, @"No rows shall be at this point.");
		
        // Iterate over all items, turning them into rows.
        CGSize sectionSize = CGSizeZero;
        NSUInteger rowIndex = 0;
        NSUInteger itemIndex = 0;
        NSUInteger itemsByRowCount = 0;
        CGFloat dimensionLeft = 0;
        BTRGridLayoutRow *row = nil;
        // Get dimension and compensate for section margin
		CGFloat headerFooterDimension = self.layoutInfo.dimension;
        CGFloat dimension = headerFooterDimension;
		
        if (self.layoutInfo.horizontal) {
            dimension -= self.sectionMargins.top + self.sectionMargins.bottom;
			self.headerFrame = CGRectMake(sectionSize.width, 0, self.headerDimension, headerFooterDimension);
			sectionSize.width += self.headerDimension + self.sectionMargins.left;
        }else {
            dimension -= self.sectionMargins.left + self.sectionMargins.right;
			self.headerFrame = CGRectMake(0, sectionSize.height, headerFooterDimension, self.headerDimension);
			sectionSize.height += self.headerDimension + self.sectionMargins.top;
        }
		
        float spacing = self.layoutInfo.horizontal ? self.verticalInterstice : self.horizontalInterstice;
        
        do {
            BOOL finishCycle = itemIndex >= self.itemsCount;
            // TODO: fast path could even remove row creation and just calculate on the fly
            BTRGridLayoutItem *item = nil;
            if (!finishCycle) item = self.fixedItemSize ? nil : self.items[itemIndex];
			
            CGSize itemSize = self.fixedItemSize ? self.itemSize : item.itemFrame.size;
            CGFloat itemDimension = self.layoutInfo.horizontal ? itemSize.height : itemSize.width;
            // First item of each row does not add spacing
            if (itemsByRowCount > 0) itemDimension += spacing;
            if (dimensionLeft < itemDimension || finishCycle) {
                if (row) {
                    // Compensate last row
                    self.itemsByRowCount = fmaxf(itemsByRowCount, self.itemsByRowCount);
                    row.itemCount = itemsByRowCount;
					
                    // If current row is done but there are still items left, increase the incomplete row counter
                    if (!finishCycle) self.indexOfImcompleteRow = rowIndex;
					
                    [row layoutRow];
					
                    if (self.layoutInfo.horizontal) {
                        row.rowFrame = CGRectMake(sectionSize.width, self.sectionMargins.top, row.rowSize.width, row.rowSize.height);
                        sectionSize.height = fmaxf(row.rowSize.height, sectionSize.height);
                        sectionSize.width += row.rowSize.width + (finishCycle ? 0 : self.horizontalInterstice);
                    }else {
                        row.rowFrame = CGRectMake(self.sectionMargins.left, sectionSize.height, row.rowSize.width, row.rowSize.height);
                        sectionSize.height += row.rowSize.height + (finishCycle ? 0 : self.verticalInterstice);
                        sectionSize.width = fmaxf(row.rowSize.width, sectionSize.width);
                    }
                }
                // Add new rows until the section is fully layouted
                if (!finishCycle) {
                    // Create new row
                    row.complete = YES;
                    row = [self addRow];
                    row.fixedItemSize = self.fixedItemSize;
                    row.index = rowIndex;
                    self.indexOfImcompleteRow = rowIndex;
                    rowIndex++;
                    // Convert an item from previous row to current, remove spacing for first item
                    if (itemsByRowCount > 0) itemDimension -= spacing;
                    dimensionLeft = dimension - itemDimension;
                    itemsByRowCount = 0;
                }
            } else {
                dimensionLeft -= itemDimension;
            }
			
            // Add item on slow path
            if (item) [row addItem:item];
			
            itemIndex++;
            itemsByRowCount++;
        } while (itemIndex <= self.itemsCount); // Cycle once more to finish last row
		
        if (self.layoutInfo.horizontal) {
			sectionSize.width += self.sectionMargins.right;
			self.footerFrame = CGRectMake(sectionSize.width, 0, self.footerDimension, headerFooterDimension);
			sectionSize.width += self.footerDimension;
        }else {
			sectionSize.height += self.sectionMargins.bottom;
			self.footerFrame = CGRectMake(0, sectionSize.height, headerFooterDimension, self.footerDimension);
			sectionSize.height += self.footerDimension;
        }
		
        _frame = CGRectMake(0, 0, sectionSize.width, sectionSize.height);
        _isValid = YES;
    }
}

- (void)recomputeFromIndex:(NSInteger)index {
    // TODO: use index.
    [self invalidate];
    [self computeLayout];
}

- (BTRGridLayoutItem *)addItem {
    BTRGridLayoutItem *item = [BTRGridLayoutItem new];
    item.section = self;
    [_items addObject:item];
    return item;
}

- (BTRGridLayoutRow *)addRow {
    BTRGridLayoutRow *row = [BTRGridLayoutRow new];
    row.section = self;
    [_rows addObject:row];
    return row;
}

- (NSUInteger)itemsCount {
    return self.fixedItemSize ? _itemsCount : [self.items count];
}

@end

