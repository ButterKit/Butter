//
//  BTRCollectionViewListLayout.m
//  Butter
//
//  Created by Jonathan Willing and Indragie Karunaratne.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRCollectionViewListLayout.h"
#import "BTRCollectionView.h"

@interface BTRListSection : NSObject
@property (nonatomic, strong) NSArray *rows;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGRect headerFrame;
@property (nonatomic, assign) CGRect footerFrame;
@end

@interface BTRListRow : NSObject
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSUInteger index;
@end

@implementation BTRCollectionViewListLayout {
	NSArray *_sections;
	CGSize _contentsSize;
}

- (id)init {
	if ((self = [super init])) {
		_rowHeight = 30.f;
	}
	return self;
}

#pragma mark - UICollectionViewLayout

- (void)prepareLayout
{
	[self recomputeLayout];
}

- (CGSize)collectionViewContentSize {
	return _contentsSize;
}

- (void)invalidateLayout {
    _sections = nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSMutableArray *attributes = [NSMutableArray array];
	[_sections enumerateObjectsUsingBlock:^(BTRListSection *section, NSUInteger idx, BOOL *stop) {
		if (CGRectIntersectsRect(section.frame, rect)) {
			if (!CGRectIsEmpty(section.headerFrame) && CGRectIntersectsRect(section.headerFrame, rect)) {
				BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BTRCollectionElementKindSectionHeader withIndexPath:[NSIndexPath btr_indexPathForItem:0 inSection:section.index]];
				layoutAttributes.frame = section.headerFrame;
				[attributes addObject:layoutAttributes];
			}
			[section.rows enumerateObjectsUsingBlock:^(BTRListRow *row, NSUInteger idx, BOOL *stop) {
				if (CGRectIntersectsRect(row.frame, rect)) {
					BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath btr_indexPathForItem:row.index inSection:section.index]];
					layoutAttributes.frame = row.frame;
					[attributes addObject:layoutAttributes];
				}
			}];
			if (!CGRectIsEmpty(section.footerFrame) && CGRectIntersectsRect(section.footerFrame, rect)) {
				BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BTRCollectionElementKindSectionFooter withIndexPath:[NSIndexPath btr_indexPathForItem:0 inSection:section.index]];
				layoutAttributes.frame = section.footerFrame;
				[attributes addObject:layoutAttributes];
			}
		}
	}];
	return attributes;
}

- (BTRCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	BTRListSection *section = _sections[indexPath.section];
	BTRListRow *row = section.rows[indexPath.item];
	BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	layoutAttributes.frame = row.frame;
	return layoutAttributes;
}

- (BTRCollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
	BTRListSection *section = _sections[indexPath.section];
	if ([kind isEqualToString:BTRCollectionElementKindSectionHeader]) {
		BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BTRCollectionElementKindSectionHeader withIndexPath:indexPath];
		layoutAttributes.frame = section.headerFrame;
		return layoutAttributes;
	} else if ([kind isEqualToString:BTRCollectionElementKindSectionFooter]) {
		BTRCollectionViewLayoutAttributes *layoutAttributes = [BTRCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BTRCollectionElementKindSectionFooter withIndexPath:indexPath];
		layoutAttributes.frame = section.footerFrame;
		return layoutAttributes;
	}
	return nil;
}

#pragma mark - Recompute Layout

- (void)recomputeLayout {
	id<BTRCollectionViewDelegateListLayout> delegate = (id<BTRCollectionViewDelegateListLayout>)self.collectionView.delegate;
	BOOL implementsRowHeightDelegate = [delegate respondsToSelector:@selector(collectionView:layout:heightForRowAtIndexPath:)];
	BOOL implementsHeaderHeightDelegate = [delegate respondsToSelector:@selector(collectionView:layout:referenceHeightForHeaderInSection:)];
	BOOL implementsFooterHeightDelegate = [delegate respondsToSelector:@selector(collectionView:layout:referenceHeightForFooterInSection:)];
	
	NSUInteger numberOfSections = [self.collectionView numberOfSections];
	NSMutableArray *sections = [NSMutableArray arrayWithCapacity:numberOfSections];
	
	CGSize collectionViewContentSize = CGSizeMake(CGRectGetWidth([self.collectionView.enclosingScrollView bounds]), 0.f);
	
	CGRect lastSectionFrame = CGRectZero;
	for (NSUInteger section = 0; section < numberOfSections; section++) {
		BTRListSection *listSection = [BTRListSection new];
		listSection.index = section;
		
		CGFloat headerHeight = self.headerReferenceHeight;
		if (implementsHeaderHeightDelegate) {
			headerHeight = [delegate collectionView:self.collectionView
									   layout:self referenceHeightForHeaderInSection:section];
		}
		CGSize sectionSize = CGSizeMake(collectionViewContentSize.width, 0.f);
		CGPoint sectionOrigin = CGPointMake(CGRectGetMinX(lastSectionFrame), CGRectGetMaxY(lastSectionFrame));
		CGPoint currentOrigin = sectionOrigin;
		
		listSection.headerFrame = (CGRect){.origin = sectionOrigin, .size=CGSizeMake(sectionSize.width, headerHeight)};
		currentOrigin.y += headerHeight;
		
		NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
		NSMutableArray *rows = [NSMutableArray arrayWithCapacity:numberOfItems];
		for (NSUInteger item = 0; item < numberOfItems; item++) {
			CGFloat rowHeight = self.rowHeight;
			if (implementsRowHeightDelegate) {
				NSIndexPath *indexPath = [NSIndexPath btr_indexPathForItem:item inSection:section];
				rowHeight = [delegate collectionView:self.collectionView layout:self heightForRowAtIndexPath:indexPath];
			}
			
			BTRListRow *row = [BTRListRow new];
			row.index = item;
			row.frame = (CGRect){.origin = currentOrigin, .size = CGSizeMake(sectionSize.width, rowHeight)};
			
			currentOrigin.y += rowHeight;
			[rows addObject:row];
		}
		listSection.rows = rows;
		
		CGFloat footerHeight = self.footerReferenceHeight;
		if (implementsFooterHeightDelegate) {
			footerHeight = [delegate collectionView:self.collectionView layout:self referenceHeightForFooterInSection:section];
		}
		listSection.footerFrame = (CGRect){.origin = currentOrigin, .size = CGSizeMake(sectionSize.width, footerHeight)};
		currentOrigin.y += footerHeight;
		sectionSize.height = currentOrigin.y - sectionOrigin.y;
		collectionViewContentSize.height += sectionSize.height;
		
		listSection.frame = (CGRect){.origin = sectionOrigin, .size = sectionSize};
		lastSectionFrame = listSection.frame;
		[sections addObject:listSection];
	}
	_sections = sections;
	_contentsSize = collectionViewContentSize;
}

@end

@implementation BTRListRow
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p frame:%@>", NSStringFromClass([self class]),self, NSStringFromRect(self.frame)];
}
@end

@implementation BTRListSection
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p frame:%@ headerFrame:%@ footerFrame:%@ rows:\n%@\n>", NSStringFromClass([self class]), self, NSStringFromRect(self.frame), NSStringFromRect(self.headerFrame), NSStringFromRect(self.footerFrame), self.rows];
}
@end
