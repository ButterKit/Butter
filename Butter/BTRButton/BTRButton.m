//
//  BTRButton.m
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRButton.h"
#import "BTRLabel.h"

@interface BTRButtonContent : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSAttributedString *attributedTitle;
@property (nonatomic, strong) NSColor *titleColor;
@property (nonatomic, strong) NSShadow *titleShadow;
@property (nonatomic, strong) NSFont *titleFont;
@property (nonatomic, strong) NSImage *backgroundImage;
@end
@implementation BTRButtonContent {
	NSMutableAttributedString *_attributedTitle;
}
@synthesize attributedTitle = _attributedTitle;

- (NSString *)title {
	return [self.attributedTitle string];
}

- (void)setTitle:(NSString *)title {
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	style.alignment = NSCenterTextAlignment;
	style.lineBreakMode = NSLineBreakByTruncatingTail;
	NSMutableDictionary *attributes = @{NSParagraphStyleAttributeName: style}.mutableCopy;
	if (self.titleColor) attributes[NSForegroundColorAttributeName] = self.titleColor;
	if (self.titleShadow) attributes[NSShadowAttributeName] = self.titleShadow;
	self.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{NSParagraphStyleAttributeName : style}];
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle {
	_attributedTitle = [attributedTitle mutableCopy];
}

- (void)setTitleColor:(NSColor *)titleColor {
	if (titleColor) {
		[_attributedTitle addAttribute:NSForegroundColorAttributeName value:titleColor range:[self entireStringRange]];
	} else {
		[_attributedTitle removeAttribute:NSForegroundColorAttributeName range:[self entireStringRange]];
	}
	_titleColor = titleColor;
}

- (void)setTitleShadow:(NSShadow *)titleShadow {
	if (titleShadow) {
		[_attributedTitle addAttribute:NSShadowAttributeName value:titleShadow range:[self entireStringRange]];
	} else {
		[_attributedTitle removeAttribute:NSShadowAttributeName range:[self entireStringRange]];
	}
	_titleShadow = titleShadow;
}

- (void)setTitleFont:(NSFont *)titleFont {
	if (titleFont) {
		[_attributedTitle addAttribute:NSFontAttributeName value:titleFont range:[self entireStringRange]];
	} else {
		[_attributedTitle removeAttribute:NSFontAttributeName range:[self entireStringRange]];
	}
	_titleFont = titleFont;
}

- (NSRange)entireStringRange {
	return NSMakeRange(0, [_attributedTitle length]);
}
@end

@interface BTRButton()
@property (nonatomic, strong) NSMutableDictionary *content;
@property (nonatomic, strong, readwrite) BTRLabel *titleLabel;
@property (nonatomic, strong, readwrite) BTRImageView *imageView;
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

- (BTRImageView *)imageView {
	if (!_imageView) {
		_imageView = [[BTRImageView alloc] initWithFrame:self.bounds];
		[self addSubview:_imageView];
	}
	return _imageView;
}

#pragma mark Titles

- (NSString *)titleForControlState:(BTRControlState)state {
	return [self contentForControlState:state].title;
}

- (void)setTitle:(NSString *)title forControlState:(BTRControlState)state {
	[self contentForControlState:state].title = title;
	[self updateState];
}

- (NSAttributedString *)attributedTitleForState:(BTRControlState)state {
	return [self contentForControlState:state].attributedTitle;
}

- (void)setAttributedTitle:(NSAttributedString *)title forState:(BTRControlState)state {
	[self contentForControlState:state].attributedTitle = title;
	[self updateState];
}

- (NSColor *)titleColorForState:(BTRControlState)state {
	return [self contentForControlState:state].titleColor;
}

- (void)setTitleColor:(NSColor *)color forState:(BTRControlState)state {
	[self contentForControlState:state].titleColor = color;
	[self updateState];
}

- (NSShadow *)titleShadowForState:(BTRControlState)state {
	return [self contentForControlState:state].titleShadow;
}

- (void)setTitleShadow:(NSShadow *)shadow forState:(BTRControlState)state {
	[self contentForControlState:state].titleShadow = shadow;
	[self updateState];
}

- (NSFont *)titleFontForState:(BTRControlState)state {
	return [self contentForControlState:state].titleFont;
}

- (void)setTitleFont:(NSFont *)font forState:(BTRControlState)state
{
	[self contentForControlState:state].titleFont = font;
	[self updateState];
}

- (NSString *)currentTitle {
	return [self contentForControlState:self.state].title;
}

- (NSAttributedString *)currentAttributedTitle {
	return [self contentForControlState:self.state].attributedTitle;
}

- (NSImage *)currentBackgroundImage {
	return [self contentForControlState:self.state].backgroundImage;
}

- (NSColor *)currentTitleColor {
	return [self contentForControlState:self.state].titleColor;
}

- (NSShadow *)currentTitleShadow {
	return [self contentForControlState:self.state].titleShadow;
}

- (NSFont *)currentTitleFont {
	return [self contentForControlState:self.state].titleFont;
}

- (BTRLabel *)titleLabel {
	if (!_titleLabel) {
		_titleLabel = [[BTRLabel alloc] initWithFrame:self.bounds];
		[self addSubview:_titleLabel positioned:NSWindowAbove relativeTo:self.imageView];
	}
	return _titleLabel;
}

#pragma mark State

- (void)handleStateChange {
	[self updateState];
}

- (void)updateState {
	NSString *title = [self titleForControlState:self.state];
	self.titleLabel.stringValue = title?: @"";
	
	NSImage *backgroundImage = [self backgroundImageForControlState:self.state];
	if (backgroundImage == nil) {
		// If we can't find a control state for the current state, we to the normal control state image.
		// If the normal state image can't be found, revert back to the default image for the current state.
		backgroundImage = ([self backgroundImageForControlState:BTRControlStateNormal] ?: [self defaultBackgroundImageForControlState:self.state]);
	}
	self.imageView.image = backgroundImage;
}


#pragma mark Drawing

//- (BOOL)wantsUpdateLayer {
//	return YES;
//}
//
//- (void)updateLayer {
//	[super updateLayer];
//}

- (void)layout {
	[super layout];
	self.imageView.frame = self.bounds;
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

// When a button is clicked, the initial state change shouldn't animate
// or it will appear to be laggy. However, if the user has opted to animate
// the contents, we animate the transition back out.
- (void)setHighlighted:(BOOL)highlighted {
	self.imageView.animatesContents = (!highlighted && self.animatesContents);
	[super setHighlighted:highlighted];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
	self.imageView.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
	return self.imageView.cornerRadius;
}


#pragma mark Content mode

- (void)setContentMode:(BTRViewContentMode)contentMode {
	self.imageView.contentMode = contentMode;
}

- (BTRViewContentMode)contentMode {
	return self.imageView.contentMode;
}

@end
