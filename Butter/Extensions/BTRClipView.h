//
//  BTRClipView.h
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-14.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

// A faster NSClipView based on CAScrollLayer.
//
// This view should be set as the scroll view's contentView as soon as possible
// after the scroll view is initialized. For some reason, scroll bars will
// disappear on 10.7 (but not 10.8) unless hasHorizontalScroller and
// hasVerticalScroller are set _after_ the contentView.
@interface BTRClipView : NSClipView

// The backing layer for this view.
@property (nonatomic, strong) CAScrollLayer *layer;

// Whether the content in this view is opaque.
//
// Defaults to NO.
@property (nonatomic, getter = isOpaque) BOOL opaque;

// Calls -scrollRectToVisible:, optionally animated.
- (BOOL)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;

// Any time the origin changes with an animation as discussed above, the deceleration
// rate will be used to create an ease-out animation.
//
// Values should range from [0, 1]. Smaller deceleration rates will provide
// generally fast animations, whereas larger rates will create lengthy animations.
//
//Defaults to 0.78.
@property (nonatomic, assign) CGFloat decelerationRate;

@end
