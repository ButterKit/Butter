//
//  NSValue+BTRAdditions.h
//  BasicExample
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <Foundation/Foundation.h>

// Additions to support boxing CG data types in NSValue
@interface NSValue (BTRAdditions)
+ (NSValue *)btr_valueWithCGRect:(CGRect)rect;
+ (NSValue *)btr_valueWithCGSize:(CGSize)size;
+ (NSValue *)btr_valueWithCGPoint:(CGPoint)point;
- (CGRect)btr_CGRectValue;
- (CGSize)btr_CGSizeValue;
- (CGPoint)btr_CGPointValue;
@end
