/*
 *  InfoPanel.m
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import "InfoPanel.h"
#import "InfoRow.h"
#import "CodePointSet.h"
#import "Utils.h"


@implementation InfoPanel {
    NSTextField *_fileLabel;
    NSPathControl *_pathControl;
    NSPopUpButton *_fontSelector;
    NSButton *_openButton;

    NSBox *_separator;

    NSScrollView *_scrollView;

    NSArray<NSBox *> *_boxes;
    NSUInteger _indexOfWrappingBox;

    NSArray<InfoRow *> *_infoRows;

    CGSize _standardSize;
    CGSize _minSizeWithDoubleColumns;

    NSAlert *_badFileAlert;
    NSURL *_draggingURL;
}

- (instancetype)init {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        _fileLabel = [NSTextField labelWithString:[@"file-label" localizedString]];
        _pathControl = [[PathControl alloc] init];
        _fontSelector = [NSPopUpButton buttonWithTitle:@"" target:nil action:@selector(selectFont:)];
        _openButton = [NSButton buttonWithTitle:[@"open-button" localizedString] target:nil action:@selector(open:)];

        [_pathControl setURL:[NSURL fileURLWithPath:@"/"]];
        [_pathControl setRefusesFirstResponder:YES];
        [_fontSelector setHidden:YES];
        [_openButton setKeyEquivalent:@"\r"];

        _separator = [NSBox separator];

        _scrollView = [[NSScrollView alloc] init];

        NSMutableArray<NSString *> *groupNames = [NSMutableArray array];
        _boxes = [NSMutableArray array];
        _infoRows = [[CodePointSet knownCodePointSets] arrayByMappingObjectsUsingBlock:^id _Nonnull(CodePointSet *codePointSet, NSUInteger idx, BOOL *stop) {
            InfoRow *infoRow = [[InfoRow alloc] initWithValue:0 maxValue:[codePointSet count] title:[codePointSet name]];
            NSString *groupName = [codePointSet groupName];
            NSUInteger indexOfBox = [groupNames indexOfObject:groupName];

            if (indexOfBox != NSNotFound) {
                [[[self->_boxes objectAtIndex:indexOfBox] contentView] addSubview:infoRow];
            } else {
                NSBox *box = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, 384, 256)];
                [[box contentView] addSubview:infoRow];
                [box setTitle:groupName];
                [groupNames addObject:groupName];
                [(NSMutableArray *)self->_boxes addObject:box];
            }

            return infoRow;
        }];

        {
            NSInteger delta = NSIntegerMax;
            NSInteger boxCount = [_boxes count];
            NSInteger infoRowCount = [_infoRows count];
            NSInteger accumulatedInfoRowCount = 0;
            for (NSUInteger i = 0; i < boxCount; ++i) {
                NSInteger thisDelta = ABS(infoRowCount - accumulatedInfoRowCount * 2);
                if (thisDelta <= delta) {
                    delta = thisDelta;
                    _indexOfWrappingBox = i;

                } else {
                    break;
                }

                NSBox *box = [_boxes objectAtIndex:i];
                accumulatedInfoRowCount += [[[box contentView] subviews] count];
            }
        }

        [_scrollView setDocumentView:[[FlippedView alloc] init]];
        [[_scrollView documentView] setSubviews:_boxes];
        [self setSubviews:@[_fileLabel, _pathControl, _fontSelector, _openButton, _separator, _scrollView]];
        [self initializeLayout];

        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame {
    return [self init];
}

- (void)setDataSource:(id<InfoPanelDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        [self reloadData];
    }
}

static NSSize const panelPadding = {20, 20};
static NSSize const boxMargin = {18, 10};
static NSSize const boxPadding = {10, 6};
static CGFloat const headerControlMargin = 8;
static CGFloat const separatorMargin = 14;
static CGFloat const rowMargin = 5;
static CGFloat const fontSelectorMaxWidth = 200;
static CGFloat const openButtonMinWidth = 80;

- (BOOL)isFlipped {return YES;}

- (NSSize)minSize {
    return NSMakeSize(384, 256);
}

- (NSSize)maxSize {
    return NSMakeSize(1280, 1024);
}

- (NSSize)sizeThatFits:(NSSize)newSize {
    if (newSize.width >= _minSizeWithDoubleColumns.width) {
        newSize.height = _minSizeWithDoubleColumns.height;
    }
    return newSize;
}

- (void)initializeLayout {
    NSArray *headerControls = @[_fileLabel, _pathControl, _fontSelector, _openButton];
    CGFloat headerHeight = centerControlsVertically(headerControls, panelPadding.height);

    NSRect fileLabelRect = [_fileLabel alignmentRect];
    fileLabelRect.origin.x = panelPadding.width;
    [_fileLabel setAlignmentRect:fileLabelRect];

    NSRect pathControlRect = [_pathControl alignmentRect];
    pathControlRect.origin.x = NSMaxX(fileLabelRect) + headerControlMargin;
    [_pathControl setAlignmentRect:pathControlRect];

    NSRect openButtonRect = [_openButton alignmentRect];
    openButtonRect.size.width = MAX(openButtonRect.size.width, openButtonMinWidth);
    [_openButton setAlignmentRect:openButtonRect];

    NSRect separatorRect;
    separatorRect.origin.x = panelPadding.width;
    separatorRect.origin.y = panelPadding.height + headerHeight + separatorMargin;
    separatorRect.size.height = 1;
    separatorRect.size.width = 200;
    [_separator setFrame:separatorRect];

    [_scrollView setDrawsBackground:NO];
    [_scrollView setBorderType:NSNoBorder];
    [_scrollView setFrameOrigin:NSMakePoint(0, NSMaxY(separatorRect))];

    __block CGFloat fittingBoxWidth = 0;

    for (NSBox *box in _boxes) {
        [box setContentViewMargins:boxPadding];

        NSView *contentView = [box contentView];

        NSRect boxFrame = [box frame];
        CGFloat heightOffset = NSHeight(boxFrame) - NSHeight([contentView frame]) + boxPadding.height - 2;
        CGFloat boxContentWidth = [contentView bounds].size.width;

        NSArray<InfoRow *> *infoRows = [contentView subviews];
        NSUInteger infoRowCount = [infoRows count];
        [infoRows enumerateObjectsUsingBlock:^(InfoRow *infoRow, NSUInteger i, BOOL *stop) {
            NSRect infoRowRect = [infoRow alignmentRect];
            infoRowRect.origin.x = 0;
            infoRowRect.origin.y = (infoRowRect.size.height + rowMargin) * (infoRowCount - 1 - i);
            infoRowRect.size.width = boxContentWidth;
            [infoRow setAlignmentRect:infoRowRect];
            [infoRow setAutoresizingMask:NSViewWidthSizable];
            fittingBoxWidth = MAX(fittingBoxWidth, [infoRow fittingSize].width);
        }];

        CGFloat contentHeight = NSMaxY([[infoRows firstObject] frame]);
        [box setFrameSize:NSMakeSize(NSWidth(boxFrame), contentHeight + heightOffset)];
    }

    fittingBoxWidth += boxPadding.width * 2;
    _minSizeWithDoubleColumns.width = fittingBoxWidth * 1.6 + boxMargin.width + panelPadding.width * 2;
    _minSizeWithDoubleColumns.height = [self layoutWithinPanelWidth:[self maxSize].width];

    if (_minSizeWithDoubleColumns.width <= 800) {
        _standardSize.width = fittingBoxWidth * 2 + boxMargin.width + panelPadding.width * 2;
        _standardSize.height = _minSizeWithDoubleColumns.height;
    } else {
        _standardSize.width = fittingBoxWidth + boxMargin.width + panelPadding.width * 2;
        _standardSize.height = MAX(_minSizeWithDoubleColumns.height, 600);
    }

    [self setFrameSize:_standardSize];
}

- (CGFloat)layoutWithinPanelWidth:(CGFloat)panelWidth {
    NSRect openButtonRect = [_openButton alignmentRect];
    openButtonRect.origin.x = panelWidth - panelPadding.width - openButtonRect.size.width;

    NSRect pathControlRect = [_pathControl alignmentRect];

    if ([_fontSelector isHidden]) {
        pathControlRect.size.width = NSMinX(openButtonRect) - NSMinX(pathControlRect) - headerControlMargin;

    } else {
        CGRect fontSelectRect = [_fontSelector alignmentRect];
        fontSelectRect.size.width = MIN(fontSelectRect.size.width, fontSelectorMaxWidth);
        fontSelectRect.origin.x = NSMinX(openButtonRect) - NSWidth(fontSelectRect) - headerControlMargin;
        pathControlRect.size.width = NSMinX(fontSelectRect) - NSMinX(pathControlRect) - headerControlMargin;

        [_fontSelector setAlignmentRect:fontSelectRect];
    }

    [_openButton setAlignmentRect:openButtonRect];
    [_pathControl setAlignmentRect:pathControlRect];

    CGFloat contentWidth = panelWidth - panelPadding.width * 2;
    [_separator setFrameSize:NSMakeSize(contentWidth, 1)];

    CGFloat boxWidth;
    NSRange boxRanges[2];

    BOOL usesDoubleColumns = panelWidth >= _minSizeWithDoubleColumns.width;

    if (usesDoubleColumns) {
        boxWidth = (contentWidth - boxMargin.width) / 2;
        boxRanges[0] = NSMakeRange(0, _indexOfWrappingBox);
        boxRanges[1] = NSMakeRange(_indexOfWrappingBox, [_boxes count] - _indexOfWrappingBox);
    } else {
        boxWidth = contentWidth;
        boxRanges[0] = NSMakeRange(0, [_boxes count]);
        boxRanges[1] = NSMakeRange(0, 0);
    }

    CGFloat boxMinXs[2] = {panelPadding.width, panelPadding.width + boxWidth + boxMargin.width};

    for (NSUInteger i = 0; i < 2; ++i) {
        NSRange columnRange = boxRanges[i];
        NSUInteger endIndex = columnRange.location + columnRange.length;

        CGFloat x = boxMinXs[i];
        CGFloat y = separatorMargin;

        for (NSUInteger j = columnRange.location; j < endIndex; ++j) {
            NSBox *box = [_boxes objectAtIndex:j];
            NSRect boxRect = NSMakeRect(x, y, boxWidth, [box alignmentRect].size.height);
            [box setAlignmentRect:boxRect];
            y += boxRect.size.height + boxMargin.height;
        }
    }

    CGFloat contentScrollMaxY = MAX(NSMaxY([[_boxes objectAtIndex:(_indexOfWrappingBox - 1)] alignmentRect]),
                                    NSMaxY([[_boxes objectAtIndex:([_boxes count] - 1)] alignmentRect]));

    NSSize scrollSize = NSMakeSize(panelWidth, contentScrollMaxY + panelPadding.height);
    [[_scrollView documentView] setFrameSize:scrollSize];

    if (usesDoubleColumns) {
        [_scrollView setFrameSize:scrollSize];
        [_scrollView setHasVerticalScroller:NO];
        [_scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    } else {
        [_scrollView setFrameSize:NSMakeSize(panelWidth, NSHeight([self bounds]) - NSMinY([_scrollView frame]))];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setVerticalScrollElasticity:NSScrollElasticityAutomatic];
        [_scrollView flashScrollers];
    }

    return NSMaxY([_scrollView frame]);
}

- (void)layout {
    [self layoutWithinPanelWidth:[self bounds].size.width];
}

- (NSSize)intrinsicContentSize {
    return [self sizeThatFits:[self bounds].size];
}

- (void)reloadData {
    if (!_dataSource) {return;}

    NSUInteger numberOfFonts = [_dataSource numberOfFontsInInInfoPanel:self];
    if (numberOfFonts == 0) {return;}

    BOOL shouldHideFontSelector = numberOfFonts == 1;
    if (!shouldHideFontSelector) {
        [_fontSelector removeAllItems];
        for (NSUInteger i = 0; i < numberOfFonts; ++i) {
            [_fontSelector addItemWithTitle:[_dataSource infoPanel:self nameOfFontAtIndex:i]];
        }
        [_fontSelector selectItemAtIndex:0];
        [_fontSelector sizeToFit];
        [self setNeedsLayout:YES];
    }

    if (shouldHideFontSelector != [_fontSelector isHidden]) {
        [_fontSelector setHidden:shouldHideFontSelector];
        [self setNeedsLayout:YES];
    }

    [self loadCharacterSet:[_dataSource infoPanel:self characterSetOfFontAt:0]];
}

- (BOOL)openFontAtURL:(NSURL *)url {
    if (_badFileAlert) {
        // FIXME: the sheet appears twice if interrupted by another sheet
        //[[_badFileAlert window] close];
        NSButton *okButton = [_badFileAlert valueForKey:@"_first"];
        [okButton sendAction:[okButton action] to:[okButton target]];
    }

    if ([_delegate infoPanel:self shouldOpenFontAtURL:url]) {
        [_pathControl setURL:url];
        [self reloadData];
        return true;

    } else {
        _badFileAlert = [[NSAlert alloc] init];
        [_badFileAlert setAlertStyle:NSAlertStyleWarning];
        [_badFileAlert setMessageText:[[@"bad-file-$1" localizedString] stringByReplacingOccurrencesOfString:@"$1"
                                                                                                  withString:[[url lastPathComponent] description]]];
        [_badFileAlert setInformativeText:[@"bad-file-help" localizedString]];
        [_badFileAlert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            self->_badFileAlert = nil;
        }];

        return false;
    }
}

- (void)open:(id)sender {
    if (!_delegate) {return;}
    if (![self window]) {return;}

    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
    [panel setDirectoryURL:[_pathControl URL]];
    [panel setAllowedFileTypes:[_delegate allowedFileExtensionsOfInfoPanel:self]];
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK || ![panel URL]) {return;}
        [self openFontAtURL:[panel URL]];
    }];
}

- (void)selectFont:(NSPopUpButton *)sender {
    if (!_delegate) {return;}
    [self loadCharacterSet:[_dataSource infoPanel:self characterSetOfFontAt:[sender indexOfSelectedItem]]];
}

- (void)loadCharacterSet:(NSCharacterSet *)characterSet {
    [[CodePointSet knownCodePointSets] enumerateObjectsUsingBlock:^(CodePointSet *codePointSet, NSUInteger i, BOOL *stop) {
        [[_infoRows objectAtIndex:i] setValue:[codePointSet intersectionCountWithCharacterSet:characterSet]];
    }];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    _draggingURL = [NSURL URLFromPasteboard:[sender draggingPasteboard]];
    NSString *extension = [[_draggingURL pathExtension] lowercaseString];
    if (![[_delegate allowedFileExtensionsOfInfoPanel:self] containsObject:extension]) {
        return NSDragOperationNone;
    }

    [_openButton setHighlighted:YES];
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    [self openFontAtURL:_draggingURL];
    return YES;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    [_openButton setHighlighted:NO];
    _draggingURL = nil;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    [_openButton setHighlighted:NO];
    _draggingURL = nil;
}

@end
