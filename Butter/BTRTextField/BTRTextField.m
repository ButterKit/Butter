//
//  BTRTextField.m
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRTextField.h"

@implementation BTRTextField

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;
	self.wantsLayer = YES;
	return self;
}

// It appears that on some layer-backed view heirarchies that are
// set up before the window has a chance to be shown, the text fields
// aren't set up properly. This temporarily alleviates this problem.
//
// TODO: Investigate this more.
- (void)viewDidMoveToWindow {
	[self setNeedsDisplay:YES];
}

@end
