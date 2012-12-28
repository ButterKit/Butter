//
//  BTRSecureTextField.h
//  Butter
//
//  Created by Indragie Karunaratne on 2012-12-28.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// BTRSecureTextField should *not* be layer backed in Interface Builder
// This leads to a bug that causes an additional shadow to be shown
// underneath the field
@interface BTRSecureTextField : NSSecureTextField

@end
