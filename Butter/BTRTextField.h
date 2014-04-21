//
//  BTRTextField.h
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BTRTextFieldProtocol.h"

// BTRTextField is a powerful subclass of NSTextField that adds support
// for image-based customization and modifications of default drawing,
// plus control event additions.
//
// BTRTextField should _not_ be layer backed in Interface Builder.
// There is an Interface Builder bug that leads to an issue which causes
// an additional shadow to be shown underneath the textfield.
@interface BTRTextField : NSTextField <BTRTextField>
@end

// Subclassing hooks for a BTRTextField
@interface BTRTextField (SubclassingHooks)

- (void)drawBackgroundInRect:(NSRect)rect;
- (NSRect)drawingRectForProposedDrawingRect:(NSRect)rect;
- (NSRect)editingRectForProposedEditingRect:(NSRect)rect;
- (void)setFieldEditorAttributes:(NSTextView *)fieldEditor;

@end
