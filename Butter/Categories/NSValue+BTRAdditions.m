//
//  NSValue+BTRAdditions.m
//  BasicExample
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "NSValue+BTRAdditions.h"

@implementation NSValue (BTRAdditions)
+ (NSValue *)btr_valueWithCGRect:(CGRect)rect
{
    return [self valueWithRect:rect];
}

- (CGRect)btr_CGRectValue
{
    return NSRectToCGRect([self rectValue]);
}

+ (NSValue *)btr_valueWithCGSize:(CGSize)size
{
    return [self valueWithSize:size];
}

+ (NSValue *)btr_valueWithCGPoint:(CGPoint)point
{
    return [self valueWithPoint:point];
}

- (CGSize)btr_CGSizeValue
{
    return [self sizeValue];
}

- (CGPoint)btr_CGPointValue
{
    return [self pointValue];
}
@end
