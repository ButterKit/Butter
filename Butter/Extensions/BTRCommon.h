//
//  BTRCommon.h
//  Butter
//
//  Created by Indragie Karunaratne on 2012-12-13.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#define BTRVIEW_ADDITIONS_IMPLEMENTATION() \
- (NSColor *)backgroundColor \
{ \
	return [NSColor colorWithCGColor:self.layer.backgroundColor]; \
} \
 \
- (void)setBackgroundColor:(NSColor *)color \
{ \
	self.layer.backgroundColor = color.CGColor; \
} \
 \
- (CGFloat)cornerRadius \
{ \
	return self.layer.cornerRadius; \
} \
 \
- (void)setCornerRadius:(CGFloat)radius \
{ \
	self.layer.cornerRadius = radius; \
} \
 \
- (BOOL)masksToBounds \
{ \
	return self.layer.masksToBounds; \
} \
 \
- (void)setMasksToBounds:(BOOL)masksToBounds \
{ \
	self.layer.masksToBounds = masksToBounds; \
} \
 \
- (BOOL)isOpaque \
{ \
	return self.layer.opaque; \
} \
\
- (void)setOpaque:(BOOL)opaque \
{ \
	self.layer.opaque = opaque; \
}
