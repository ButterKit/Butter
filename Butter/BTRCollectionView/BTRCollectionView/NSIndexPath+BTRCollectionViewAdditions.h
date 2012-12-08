//
//  NSIndexPath+BTRCollectionViewAdditions.h
//  BasicExample
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <Foundation/Foundation.h>

// Additions to NSIndexPath to support convenience constructors for item/section indexes

@interface NSIndexPath (BTRCollectionViewAdditions)
+ (NSIndexPath *)indexPathForItem:(NSInteger)item inSection:(NSInteger)section;
- (NSInteger)item;
- (NSInteger)section;
@end
