//
//  BTRClipView.m
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-14.
//  Modified by Jonathan Willing
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "BTRClipView.h"

const CGFloat decelerationRate = 0.87;

@interface BTRClipView()
@property (nonatomic) CVDisplayLinkRef displayLink;
@property (nonatomic) BOOL animate;
@property (nonatomic) CGPoint destination;
@property (nonatomic, readonly, getter = isScrolling) BOOL scrolling;
@end

@implementation BTRClipView

#pragma mark Properties

@dynamic layer;

- (NSColor *)backgroundColor {
	return [NSColor colorWithCGColor:self.layer.backgroundColor];
}

- (void)setBackgroundColor:(NSColor *)color {
	self.layer.backgroundColor = color.CGColor;
}

- (BOOL)isOpaque {
	return self.layer.opaque;
}

- (void)setOpaque:(BOOL)opaque {
	self.layer.opaque = opaque;
}

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

#pragma mark - NSObject

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
}

#pragma mark Scrolling

- (void)scrollToPoint:(NSPoint)newOrigin {
	if (self.isScrolling) {
		[self endScrolling];
	}
	
	if (self.animate) {
		self.destination = newOrigin;
		[self beginScrolling];
	} else {
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
