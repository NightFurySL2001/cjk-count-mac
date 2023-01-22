/*
 *  AppDelegate.h
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import <Cocoa/Cocoa.h>
#import "InfoPanel.h"

NS_ASSUME_NONNULL_BEGIN


@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, InfoPanelDelegate, InfoPanelDataSource>

@property(nonatomic, readonly) NSWindow *window;

@end


NS_ASSUME_NONNULL_END
