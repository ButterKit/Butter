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

const CGFloat decelerationRate = 0.88;

@interface BTRClipView()
@property (nonatomic) CVDisplayLinkRef displayLink;
@property (nonatomic) BOOL animate;
@property (nonatomic) CGPoint destination;
@property (nonatomic, readonly, getter = isScrolling) BOOL scrolling;
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

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (self.window) {
		[nc removeObserver:self name:NSWindowDidChangeScreenNotification object:self.window];
	}
	[super viewWillMoveToWindow:newWindow];
	if (newWindow) {
		[nc addObserverForName:NSWindowDidChangeScreenNotification object:newWindow queue:nil usingBlock:^(NSNotification *note) {
			[self updateCVDisplay];
		}];
	}
}

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;

	self.layer = [CAScrollLayer layer];
	self.wantsLayer = YES;

	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;

	// Matches default NSClipView settings.
	self.backgroundColor = NSColor.clearColor;
	self.opaque = NO;

	return self;
}

- (void)dealloc {
	CVDisplayLinkRelease(_displayLink);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Scrolling

- (void)scrollToPoint:(NSPoint)newOrigin {	
	if (self.animate) {
		self.destination = newOrigin;
		if (!self.isScrolling) {
			[self beginScrolling];
		}
	} else {
		if (self.isScrolling) {
			[self endScrolling];
		}
		[super scrollToPoint:newOrigin];
	}
}

- (BOOL)scrollRectToVisible:(NSRect)aRect animated:(BOOL)animated {
	self.animate = animated;
	return [super scrollRectToVisible:aRect];
}

- (void)beginScrolling {
	CVDisplayLinkStart(self.displayLink);
}

- (void)endScrolling {
	CVDisplayLinkStop(self.displayLink);
	self.animate = NO;
}

- (BOOL)isScrolling {
	return CVDisplayLinkIsRunning(self.displayLink);
}

- (CVReturn)updateOrigin {
	if(self.window == nil) {
		[self endScrolling];
		return kCVReturnError;
	}
	
	CGPoint o = self.bounds.origin;
	CGPoint lastOrigin = o;
	o.x = o.x * decelerationRate + self.destination.x * (1-decelerationRate);
	o.y = o.y * decelerationRate + self.destination.y * (1-decelerationRate);
	
	[self setBoundsOrigin:o];
	
	if((fabsf(o.x - lastOrigin.x) < 0.1) && (fabsf(o.y - lastOrigin.y) < 0.1)) {
		[self endScrolling];
		[self setBoundsOrigin:self.destination];
		[(NSScrollView *)self.superview flashScrollers];
	}
	
	return kCVReturnSuccess;
}

- (void)updateCVDisplay
{
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
