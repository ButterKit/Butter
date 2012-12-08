//
//  BTRCollectionViewItemKey.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRCollectionViewCommon.h"
#import "BTRCollectionViewLayout.h"

extern NSString *const BTRCollectionElementKindCell;
extern NSString *const BTRCollectionElementKindDecorationView;
@class BTRCollectionViewLayoutAttributes;

NSString *BTRCollectionViewItemTypeToString(BTRCollectionViewItemType type); // debug helper

// Used in NSDictionaries
@interface BTRCollectionViewItemKey : NSObject <NSCopying>

+ (id)collectionItemKeyForLayoutAttributes:(BTRCollectionViewLayoutAttributes *)layoutAttributes;
+ (id)collectionItemKeyForDecorationViewOfKind:(NSString *)elementKind andIndexPath:(NSIndexPath *)indexPath;
+ (id)collectionItemKeyForSupplementaryViewOfKind:(NSString *)elementKind andIndexPath:(NSIndexPath *)indexPath;
+ (id)collectionItemKeyForCellWithIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic, assign) BTRCollectionViewItemType type;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSString *identifier;

@end
