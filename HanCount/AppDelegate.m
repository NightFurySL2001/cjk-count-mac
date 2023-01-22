/* 
 *  AppDelegate.m
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import "AppDelegate.h"
#import "Utils.h"


@implementation AppDelegate {
    InfoPanel *_infoPanel;

    NSArray<NSCharacterSet *> *_characterSets;
    NSArray<NSString *> *_fontNames;

    NSArray<NSString *> *_allowedFileTypes;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [self setUpMainMenu];

    // create the window before `application:openFile:`
    NSArray<NSDictionary *> *documentTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDocumentTypes"];
    _allowedFileTypes = [[documentTypes objectAtIndex:0] objectForKey:@"CFBundleTypeExtensions"];

    _infoPanel = [[InfoPanel alloc] init];
    [_infoPanel setDelegate:self];
    [_infoPanel setDataSource:self];

    _window = [[NSWindow alloc] initWithContentRect:(NSRect){NSZeroPoint, [_infoPanel fittingSize]}
                                          styleMask:NSWindowStyleMaskTitled
                                                  | NSWindowStyleMaskClosable
                                                  | NSWindowStyleMaskMiniaturizable
                                                  | NSWindowStyleMaskResizable
                                            backing:NSBackingStoreBuffered
                                              defer:YES];
    [_window setContentView:_infoPanel];
    [_window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenNone];
    [_window setContentMinSize:[_infoPanel minSize]];
    [_window setContentMaxSize:[_infoPanel maxSize]];
    [_window setDelegate:self];
    [_window setTitle:[@"app-name" localizedString]];
    [_window center];
    [_window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    NSURL *url = [NSURL fileURLWithPath:filename];
    [_infoPanel openFontAtURL:url];
    return YES;
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)frameSize {
    NSSize contentSize = [window contentRectForFrameRect:(NSRect){NSZeroPoint, frameSize}].size;
    contentSize = [_infoPanel sizeThatFits:contentSize];
    return [window frameRectForContentRect:(NSRect){NSZeroPoint, contentSize}].size;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame {
    NSSize standardSize = [window frameRectForContentRect:(NSRect){NSZeroPoint, [_infoPanel standardSize]}].size;
    NSRect frame = [window frame];
    frame.origin.y += frame.size.height - standardSize.height;
    frame.size = standardSize;
    return frame;
}

// MARK: InfoRowDelegate

- (NSArray<NSString *> *)allowedFileExtensionsOfInfoPanel:(InfoPanel *)infoPanel {
    return _allowedFileTypes;
}

- (BOOL)infoPanel:(InfoPanel *)infoPanel shouldOpenFontAtURL:(NSURL *)url {
    CFArrayRef descriptors = CTFontManagerCreateFontDescriptorsFromURL((__bridge CFURLRef)url);
    if (!descriptors) {return NO;}

    CFIndex descriptorCount = CFArrayGetCount(descriptors);
    if (descriptorCount <= 0) {
        CFRelease(descriptors);
        return NO;
    }

    NSMutableArray<NSCharacterSet *> *characterSets = [NSMutableArray array];
    NSMutableArray<NSString *> *subfamilies = [NSMutableArray array];
    NSMutableArray<NSString *> *fullNames = [NSMutableArray array];

    for (CFIndex i = 0; i < descriptorCount; ++i) {
        CTFontDescriptorRef descriptor = CFArrayGetValueAtIndex(descriptors, i);
        CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, 12, NULL);

        CFCharacterSetRef characterSet = CTFontCopyCharacterSet(font);
        CFStringRef subfamily = CTFontCopyLocalizedName(font, kCTFontSubFamilyNameKey, NULL) ?: CFSTR("<unnamed>");
        CFStringRef fullName = CTFontCopyLocalizedName(font, kCTFontFullNameKey, NULL) ?: CFSTR("<unnamed>");

        CFRelease(font);

        [characterSets addObject:(__bridge_transfer NSCharacterSet *)characterSet];
        [subfamilies addObject:(__bridge_transfer NSString *)subfamily];
        [fullNames addObject:(__bridge_transfer NSString *)fullName];
    }

    CFRelease(descriptors);

    _characterSets = characterSets;

    if ([[NSSet setWithArray:subfamilies] count] == descriptorCount) {
        _fontNames = subfamilies;
    } else if ([[NSSet setWithArray:fullNames] count] == descriptorCount) {
        _fontNames = fullNames;
    } else {
        _fontNames = [fullNames arrayByMappingObjectsUsingBlock:^id(NSString *fullName, NSUInteger index, BOOL *stop) {
            return [NSString stringWithFormat:@"%lu\t%@", index + 1, fullName];
        }];
    }

    return YES;
}

// MARK: InfoRowDataSource

- (NSUInteger)numberOfFontsInInInfoPanel:(InfoPanel *)infoPanel {
    return [_fontNames count];
}

- (NSString *)infoPanel:(InfoPanel *)infoPanel nameOfFontAtIndex:(NSUInteger)index {
    return [_fontNames objectAtIndex:index];
}

- (NSCharacterSet *)infoPanel:(InfoPanel *)infoPanel characterSetOfFontAt:(NSUInteger)index {
    return [_characterSets objectAtIndex:index];
}

// MARK: Build Main Menu

- (void)setUpMainMenu {
    NSMenu *servicesMenu = [[NSMenu alloc] initWithTitle:[@"menu-services" localizedString]];

    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:[@"app-name" localizedString] itemArray:@[
        [[NSMenuItem alloc] initWithTitle:[@"menu-about-app" localizedString]
                                   action:@selector(goToGitHub:)],

        [NSMenuItem separatorItem],

        [[NSMenuItem alloc] initWithSubmenu:servicesMenu],

        [NSMenuItem separatorItem],

        [[NSMenuItem alloc] initWithTitle:[@"menu-hide-app" localizedString]
                                   action:@selector(hide:)
                            keyEquivalent:@"h"],

        [[NSMenuItem alloc] initWithTitle:[@"menu-hide-others" localizedString]
                                   action:@selector(hideOtherApplications:)
                            keyEquivalent:@"h"
                             modifierMask:(NSEventModifierFlagOption | NSEventModifierFlagCommand)],

        [[NSMenuItem alloc] initWithTitle:[@"menu-show-all" localizedString]
                                   action:@selector(unhideAllApplications:)],

        [NSMenuItem separatorItem],

        [[NSMenuItem alloc] initWithTitle:[@"menu-quit-app" localizedString]
                                   action:@selector(terminate:)
                            keyEquivalent:@"q"]
    ]];

    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:[@"menu-file" localizedString] itemArray:@[
        [[NSMenuItem alloc] initWithTitle:[@"menu-open" localizedString]
                                   action:@selector(open:)
                            keyEquivalent:@"o"],

        [[NSMenuItem alloc] initWithTitle:[@"menu-close" localizedString]
                                   action:@selector(performClose:)
                            keyEquivalent:@"w"]
    ]];

    NSMenu *windowsMenu = [[NSMenu alloc] initWithTitle:[@"menu-windows" localizedString] itemArray:@[
        [[NSMenuItem alloc] initWithTitle:[@"menu-minimize" localizedString]
                                   action:@selector(performMiniaturize:)
                            keyEquivalent:@"m"],

        [[NSMenuItem alloc] initWithTitle:[@"menu-zoom" localizedString]
                                   action:@selector(performZoom:)]
    ]];

    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:[@"menu-help" localizedString] itemArray:@[
        [[NSMenuItem alloc] initWithTitle:[@"menu-app-help" localizedString]
                                   action:@selector(goToGitHub:)]
    ]];

    [[NSApplication sharedApplication] setMainMenu:[[NSMenu alloc] initWithTitle:@"MainMenu" itemArray:@[
        [[NSMenuItem alloc] initWithSubmenu:appMenu],
        [[NSMenuItem alloc] initWithSubmenu:fileMenu],
        [[NSMenuItem alloc] initWithSubmenu:windowsMenu],
        [[NSMenuItem alloc] initWithSubmenu:helpMenu],
    ]]];

    [[NSApplication sharedApplication] setServicesMenu:servicesMenu];
    [[NSApplication sharedApplication] setWindowsMenu:windowsMenu];
    [[NSApplication sharedApplication] setHelpMenu:helpMenu];
}

- (void)goToGitHub:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/NightFurySL2001/cjk-count-mac"]];
}

@end
