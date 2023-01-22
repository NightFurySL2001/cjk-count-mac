/*
 *  Utils.m
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import "Utils.h"


@implementation NSString (Utils)

- (NSString *)localizedString {
    return NSLocalizedString(self, @"");
}

@end


@implementation NSArray (Utils)

- (NSArray *)arrayByMappingObjectsUsingBlock:(id (^)(id, NSUInteger, BOOL *))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject:block(obj, idx, stop)];
    }];
    return result;
}

@end


@implementation NSMenu (Utils)

- (instancetype)initWithTitle:(NSString *)title itemArray:(NSArray<NSMenuItem *> *)itemArray {
    self = [self initWithTitle:title];
    if (self) {
        [self setItemArray:itemArray];
    }
    return self;
}

@end


@implementation NSMenuItem (Utils)

- (instancetype)initWithSubmenu:(NSMenu *)submenu {
    self = [self initWithTitle:[submenu title] action:nil keyEquivalent:@""];
    if (self) {
        [self setSubmenu:submenu];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)string submenuItems:(NSArray<NSMenuItem *> *)submenuItems {
    self = [self initWithTitle:string action:nil keyEquivalent:@""];
    if (self) {
        [self setSubmenu: [[NSMenu alloc] initWithTitle:string itemArray:submenuItems]];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)string action:(SEL)selector {
    return [self initWithTitle:string action:selector keyEquivalent:@""];
}

- (instancetype)initWithTitle:(NSString *)string action:(SEL)selector keyEquivalent:(NSString *)charCode modifierMask:(NSEventModifierFlags)modifierMask {
    self = [self initWithTitle:string action:nil keyEquivalent:charCode];
    if (self) {
        [self setKeyEquivalentModifierMask:modifierMask];
    }
    return self;
}

@end


@implementation NSBox (Utils)

+ (NSBox *)separator {
    NSBox *separator = [[NSBox alloc] init];
    [separator setBoxType:NSBoxSeparator];
    return separator;
}

@end


@implementation NSView (Utils)

- (NSRect)alignmentRect {
    return [self alignmentRectForFrame:[self frame]];
}

- (void)setAlignmentRect:(NSRect)alignmentRect {
    [self setFrame:[self frameForAlignmentRect:alignmentRect]];
}

@end


@implementation PathControl

- (CGFloat)baselineOffsetFromBottom {return 4;}
- (NSEdgeInsets)alignmentRectInsets {return NSEdgeInsetsMake(1, 6, 2, 5);}

@end


@implementation FlippedView

- (BOOL)isFlipped {return YES;}

@end


CGFloat centerControlsVertically(NSArray<NSControl *> *controls, CGFloat offsetY) {
    NSUInteger count = [controls count];
    NSRect alignmentRects[count];
    CGFloat height = 0;

    for (NSUInteger i = 0; i < count; ++i) {
        NSControl *control = [controls objectAtIndex:i];
        [control sizeToFit];

        NSRect alignmentRect = [control alignmentRect];
        alignmentRects[i] = alignmentRect;
        height = MAX(height, alignmentRect.size.height);
    }

    for (NSUInteger i = 0; i < count; ++i) {
        NSRect alignmentRect = alignmentRects[i];
        alignmentRect.origin.y = offsetY + (height - alignmentRect.size.height) / 2;
        [[controls objectAtIndex:i] setAlignmentRect:alignmentRect];
    }

    return height;
}
