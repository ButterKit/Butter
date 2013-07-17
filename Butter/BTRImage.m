//
//  BTRImage.m
//  Butter
//
//  Created by Jonathan Willing on 7/16/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import "BTRImage.h"

@implementation BTRImage

+ (instancetype)resizableImageNamed:(NSString *)name withCapInsets:(NSEdgeInsets)insets {
	BTRImage *image = [[self imageNamed:name] copy];
	image.capInsets = insets;
	return image;
}

- (instancetype)resizableImageWithCapInsets:(NSEdgeInsets)insets {
	BTRImage *image = [self copy];
	image.capInsets = insets;
	return image;
}

@end
