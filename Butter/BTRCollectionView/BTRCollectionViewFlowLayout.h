//
//  UICollectionViewFlowLayout.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRCollectionViewLayout.h"
#import "BTRGeometryAdditions.h"
#import "BTRCollectionViewCommon.h"

typedef NS_ENUM(NSInteger, BTRCollectionViewScrollDirection) {
    BTRCollectionViewScrollDirectionVertical,
    BTRCollectionViewScrollDirectionHorizontal
};

@protocol BTRCollectionViewDelegateFlowLayout <BTRCollectionViewDelegate>
@optional
- (CGSize)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSEdgeInsets)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSUInteger)section;
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSUInteger)section;
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSUInteger)section;
- (CGSize)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSUInteger)section;
- (CGSize)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSUInteger)section;
@end

@class BTRGridLayoutInfo;

@interface BTRCollectionViewFlowLayout : BTRCollectionViewLayout

@property (nonatomic) CGFloat minimumLineSpacing;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGSize itemSize; // for the cases the delegate method is not implemented
@property (nonatomic) BTRCollectionViewScrollDirection scrollDirection; // default is BTRCollectionViewScrollDirectionVertical
@property (nonatomic) CGSize headerReferenceSize;
@property (nonatomic) CGSize footerReferenceSize;

@property (nonatomic) NSEdgeInsets sectionInset;
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