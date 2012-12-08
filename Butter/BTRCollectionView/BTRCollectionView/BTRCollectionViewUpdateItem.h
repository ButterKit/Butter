//
//  BTRCollectionViewUpdateItem.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BTRCollectionUpdateAction) {
    BTRCollectionUpdateActionInsert,
    BTRCollectionUpdateActionDelete,
    BTRCollectionUpdateActionReload,
    BTRCollectionUpdateActionMove,
    BTRCollectionUpdateActionNone
};

@interface BTRCollectionViewUpdateItem : NSObject

@property (nonatomic, readonly, strong) NSIndexPath *indexPathBeforeUpdate; // nil for BTRCollectionUpdateActionInsert
@property (nonatomic, readonly, strong) NSIndexPath *indexPathAfterUpdate;  // nil for BTRCollectionUpdateActionDelete
@property (nonatomic, readonly, assign) BTRCollectionUpdateAction updateAction;


- (id)initWithInitialIndexPath:(NSIndexPath*)arg1
                finalIndexPath:(NSIndexPath*)arg2
                  updateAction:(BTRCollectionUpdateAction)arg3;

- (id)initWithAction:(BTRCollectionUpdateAction)arg1
        forIndexPath:(NSIndexPath*)indexPath;

- (id)initWithOldIndexPath:(NSIndexPath*)arg1 newIndexPath:(NSIndexPath*)arg2;

- (BTRCollectionUpdateAction)updateAction;

- (NSComparisonResult)compareIndexPaths:(BTRCollectionViewUpdateItem*) otherItem;
- (NSComparisonResult)inverseCompareIndexPaths:(BTRCollectionViewUpdateItem*) otherItem;

@end
