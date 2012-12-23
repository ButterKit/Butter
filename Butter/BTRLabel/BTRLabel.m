//
//  BTRLabel.m
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRLabel.h"

@implementation BTRLabel

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;
	
	self.bezeled = NO;
	self.editable = NO;
	self.alignment = NSCenterTextAlignment;
	self.selectable = NO;
	self.drawsBackground = NO;

	return self;
}

@end
