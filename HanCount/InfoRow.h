/*
 *  InfoRow.h
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN


@interface InfoRow : NSView

@property(nonatomic) NSInteger value;
@property(nonatomic) NSInteger maxValue;

@property(nonatomic) NSString *title;

@property(nonatomic, nullable) NSAttributedString *message;

@property(nonatomic) double warningFraction;
@property(nonatomic) double criticalFraction;

- (instancetype)initWithValue:(NSInteger)value maxValue:(NSInteger)maxValue title:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
