//
//  BTRSecureTextField.h
//  Butter
//
//  Created by Indragie Karunaratne on 2012-12-28.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BTRTextFieldProtocol.h"

// The secure variant of BTRTextField. See BTRTextField header for more information.
@interface BTRSecureTextField : NSSecureTextField <BTRTextField>
@end

// Subclassing hooks for a BTRSecureTextField
@interface BTRSecureTextField (SubclassingHooks)

- (void)drawBackgroundInRect:(NSRect)rect;
- (NSRect)drawingRectForProposedDrawingRect:(NSRect)rect;
- (NSRect)editingRectForProposedEditingRect:(NSRect)rect;
- (void)setFieldEditorAttributes:(NSTextView *)fieldEditor;

@end

