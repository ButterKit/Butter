//
//  NSIndexPath+BTRAdditions.m
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "NSIndexPath+BTRAdditions.h"

@implementation NSIndexPath (BTRAdditions)
+ (NSIndexPath *)btr_indexPathForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSUInteger indexes[2] = {section, item};
    return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

+ (NSIndexPath *)btr_indexPathForRow:(NSInteger)row inSection:(NSInteger)section
{
	return [self btr_indexPathForItem:row inSection:section];
}

- (NSInteger)item
{
    return [self indexAtPosition:1];
}

- (NSInteger)row
{
	return self.item;
}

- (NSInteger)section
{
    return [self indexAtPosition:0];
}
@end
