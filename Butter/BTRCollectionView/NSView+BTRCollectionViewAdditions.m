//
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSView+BTRCollectionViewAdditions.h"

@implementation NSView (BTRCollectionViewAdditions)


- (void)btr_scrollRectToVisible:(NSRect)rect animated:(BOOL)animated
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	
	// TODO: This will not be a smooth animation.
	if (animated)
		[clipView.animator scrollRectToVisible:rect];
	else
		[clipView scrollRectToVisible:rect];
}

@end
