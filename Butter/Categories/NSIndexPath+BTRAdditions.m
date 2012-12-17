//
//  NSIndexPath+BTRAdditions.m
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "NSIndexPath+BTRAdditions.h"

@implementation NSIndexPath (BTRAdditions)
+ (NSIndexPath *)btr_indexPathForItem:(NSUInteger)item inSection:(NSUInteger)section
{
    NSUInteger indexes[2] = {section, item};
    return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

+ (NSIndexPath *)btr_indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section
{
	return [self btr_indexPathForItem:row inSection:section];
}

- (NSUInteger)item
{
    return [self indexAtPosition:1];
}

- (NSUInteger)row
{
	return self.item;
}

- (NSUInteger)section
{
    return [self indexAtPosition:0];
}
@end
