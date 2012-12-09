//
//  UICollectionViewFlowLayout.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRCollectionViewLayout.h"
#import "BTRGeometryAdditions.h"
#import "BTRCollectionViewCommon.h"

extern NSString *const BTRCollectionElementKindSectionHeader;
extern NSString *const BTRCollectionElementKindSectionFooter;

typedef NS_ENUM(NSInteger, BTRCollectionViewScrollDirection) {
    BTRCollectionViewScrollDirectionVertical,
    BTRCollectionViewScrollDirectionHorizontal
};

@protocol BTRCollectionViewDelegateFlowLayout <BTRCollectionViewDelegate>
@optional

- (CGSize)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (BTREdgeInsets)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section;
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;
- (CGSize)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
- (CGSize)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;

@end

@class BTRGridLayoutInfo;

@interface BTRCollectionViewFlowLayout : BTRCollectionViewLayout

@property (nonatomic) CGFloat minimumLineSpacing;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGSize itemSize; // for the cases the delegate method is not implemented
@property (nonatomic) BTRCollectionViewScrollDirection scrollDirection; // default is BTRCollectionViewScrollDirectionVertical
@property (nonatomic) CGSize headerReferenceSize;
@property (nonatomic) CGSize footerReferenceSize;

@property (nonatomic) BTREdgeInsets sectionInset;

/*
 Row alignment options exits in the official UICollectionView, but hasn't been made public API.
 
 Here's a snippet to test this on UICollectionView:

 NSMutableDictionary *rowAlign = [[flowLayout valueForKey:@"_rowAlignmentsOptionsDictionary"] mutableCopy];
 rowAlign[@"UIFlowLayoutCommonRowHorizontalAlignmentKey"] = @(1);
 rowAlign[@"UIFlowLayoutLastRowHorizontalAlignmentKey"] = @(3);
 [flowLayout setValue:rowAlign forKey:@"_rowAlignmentsOptionsDictionary"];
 */
@property (nonatomic, strong) NSDictionary *rowAlignmentOptions;

@end

// @steipete addition, private API in UICollectionViewFlowLayout
extern NSString *const BTRFlowLayoutCommonRowHorizontalAlignmentKey;
extern NSString *const BTRFlowLayoutLastRowHorizontalAlignmentKey;
extern NSString *const BTRFlowLayoutRowVerticalAlignmentKey;

typedef NS_ENUM(NSInteger, BTRFlowLayoutHorizontalAlignment) {
    BTRFlowLayoutHorizontalAlignmentLeft,
    BTRFlowLayoutHorizontalAlignmentCentered,
    BTRFlowLayoutHorizontalAlignmentRight,
    BTRFlowLayoutHorizontalAlignmentJustify // 3; default except for the last row
};
// TODO: settings for UIFlowLayoutRowVerticalAlignmentKey


/*
@interface BTRCollectionViewFlowLayout (Private)

- (CGSize)synchronizeLayout;

// For items being inserted or deleted, the collection view calls some different methods, which you should override to provide the appropriate layout information.
- (BTRCollectionViewLayoutAttributes *)initialLayoutAttributesForFooterInInsertedSection:(NSInteger)section;
- (BTRCollectionViewLayoutAttributes *)initialLayoutAttributesForHeaderInInsertedSection:(NSInteger)section;
- (BTRCollectionViewLayoutAttributes *)initialLayoutAttributesForInsertedItemAtIndexPath:(NSIndexPath *)indexPath;
- (BTRCollectionViewLayoutAttributes *)finalLayoutAttributesForFooterInDeletedSection:(NSInteger)section;
- (BTRCollectionViewLayoutAttributes *)finalLayoutAttributesForHeaderInDeletedSection:(NSInteger)section;
- (BTRCollectionViewLayoutAttributes *)finalLayoutAttributesForDeletedItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)_updateItemsLayout;
- (void)_getSizingInfos;
- (void)_updateDelegateFlags;

- (BTRCollectionViewLayoutAttributes *)layoutAttributesForFooterInSection:(NSInteger)section;
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForHeaderInSection:(NSInteger)section;
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath usingData:(id)data;
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForFooterInSection:(NSInteger)section usingData:(id)data;
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForHeaderInSection:(NSInteger)section usingData:(id)data;

- (id)indexesForSectionFootersInRect:(CGRect)rect;
- (id)indexesForSectionHeadersInRect:(CGRect)rect;
- (id)indexPathsForItemsInRect:(CGRect)rect usingData:(id)arg2;
- (id)indexesForSectionFootersInRect:(CGRect)rect usingData:(id)arg2;
- (id)indexesForSectionHeadersInRect:(CGRect)arg1 usingData:(id)arg2;
- (CGRect)_frameForItemAtSection:(int)arg1 andRow:(int)arg2 usingData:(id)arg3;
- (CGRect)_frameForFooterInSection:(int)arg1 usingData:(id)arg2;
- (CGRect)_frameForHeaderInSection:(int)arg1 usingData:(id)arg2;
- (void)_invalidateLayout;
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)arg1;
- (BTRCollectionViewLayoutAttributes *)_layoutAttributesForItemsInRect:(CGRect)arg1;
- (CGSize)collectionViewContentSize;
- (void)finalizeCollectionViewUpdates;
- (BTRCollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
- (void)_invalidateButKeepDelegateInfo;
- (void)_invalidateButKeepAllInfo;
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)arg1;
- (id)layoutAttributesForElementsInRect:(CGRect)arg1;
- (void)invalidateLayout;
- (id)layoutAttributesForItemAtIndexPath:(id)arg1;

@end
*/

// Represents a single grid item; only created for non-uniform-sized grids.
@class BTRGridLayoutItem, BTRGridLayoutRow, BTRGridLayoutSection;
@interface BTRGridLayoutRow : NSObject

@property (nonatomic, unsafe_unretained) BTRGridLayoutSection *section;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, assign) CGSize rowSize;
@property (nonatomic, assign) CGRect rowFrame;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) BOOL complete;
@property (nonatomic, assign) BOOL fixedItemSize;

// @steipete addition for row-fastPath
@property (nonatomic, assign) NSInteger itemCount;

//- (BTRGridLayoutRow *)copyFromSection:(BTRGridLayoutSection *)section; // ???

// Add new item to items array.
- (void)addItem:(BTRGridLayoutItem *)item;

// Layout current row (if invalid)
- (void)layoutRow;

// @steipete: Helper to save code in BTRCollectionViewFlowLayout.
// Returns the item rects when fixedItemSize is enabled.
- (NSArray *)itemRects;

//  Set current row frame invalid.
- (void)invalidate;

// Copy a snapshot of the current row data
- (BTRGridLayoutRow *)snapshot;

@end

@interface BTRGridLayoutSection : NSObject

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *rows;

// fast path for equal-size items
@property (nonatomic, assign) BOOL fixedItemSize;
@property (nonatomic, assign) CGSize itemSize;
// depending on fixedItemSize, this either is a _ivar or queries items.
@property (nonatomic, assign) NSInteger itemsCount;

@property (nonatomic, assign) CGFloat verticalInterstice;
@property (nonatomic, assign) CGFloat horizontalInterstice;
@property (nonatomic, assign) BTREdgeInsets sectionMargins;

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
@property (nonatomic, assign) NSInteger itemsByRowCount;
@property (nonatomic, assign) NSInteger indexOfImcompleteRow; // typo as of iOS6B3

//- (BTRGridLayoutSection *)copyFromLayoutInfo:(BTRGridLayoutInfo *)layoutInfo;

// Faster variant of invalidate/compute
- (void)recomputeFromIndex:(NSInteger)index;

// Invalidate layout. Destroys rows.
- (void)invalidate;

// Compute layout. Creates rows.
- (void)computeLayout;

- (BTRGridLayoutItem *)addItem;
- (BTRGridLayoutRow *)addRow;

// Copy snapshot of current object
- (BTRGridLayoutSection *)snapshot;

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

// Make a copy of the current state.
- (BTRGridLayoutInfo *)snapshot;

@end