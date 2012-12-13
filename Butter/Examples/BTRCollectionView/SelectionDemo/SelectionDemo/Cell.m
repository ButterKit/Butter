//
//  Cell.m
//  SelectionDemo
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "Cell.h"

@implementation Cell

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
	
	[self addSubview:self.label];
    
    return self;
}

- (NSTextField *)label {
	if (!_label) {
		_label = [[NSTextField alloc] initWithFrame:self.bounds];
		[_label setBezeled:NO];
		[_label setDrawsBackground:NO];
		[_label setEditable:NO];
		[_label setAlignment:NSCenterTextAlignment];
		[_label setSelectable:NO];
	}
	return _label;
}

@end
