/*
 *  HanCountTests.m
 *
 *  Created by alpha on 2023/1/13.
 *  Copyright © 2023 alphaArgon.
 */

#import <XCTest/XCTest.h>
#import "CodePointSet.h"


@interface HanCountTests : XCTestCase @end

@implementation HanCountTests

- (void)testCodePointSet {
    UInt32 utf32[2] = {0x10000, 0x20000};
    utf32[0] = CFSwapInt32HostToBig(utf32[0]);
    utf32[1] = CFSwapInt32HostToBig(utf32[1]);

    CFStringRef highPlaneString = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8 *)utf32, 8, kCFStringEncodingUTF32BE, false);

    CFMutableCharacterSetRef characterSet = CFCharacterSetCreateMutable(kCFAllocatorDefault);
    CFCharacterSetAddCharactersInString(characterSet, highPlaneString);
    CFCharacterSetAddCharactersInString(characterSet, CFSTR("Aa"));

    XCTAssert(CFCharacterSetIsLongCharacterMember(characterSet, 0x20000));
    XCTAssert(CFCharacterSetGetCharacterCount(characterSet) == 4);

    CFStringRef coverageString = CFCharacterSetCreateCoverageString(characterSet);
    XCTAssert(CFStringGetLength(coverageString) == 6);

    CFRelease(highPlaneString);
    CFRelease(characterSet);
    CFRelease(coverageString);
}

@end
