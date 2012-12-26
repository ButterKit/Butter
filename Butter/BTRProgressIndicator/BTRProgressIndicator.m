//
//  BTRProgressIndicator.m
//  Butter
//
//  Created by Jonathan Willing on 12/25/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRProgressIndicator.h"

static const CGFloat BTRProgressIndicatorDefaultFrameLength = 14.f;

@implementation BTRProgressIndicator

- (id)initWithFrame:(NSRect)frame {
	return [self initWithFrame:frame activityIndicatorStyle:BTRActivityIndicatorStyleGray];
}

- (id)initWithActivityIndicatorStyle:(BTRActivityIndicatorStyle)style {
	CGFloat length = BTRProgressIndicatorDefaultFrameLength;
	return [self initWithFrame:CGRectMake(0, 0, length, length) activityIndicatorStyle:style];
}

- (id)initWithFrame:(NSRect)frame activityIndicatorStyle:(BTRActivityIndicatorStyle)style {
	self = [super initWithFrame:frame layerHosted:YES];
	if (self == nil) return nil;
	_activityIndicatorStyle = style;
	_hidesWhenStopped = YES;
	
	return self;
}

- (void)startAnimating {
	
}

- (void)stopAnimating {
	
}

@end
