/*
 *  main.m
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"


int main(int argc, const char * argv[]) {
    NSApplication *NSApp = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [NSApp setDelegate:delegate];
    return NSApplicationMain(argc, argv);
}
