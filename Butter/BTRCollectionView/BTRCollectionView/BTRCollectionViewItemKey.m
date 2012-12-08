//
//  BTRCollectionViewItemKey.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRCollectionViewItemKey.h"
#import "BTRCollectionViewLayout.h"

NSString *const BTRCollectionElementKindCell = @"BTRCollectionElementKindCell";
NSString *const BTRCollectionElementKindDecorationView = @"BTRCollectionElementKindDecorationView";

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

NSString *BTRCollectionViewItemTypeToString(BTRCollectionViewItemType type) {
    switch (type) {
        case BTRCollectionViewItemTypeCell: return @"Cell";
        case BTRCollectionViewItemTypeDecorationView: return @"Decoration";
        case BTRCollectionViewItemTypeSupplementaryView: return @"Supplementary";
        default: return @"<INVALID>";
    }
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
