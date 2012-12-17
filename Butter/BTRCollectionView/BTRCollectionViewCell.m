//
//  BTRCollectionViewCell.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import "BTRCollectionView.h"
#import "BTRCollectionViewCell.h"
#import "BTRCollectionViewLayout.h"

@interface BTRCollectionReusableView() {
    BTRCollectionViewLayoutAttributes *_layoutAttributes;
    NSString *_reuseIdentifier;
    __unsafe_unretained BTRCollectionView *_collectionView;
    struct {
        unsigned int inUpdateAnimation : 1;
    } _reusableViewFlags;
}
@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, unsafe_unretained) BTRCollectionView *collectionView;
@property (nonatomic, strong) BTRCollectionViewLayoutAttributes *layoutAttributes;
@end

@implementation BTRCollectionReusableView

#pragma mark - NSObject

- (void)awakeFromNib {
    self.reuseIdentifier = [self valueForKeyPath:@"reuseIdentifier"];
}

#pragma mark - Public

- (void)prepareForReuse {
    self.layoutAttributes = nil;
}

- (void)applyLayoutAttributes:(BTRCollectionViewLayoutAttributes *)layoutAttributes {
    if (layoutAttributes != _layoutAttributes) {
        _layoutAttributes = layoutAttributes;
        self.frame = layoutAttributes.frame;
        self.alphaValue = layoutAttributes.alpha;
        self.hidden = layoutAttributes.isHidden;
        self.layer.transform = layoutAttributes.transform3D;
        self.layer.zPosition = layoutAttributes.zIndex;
        // TODO more attributes
    }
}

- (void)willTransitionFromLayout:(BTRCollectionViewLayout *)oldLayout toLayout:(BTRCollectionViewLayout *)newLayout {
    _reusableViewFlags.inUpdateAnimation = YES;
}

- (void)didTransitionFromLayout:(BTRCollectionViewLayout *)oldLayout toLayout:(BTRCollectionViewLayout *)newLayout {
    _reusableViewFlags.inUpdateAnimation = NO;
}

- (BOOL)isInUpdateAnimation {
    return _reusableViewFlags.inUpdateAnimation;
}

- (void)setInUpdateAnimation:(BOOL)inUpdateAnimation {
    _reusableViewFlags.inUpdateAnimation = inUpdateAnimation;
}

@end


@implementation BTRCollectionViewCell {
    BTRView *_contentView;
    NSView *_backgroundView;
    NSView *_selectedBackgroundView;
    id _selectionSegueTemplate;
    id _highlightingSupport;
    struct {
        unsigned int selected : 1;
        unsigned int highlighted : 1;
        unsigned int showingMenu : 1;
        unsigned int clearSelectionWhenMenuDisappears : 1;
        unsigned int waitingForSelectionAnimationHalfwayPoint : 1;
    } _collectionCellFlags;
    BOOL _selected;
    BOOL _highlighted;
}

#pragma mark - NSObject

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _backgroundView = [[BTRView alloc] initWithFrame:self.bounds];
        _backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:_backgroundView];

        _contentView = [[BTRView alloc] initWithFrame:self.bounds];
        _contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:_contentView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        if ([[self subviews] count] > 0) {
            _contentView = [self subviews][0];
        } else {
            _contentView = [[BTRView alloc] initWithFrame:self.bounds];
            _contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
            [self addSubview:_contentView];
        }
        
        _backgroundView = [[BTRView alloc] initWithFrame:self.bounds];
        _backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:_backgroundView positioned:NSWindowBelow relativeTo:_contentView];
    }
    return self;
}

#pragma mark - Public

- (void)prepareForReuse {
    self.layoutAttributes = nil;
    self.selected = NO;
    self.highlighted = NO;
}

- (void)setSelected:(BOOL)selected {
    if (_collectionCellFlags.selected != selected) {
        _collectionCellFlags.selected = selected;
        [self updateBackgroundView];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_collectionCellFlags.highlighted != highlighted) {
        _collectionCellFlags.highlighted = highlighted;
        [self updateBackgroundView];
    }
}

- (void)updateBackgroundView {
    BOOL shouldHighlight = (self.highlighted || self.selected);
    _selectedBackgroundView.alphaValue = shouldHighlight ? 1.0f : 0.0f;
    [self setHighlighted:shouldHighlight forViews:self.contentView.subviews];
}

- (void)setHighlighted:(BOOL)highlighted forViews:(id)subviews {
    for (id view in subviews) {
        if ([view respondsToSelector:@selector(setHighlighted:)]) {
            [view setHighlighted:highlighted];
        }
        [self setHighlighted:highlighted forViews:[view subviews]];
    }
}

- (void)setBackgroundView:(NSView *)backgroundView {
    if (_backgroundView != backgroundView) {
        [_backgroundView removeFromSuperview];
        _backgroundView = backgroundView;
        _backgroundView.frame = self.bounds;
        _backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:_backgroundView positioned:NSWindowBelow relativeTo:nil];
    }
}

- (void)setSelectedBackgroundView:(NSView *)selectedBackgroundView {
    if (_selectedBackgroundView != selectedBackgroundView) {
        [_selectedBackgroundView removeFromSuperview];
        _selectedBackgroundView = selectedBackgroundView;
        _selectedBackgroundView.frame = self.bounds;
        _selectedBackgroundView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
        _selectedBackgroundView.alphaValue = self.selected ? 1.0f : 0.0f;
        if (_backgroundView) {
            [self addSubview:_selectedBackgroundView positioned:NSWindowAbove relativeTo:_backgroundView];
        } else {
            [self addSubview:_selectedBackgroundView positioned:NSWindowBelow relativeTo:nil];
        }
    }
}

- (BOOL)isSelected {
    return _collectionCellFlags.selected;
}

- (BOOL)isHighlighted {
    return _collectionCellFlags.highlighted;
}
@end
