//
//  HeaderView.m
//  FlowLayoutNoNIB
//
//  Created by Beau G. Bolle on 2012.10.29.
//
//

#import "HeaderView.h"

@implementation HeaderView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.wantsLayer = YES;
		self.layer.backgroundColor = [NSColor greenColor].CGColor;
	}
	return self;
}

@end
