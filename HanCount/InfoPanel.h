/*
 *  InfoPanel.h
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN


@class InfoPanel;


@protocol InfoPanelDelegate <NSObject>

- (NSArray<NSString *> *)allowedFileExtensionsOfInfoPanel:(InfoPanel *)infoPanel;
- (BOOL)infoPanel:(InfoPanel *)infoPanel shouldOpenFontAtURL:(NSURL *)url;

@end


@protocol InfoPanelDataSource <NSObject>

- (NSUInteger)numberOfFontsInInInfoPanel:(InfoPanel *)infoPanel;
- (NSString *)infoPanel:(InfoPanel *)infoPanel nameOfFontAtIndex:(NSUInteger)index;
- (NSCharacterSet *)infoPanel:(InfoPanel *)infoPanel characterSetOfFontAt:(NSUInteger)index;

@end


@interface InfoPanel : NSView

@property(nonatomic, weak) id<InfoPanelDelegate> delegate;
@property(nonatomic, weak) id<InfoPanelDataSource> dataSource;

@property(nonatomic, readonly) NSSize minSize;
@property(nonatomic, readonly) NSSize maxSize;
@property(nonatomic, readonly) NSSize standardSize;
- (NSSize)sizeThatFits:(NSSize)newSize;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)reloadData;
- (BOOL)openFontAtURL:(NSURL *)url;

@end


NS_ASSUME_NONNULL_END
