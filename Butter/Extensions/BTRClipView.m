//
//  BTRClipView.m
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-14.
//  Modified by Jonathan Willing
//  Deceleration logic originally from TwUI
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "BTRClipView.h"
#import "BTRCommon.h"

// The deceleration constant used for the ease-out curve in the animation.
const CGFloat BTRClipViewDecelerationRate = 0.78;

@interface BTRClipView()
@property (nonatomic) CVDisplayLinkRef displayLink;
@property (nonatomic) BOOL animate;
@property (nonatomic) CGPoint destination;
@property (nonatomic, readonly, getter = isScrolling) BOOL scrolling;
@property (nonatomic, strong) id notificationObserver;
@end

@implementation BTRClipView

#pragma mark Properties

@dynamic layer;

BTRVIEW_ADDITIONS_IMPLEMENTATION();

- (CVDisplayLinkRef)displayLink {
	if (_displayLink == NULL) {
		CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
		CVDisplayLinkSetOutputCallback(_displayLink, &BTRScrollingCallback, (__bridge void *)(self));
		[self updateCVDisplay];
	}
	return _displayLink;
}

#pragma mark - NSView

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (self.window && self.notificationObserver) {
		[nc removeObserver:self.notificationObserver];
		self.notificationObserver = nil;
	}
	[super viewWillMoveToWindow:newWindow];
	if (newWindow) {
		self.notificationObserver = [nc addObserverForName:NSWindowDidChangeScreenNotification object:newWindow queue:nil usingBlock:^(NSNotification *note) {
			[self updateCVDisplay];
		}];
	}
}

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;

	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;

	// Matches default NSClipView settings.
	self.backgroundColor = NSColor.clearColor;
	self.opaque = NO;
	
	self.decelerationRate = BTRClipViewDecelerationRate;

	return self;
}

- (void)dealloc {
	CVDisplayLinkRelease(_displayLink);
	if (self.notificationObserver) {
		[NSNotificationCenter.defaultCenter removeObserver:self.notificationObserver];
	}
}

#pragma mark Scrolling

- (void)scrollToPoint:(NSPoint)newOrigin {
	if (self.animate && (self.window.currentEvent.type != NSScrollWheel)) {
		self.destination = newOrigin;
		[self beginScrolling];
	} else {
		[self endScrolling];
		[super scrollToPoint:newOrigin];
	}
}

- (void)setDestination:(CGPoint)destination {
	// We want to round up to the nearest integral point, since some classes
	// have a bad habit of providing non-integral point values.
	_destination = (CGPoint){ .x = roundf(destination.x), .y = roundf(destination.y) };
}

- (BOOL)scrollRectToVisible:(NSRect)aRect animated:(BOOL)animated {
	self.animate = animated;
	return [super scrollRectToVisible:aRect];
}

- (void)beginScrolling {
	if (self.isScrolling)
		return;

	CVDisplayLinkStart(self.displayLink);
}

- (void)endScrolling {
	if (!self.isScrolling)
		return;
	
	CVDisplayLinkStop(self.displayLink);
	self.animate = NO;
}

- (BOOL)isScrolling {
	return CVDisplayLinkIsRunning(self.displayLink);
}

// Sanitize the deceleration rate to [0, 1] so nothing unexpected happens.
- (void)setDecelerationRate:(CGFloat)decelerationRate {
	if (decelerationRate > 1)
		decelerationRate = 1;
	else if (decelerationRate < 0)
		decelerationRate = 0;
	_decelerationRate = decelerationRate;
}

- (CVReturn)updateOrigin {
	if(self.window == nil) {
		[self endScrolling];
		return kCVReturnError;
	}
	
	CGPoint o = self.bounds.origin;
	CGPoint lastOrigin = o;
	o.x = o.x * self.decelerationRate + self.destination.x * (1 - self.decelerationRate);
	o.y = o.y * self.decelerationRate + self.destination.y * (1 - self.decelerationRate);
	
	[self setBoundsOrigin:o];
	
	if((fabsf(o.x - lastOrigin.x) < 0.1) && (fabsf(o.y - lastOrigin.y) < 0.1)) {
		[self endScrolling];
		[self setBoundsOrigin:self.destination];
		[(NSScrollView *)self.superview flashScrollers];
	}
	
	return kCVReturnSuccess;
}

- (void)updateCVDisplay {
	NSScreen *screen = self.window.screen;
	if (screen) {
		NSDictionary* screenDictionary = [[NSScreen mainScreen] deviceDescription];
		NSNumber *screenID = [screenDictionary objectForKey:@"NSScreenNumber"];
		CGDirectDisplayID displayID = [screenID unsignedIntValue];
		CVDisplayLinkSetCurrentCGDisplay(_displayLink, displayID);
	} else {
		CVDisplayLinkSetCurrentCGDisplay(_displayLink, kCGDirectMainDisplay);
	}
}

static CVReturn BTRScrollingCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext) {
	__block CVReturn status;
	@autoreleasepool {
		BTRClipView *clipView = (__bridge id)displayLinkContext;
		dispatch_async(dispatch_get_main_queue(), ^{
			status = [clipView updateOrigin];
		});
	}
    return status;
}
@end
