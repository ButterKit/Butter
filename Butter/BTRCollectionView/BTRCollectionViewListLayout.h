//
//  BTRCollectionViewListLayout.h
//  Butter
//
//  Created by Jonathan Willing and Indragie Karunaratne.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRCollectionViewLayout.h"
#import "BTRCollectionViewCommon.h"

@protocol BTRCollectionViewDelegateListLayout <BTRCollectionViewDelegate>
@optional
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)layout heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)layout referenceHeightForHeaderInSection:(NSUInteger)section;
- (CGFloat)collectionView:(BTRCollectionView *)collectionView layout:(BTRCollectionViewLayout *)layout referenceHeightForFooterInSection:(NSUInteger)section;
@end

@interface BTRCollectionViewListLayout : BTRCollectionViewLayout
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) CGFloat headerReferenceHeight;
@property (nonatomic, assign) CGFloat footerReferenceHeight;
@end
