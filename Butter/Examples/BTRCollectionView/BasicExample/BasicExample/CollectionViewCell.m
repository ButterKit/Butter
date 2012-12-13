//
//  CollectionViewCell.m
//  FlowLayoutNoNIB
//
//  Created by Beau G. Bolle on 2012.10.29.
//	Modified by Jonathan Willing on 2012.12.7
//

#import "CollectionViewCell.h"

@interface CollectionViewCell()
@property (nonatomic, strong) NSTextField *titleLabel;
@end

@implementation CollectionViewCell

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [NSColor yellowColor];
		self.contentView.opaque = YES;
		[self addSubview:self.titleLabel];
	}
	return self;
}

- (void)setTitle:(NSString *)title {
	self.titleLabel.stringValue = title;
}

- (NSTextField *)titleLabel {
	if (!_titleLabel) {
		_titleLabel = [[NSTextField alloc] initWithFrame:(CGRect){ .size = CGSizeMake(self.bounds.size.width, 20) }];
		[_titleLabel setBezeled:NO];
		[_titleLabel setDrawsBackground:NO];
		[_titleLabel setEditable:NO];
		[_titleLabel setSelectable:NO];
	}
	return _titleLabel;
}

@end
