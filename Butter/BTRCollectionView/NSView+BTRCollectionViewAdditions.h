//
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Better block-based animation and animator proxies.
@interface NSView (BTRCollectionViewAdditions)

- (void)btr_scrollRectToVisible:(NSRect)rect animated:(BOOL)animated;

@end
