//
//  BTRCollectionViewCommon.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BTRCollectionView, BTRCollectionViewCell, BTRCollectionReusableView;

@protocol BTRCollectionViewDataSource <NSObject>
@required

- (NSInteger)collectionView:(BTRCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (BTRCollectionViewCell *)collectionView:(BTRCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSInteger)numberOfSectionsInCollectionView:(BTRCollectionView *)collectionView;

// The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
- (BTRCollectionReusableView *)collectionView:(BTRCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

@end

@protocol BTRCollectionViewDelegate <NSObject>
@optional

// Methods for notification of selection/deselection and highlight/unhighlight events.
// The sequence of calls leading to selection from a user touch is:
//
// (when the touch begins)
// 1. -collectionView:shouldHighlightItemAtIndexPath:
// 2. -collectionView:didHighlightItemAtIndexPath:
//
// (when the touch lifts)
// 3. -collectionView:shouldSelectItemAtIndexPath: or -collectionView:shouldDeselectItemAtIndexPath:
// 4. -collectionView:didSelectItemAtIndexPath: or -collectionView:didDeselectItemAtIndexPath:
// 5. -collectionView:didUnhighlightItemAtIndexPath:
- (BOOL)collectionView:(BTRCollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(BTRCollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(BTRCollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(BTRCollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(BTRCollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath; // called when the user taps on an already-selected item in multi-select mode
- (void)collectionView:(BTRCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(BTRCollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(BTRCollectionView *)collectionView didEndDisplayingCell:(BTRCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(BTRCollectionView *)collectionView didEndDisplayingSupplementaryView:(BTRCollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath;

// These methods provide support for copy/paste actions on cells.
// All three should be implemented if any are.
- (BOOL)collectionView:(BTRCollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(BTRCollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender;
- (void)collectionView:(BTRCollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender;

@end

#define PSBlockImplCast (__bridge void *)
