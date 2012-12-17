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
- (BTREdgeInsets)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSUInteger)section;
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSUInteger)section;
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSUInteger)section;
- (CGSize)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSUInteger)section;
- (CGSize)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSUInteger)section;

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

// @steipete addition for row-fastPath
@property (nonatomic, assign) NSUInteger itemCount;

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
@property (nonatomic, assign) NSUInteger itemsCount;

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
@property (nonatomic, assign) NSUInteger itemsByRowCount;
@property (nonatomic, assign) NSUInteger indexOfImcompleteRow; // typo as of iOS6B3

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