//
//  BTRGridLayoutItem.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRGridLayoutItem.h"
#import "BTRGeometryAdditions.h"

@implementation BTRGridLayoutItem

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p itemFrame:%@>", NSStringFromClass([self class]), self, BTRNSStringFromCGRect(self.itemFrame)];
}

@end
