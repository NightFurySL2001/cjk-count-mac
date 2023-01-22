/* 
 *  InfoRow.m
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import "InfoRow.h"
#import "Utils.h"


@implementation InfoRow {
    NSTextField *_titleLabel;
    NSTextField *_valueLabel;
    NSLevelIndicator *_indicator;
    NSButton *_infoButton;

    CGFloat _fittingHeight;

    NSTrackingArea *_inBoundsTrackingArea;
}

static NSColor *backgroundRedColor = nil;
static NSColor *backgroundYellowColor = nil;
static NSColor *backgroundGreenColor = nil;
static NSImage *infoButtonImage = nil;

+ (void)initialize {
    if (self == [InfoRow class]) {
        backgroundRedColor = [NSColor colorNamed:@"BackgroundRed"];
        backgroundYellowColor = [NSColor colorNamed:@"BackgroundYellow"];
        backgroundGreenColor = [NSColor colorNamed:@"BackgroundGreen"];

        if (@available(macOS 10.16, *)) {
            infoButtonImage = [NSImage imageWithSystemSymbolName:@"info.circle" accessibilityDescription:nil];
            [infoButtonImage setSize:NSMakeSize(30, 30)];
        } else {
            infoButtonImage = [NSImage imageNamed:@"Info"];
        }
    }
}

- (instancetype)initWithValue:(NSInteger)value maxValue:(NSInteger)maxValue title:(NSString *)title {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        _value = value;
        _maxValue = maxValue;
        _warningFraction = 0.7;
        _criticalFraction = 0.4;

        _titleLabel = [NSTextField labelWithString:@""];
        _valueLabel = [NSTextField labelWithString:@""];
        _indicator = [[NSLevelIndicator alloc] init];
        _infoButton = [NSButton buttonWithImage:infoButtonImage target:self action:@selector(popMessage:)];

        [_titleLabel setAllowsExpansionToolTips:YES];

        [self setSubviews:@[_titleLabel, _indicator, _valueLabel, _infoButton]];
        [self setTitle:title];
        [self syncValue];
        [self initializeLayout];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    return [self initWithValue:0 maxValue:0 title:@""];
}

- (void)setValue:(NSInteger)value {
    _value = value;
    [self syncValue];
}

- (void)setMaxValue:(NSInteger)maxValue {
    _maxValue = maxValue;
    [self syncValue];
}

- (NSString *)title {
    return [_titleLabel stringValue];
}

- (void)setTitle:(NSString *)title {
    [_titleLabel setStringValue:title];
    [self setNeedsDisplay:YES];
}

- (void)setWarningFraction:(double)warningFraction {
    _warningFraction = warningFraction;
    [self updateColor];
}

- (void)setCriticalFraction:(double)criticalFraction {
    _criticalFraction = criticalFraction;
    [self updateColor];
}

- (void)setMessage:(NSAttributedString *)message {
    _message = message;
    [self updateTrackingAreas];
    [self setNeedsLayout:YES];
}

- (void)updateColor {
    double valueFraction = (double)_value / (double)_maxValue;
    if (valueFraction > _warningFraction) {
        CGFloat blendFraction = (valueFraction - _warningFraction) / (1 - _warningFraction);
        [_indicator setFillColor:[backgroundYellowColor blendedColorWithFraction:blendFraction ofColor:backgroundGreenColor]];
    } else {
        CGFloat blendFraction = (valueFraction - _criticalFraction) / (_warningFraction - _criticalFraction);
        [_indicator setFillColor:[backgroundRedColor blendedColorWithFraction:blendFraction ofColor:backgroundYellowColor]];
    }
}

- (void)syncValue {
    [_indicator setDoubleValue:_value];
    [_indicator setMaxValue:_maxValue];
    [_valueLabel setStringValue:[NSString stringWithFormat:@"%ld ⁄ %ld", _value, _maxValue]];
    [_valueLabel sizeToFit];
    [self updateColor];
    [self setNeedsLayout:YES];
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    [self updateColor];
}

static CGFloat const indicatorWidth = 96;
static CGFloat const controlSpacing = 4;
static CGFloat const popoverContentWidth = 384;
static NSSize const popoverPadding = {20, 16};

- (NSEdgeInsets)alignmentRectInsets {
    return NSEdgeInsetsMake(0, [_titleLabel alignmentRectInsets].left,
                            0, [_indicator alignmentRectInsets].right);
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize([_titleLabel intrinsicContentSize].width
                    + [_titleLabel alignmentRectInsets].right
                    + indicatorWidth + controlSpacing * 2, _fittingHeight);
}

- (void)initializeLayout {
    [_titleLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];

    [_valueLabel setControlSize:NSControlSizeSmall];
    [_valueLabel setFont:[NSFont monospacedDigitSystemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightRegular]];

    [_indicator setLevelIndicatorStyle:NSLevelIndicatorStyleContinuousCapacity];
    [_indicator setFrameSize:NSMakeSize(indicatorWidth, [_indicator fittingSize].height)];

    [_infoButton setControlSize:NSControlSizeSmall];
    [_infoButton setBordered:NO];
    [_infoButton setHidden:YES];

    _fittingHeight = centerControlsVertically([self subviews], 0);

    NSPoint titleLabelFrameOrigin = [_titleLabel frame].origin;
    titleLabelFrameOrigin.y += 1;  // extra offset for text field
    [_titleLabel setFrameOrigin:titleLabelFrameOrigin];

    [self layout];
    [self setFrameSize:[self fittingSize]];
}

- (void)layout {
    [super layout];

    NSRect bounds = [self bounds];

    NSRect indicatorFrame = [_indicator frame];
    indicatorFrame.origin.x = NSMaxX(bounds) - NSWidth(indicatorFrame);

    NSRect valueLabelFrame = [_valueLabel frame];
    valueLabelFrame.origin.x = NSMaxX(bounds) - NSWidth(valueLabelFrame) - controlSpacing;

    NSRect titleLabelFrame = [_titleLabel frame];
    titleLabelFrame.size = [_titleLabel fittingSize];

    if ([_infoButton isHidden]) {
        titleLabelFrame.size.width = MIN(NSMaxX(titleLabelFrame), NSMinX(indicatorFrame) - controlSpacing);

    } else {
        NSRect infoButtonFrame = [_infoButton frame];
        infoButtonFrame.origin.x = NSMaxX(titleLabelFrame) + controlSpacing;

        CGFloat infoButtonToIndicator = NSMinX(indicatorFrame) - NSMaxX(infoButtonFrame);
        CGFloat leftShift = controlSpacing - infoButtonToIndicator;
        if (leftShift > 0) {
            infoButtonFrame.origin.x -= leftShift;
            titleLabelFrame.size.width -= leftShift;
        }

        [_infoButton setFrameOrigin:infoButtonFrame.origin];
    }

    [_titleLabel setFrameSize:titleLabelFrame.size];
    [_indicator setFrameOrigin:indicatorFrame.origin];
    [_valueLabel setFrameOrigin:valueLabelFrame.origin];
}

- (void)popMessage:(id)sender {
    NSTextField *textField = [NSTextField wrappingLabelWithString:@""];
    [textField setSelectable:NO];
    [textField setAttributedStringValue:_message];
    [textField setPreferredMaxLayoutWidth:popoverContentWidth];
    [textField setAlignmentRect:(NSRect){popoverPadding.width, popoverPadding.height, [textField intrinsicContentSize]}];

    NSView *containerView = [[NSView alloc] initWithFrame:CGRectInset([textField frame], -popoverPadding.width, -popoverPadding.height)];
    [containerView addSubview:textField];

    NSViewController *viewController = [[NSViewController alloc] init];
    [viewController setView:containerView];

    NSPopover *popover = [[NSPopover alloc] init];
    [popover setBehavior:NSPopoverBehaviorTransient];
    [popover setContentViewController:viewController];
    [popover showRelativeToRect:[_infoButton bounds] ofView:_infoButton preferredEdge:NSMinYEdge];
}

- (void)updateTrackingAreas {
    if (_inBoundsTrackingArea) {
        [self removeTrackingArea:_inBoundsTrackingArea];
    }

    if (_message) {
        _inBoundsTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                             options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways)
                                                               owner:self
                                                            userInfo:nil];
        [self addTrackingArea:_inBoundsTrackingArea];

    } else {
        _inBoundsTrackingArea = nil;
    }
}

- (void)mouseEntered:(NSEvent *)event {
    if (_message) {
        [_infoButton setHidden:NO];
        [self setNeedsLayout:YES];
    }
}

- (void)mouseExited:(NSEvent *)event {
    if (_message) {
        [_infoButton setHidden:YES];
        [self setNeedsLayout:YES];
    }
}

@end
