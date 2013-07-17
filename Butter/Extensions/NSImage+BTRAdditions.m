//
//  NSImage+BTRAdditions.m
//  Butter
//
//  Created by Jonathan Willing on 7/16/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import "NSImage+BTRAdditions.h"
#import <objc/runtime.h>

static void *BTRNSImageCapInsetsAssociatedObjectKey = &BTRNSImageCapInsetsAssociatedObjectKey;

@implementation NSImage (BTRAdditions)

- (void)setBtr_capInsets:(NSEdgeInsets)insets {
	// There's no built-in boxing of NSEdgeInsets => NSValue, so we'll do it manually.
	NSValue *wrappedInsets = [NSValue value:&insets withObjCType:@encode(NSEdgeInsets)];
	objc_setAssociatedObject(self, BTRNSImageCapInsetsAssociatedObjectKey, wrappedInsets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSEdgeInsets)btr_capInsets {
	NSValue *insetsValue = [self btr_capInsetsValue];
	
	NSEdgeInsets insets;
	[insetsValue getValue:&insetsValue];
	
	return insets;
}

- (NSValue *)btr_capInsetsValue {
	return objc_getAssociatedObject(self, BTRNSImageCapInsetsAssociatedObjectKey);
}

@end
