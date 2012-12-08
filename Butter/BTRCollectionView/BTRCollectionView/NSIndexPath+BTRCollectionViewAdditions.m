//
//  NSIndexPath+BTRCollectionViewAdditions.m
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "NSIndexPath+BTRCollectionViewAdditions.h"

@implementation NSIndexPath (BTRCollectionViewAdditions)
+ (NSIndexPath *)indexPathForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSUInteger indexes[2] = {section, item};
    return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

- (NSInteger)item
{
    return [self indexAtPosition:1];
}

- (NSInteger)section
{
    return [self indexAtPosition:0];
}
@end
