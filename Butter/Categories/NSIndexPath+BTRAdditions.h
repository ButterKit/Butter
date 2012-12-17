//
//  NSIndexPath+BTRAdditions.h
//  BasicExample
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Additions to NSIndexPath to add support for row/item and section indexes */

@interface NSIndexPath (BTRAdditions)
/**
 Returns an index-path object initialized with the indexes of a specific item and section in a collection view.
 @param item An index number identifying an item in a UICollectionView object in a section identified by the section parameter.
 @param section An index number identifying a section in a UICollectionView object.
 @return An NSIndexPath object or nil if the object could not be created.
 */
+ (NSIndexPath *)btr_indexPathForItem:(NSUInteger)item inSection:(NSUInteger)section;

/**
 Returns an index-path object initialized with the indexes of a specific row and section in a table view.
 @param row An index number identifying a row in a UITableView object in a section identified by section.
 @param section An index number identifying a section in a UITableView object.
 @return An NSIndexPath object or nil if the object could not be created.
 */
+ (NSIndexPath *)btr_indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section;

/**
 An index number identifying an item in a section of a collection view. (read-only)
 @discussion The section the item is in is identified by the value of section.
 */
@property (nonatomic, assign, readonly) NSUInteger item;

/**
 An index number identifying a row in a section of a table view. (read-only)
 @discussion The section the row is in is identified by the value of section.
 */
@property (nonatomic, assign, readonly) NSUInteger row;

/**
 An index number identifying a section in a table view or collection view. (read-only)
 */
@property (nonatomic, assign, readonly) NSUInteger section;
@end
