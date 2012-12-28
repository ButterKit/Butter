//
//  BTRTextField.h
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// BTRTextField should *not* be layer backed in Interface Builder
// This leads to a bug that causes an additional shadow to be shown
// underneath the field
@interface BTRTextField : NSTextField

@end
