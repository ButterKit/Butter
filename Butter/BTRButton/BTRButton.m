//
//  BTRButton.m
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRButton.h"
#import "BTRLabel.h"
#import "BTRImageView.h"

@interface BTRButtonContent : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSImage *backgroundImage;
@end
@implementation BTRButtonContent
@end

@interface BTRButton()
@property (nonatomic, strong) NSMutableDictionary *content;

@property (nonatomic, strong) BTRLabel *titleLabel;
@property (nonatomic, strong) BTRImageView *backgroundImageView;

- (void)updateState;
@end

@implementation BTRButton

- (BTRButtonContent *)contentForControlState:(BTRControlState)state {
	BTRButtonContent *content = self.content[@(state)];
	if (!content) {
		content = [BTRButtonContent new];
		self.content[@(state)] = content;
	}
	return content;
}

- (NSMutableDictionary *)content {
	if (!_content) {
		_content = @{}.mutableCopy;
	}
	return _content;
}

#pragma mark Background Images

- (NSImage *)backgroundImageForControlState:(BTRControlState)state {
	return [self contentForControlState:state].backgroundImage;
}

- (void)setBackgroundImage:(NSImage *)image forControlState:(BTRControlState)state {
	[self contentForControlState:state].backgroundImage = image;
	[self updateState];
}

- (BTRImageView *)backgroundImageView {
	if (!_backgroundImageView) {
		_backgroundImageView = [[BTRImageView alloc] initWithFrame:self.bounds];
		[self addSubview:_backgroundImageView];
	}
	return _backgroundImageView;
}


#pragma mark Titles

- (NSString *)titleForControlState:(BTRControlState)state {
	return [self contentForControlState:state].title;
}

- (void)setTitle:(NSString *)title forControlState:(BTRControlState)state {
	[self contentForControlState:state].title = title;
	[self updateState];
}

- (BTRLabel *)titleLabel {
	if (!_titleLabel) {
		_titleLabel = [[BTRLabel alloc] initWithFrame:self.bounds];
		[self addSubview:_titleLabel positioned:NSWindowAbove relativeTo:self.backgroundImageView];
	}
	return _titleLabel;
}


#pragma mark State

- (void)handleStateChange {
	[self updateState];
}

- (void)updateState {
	NSString *title = [self titleForControlState:self.state];
	self.titleLabel.stringValue = (title != nil) ? title : @"";
	
	NSImage *backgroundImage = [self backgroundImageForControlState:self.state];
	self.backgroundImageView.image = (backgroundImage != nil) ? backgroundImage : [self defaultBackgroundImageForControlState:self.state];
}


#pragma mark Drawing

- (BOOL)wantsUpdateLayer {
	return YES;
}

- (void)updateLayer {
	[super updateLayer];
	
	self.backgroundImageView.frame = self.bounds;
	self.titleLabel.frame = self.bounds;
}

// TODO: Ideally we'll have a good default style that can be drawn here.
- (NSImage *)defaultBackgroundImageForControlState:(BTRControlState)state {
	return [NSImage imageWithSize:self.bounds.size flipped:NO drawingHandler:^BOOL(NSRect rect) {
		
		if (state == BTRControlStateNormal) {
			[NSColor.redColor set];
		} else if (state & BTRControlStateHighlighted) {
			[NSColor.blueColor set];
		}
		
		NSRectFill(rect);
		
		return YES;
	}];
}

@end
