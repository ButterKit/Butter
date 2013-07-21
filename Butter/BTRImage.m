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
	NSImage *originalImage = [self imageNamed:name];
	if (originalImage.representations) {
		BTRImage *image = [[BTRImage alloc] initWithSize:originalImage.size];
		[image addRepresentations:originalImage.representations];
		image.capInsets = insets;
		return image;
	} else {
		return nil;
	}
}

@end
