//
//  BTRCollectionViewUpdateItem.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRCollectionViewUpdateItem.h"
#import "NSIndexPath+BTRCollectionViewAdditions.h"

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
