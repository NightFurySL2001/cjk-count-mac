/*
 *  Utils.h
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSString (Utils)

- (NSString *)localizedString;

@end


@interface NSArray<ObjectType> (Utils)

- (NSArray *)arrayByMappingObjectsUsingBlock:(id (^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

@end


@interface NSMenu (Utils)

- (instancetype)initWithTitle:(NSString *)title itemArray:(NSArray<NSMenuItem *> *)itemArray;

@end


@interface NSMenuItem (Utils)

- (instancetype)initWithSubmenu:(NSMenu *)submenu;
- (instancetype)initWithTitle:(NSString *)string submenuItems:(NSArray<NSMenuItem *> *)submenuItems;
- (instancetype)initWithTitle:(NSString *)string action:(SEL)selector;
- (instancetype)initWithTitle:(NSString *)string action:(SEL)selector keyEquivalent:(NSString *)charCode modifierMask:(NSEventModifierFlags)modifierMask;

@end


@interface NSBox (Utils)

+ (NSBox *)separator;

@end


@interface NSView (Utils)

@property(nonatomic) NSRect alignmentRect;

@end


@interface PathControl : NSPathControl

- (CGFloat)baselineOffsetFromBottom;
- (NSEdgeInsets)alignmentRectInsets;

@end


@interface FlippedView : NSView

- (BOOL)isFlipped;

@end


/// Centers the controls vertically and returns the height the controls occupy.
CGFloat centerControlsVertically(NSArray<NSControl *> *controls, CGFloat offsetY);


NS_ASSUME_NONNULL_END
