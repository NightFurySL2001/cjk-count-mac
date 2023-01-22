/* 
 *  CodePointSet.m
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import "CodePointSet.h"
#import "Utils.h"


@implementation CodePointSet

static NSMutableArray<CodePointSet *> *knownCodePointSets = nil;

+ (void)initialize {
    if (self == [CodePointSet class]) {
        knownCodePointSets = [[NSMutableArray alloc] init];

        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"CodePointSets" ofType:@"plist"];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:filePath];
        NSArray<NSDictionary *> *records = [plist objectForKey:@"records"];

        for (id record in records) {
            if (![record isKindOfClass:[NSDictionary self]]) {
                NSLog(@"Unknown record found in CodePointSets.plist");
                continue;
            }

            CodePointSet *codePointSet = [CodePointSet codePointSetWithContentsOfDictionary:record];
            if (codePointSet) {
                [knownCodePointSets addObject:codePointSet];
            }
        }
    }
}

+ (NSArray<CodePointSet *> *)knownCodePointSets {
    return knownCodePointSets;
}

- (instancetype)initWithKey:(NSString *)key groupKey:(NSString *)groupKey characterSet:(NSCharacterSet *)characterSet {
    self = [super init];
    if (self) {
        _name = [[@"code-point-set-" stringByAppendingString:key] localizedString];
        _groupName = [[@"code-point-set-group-" stringByAppendingString:groupKey] localizedString];
        _characterSet = characterSet;
    }
    return self;
}

+ (instancetype)codePointSetWithContentsOfDictionary:(NSDictionary *)dictionary {
    id key = [dictionary objectForKey:@"key"];
    if (![key isKindOfClass:[NSString self]]) {
        NSLog(@"Missing property `key` in a CodePointSet record.");
        return nil;
    }

    id groupKey = [dictionary objectForKey:@"group"];
    if (![groupKey isKindOfClass:[NSString self]]) {
        NSLog(@"Missing property `group` in a CodePointSet record `%@`.", key);
        return nil;
    }

    NSMutableCharacterSet *characterSet;
    id value = [dictionary objectForKey:@"value"];
    if ([value isKindOfClass:[NSString self]]) {
        characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:value];

    } else if ([value isKindOfClass:[NSArray self]]) {
        characterSet = [[NSMutableCharacterSet alloc] init];

        NSUInteger rangeCount = [value count] / 2;
        for (NSUInteger i = 0; i < rangeCount; ++i) {
            NSNumber *lowerBoundRef = [value objectAtIndex:(i * 2)];
            NSNumber *upperBoundRef = [value objectAtIndex:(i * 2 + 1)];

            if ([lowerBoundRef isKindOfClass:[NSNumber self]] && [upperBoundRef isKindOfClass:[NSNumber self]]) {
                // FIXME: high plane code-points are not represented on 32-bit platforms
                NSInteger lowerBound = [lowerBoundRef integerValue];
                NSInteger upperBound = [upperBoundRef integerValue];
                NSRange range = NSMakeRange(lowerBound, upperBound - lowerBound + 1);
                [characterSet addCharactersInRange:range];
            }
        }

    } else {
        NSLog(@"The `value` property of CodePointSet record `%@` needs to be a string "
              @"or an array of upper and lower bounds of closed code-point ranges.", key);
        return nil;
    }

    return [[self alloc] initWithKey:key groupKey:groupKey characterSet:characterSet];
}

- (NSUInteger)count {
    return CFCharacterSetGetCharacterCount((__bridge CFCharacterSetRef)_characterSet);
}

- (NSUInteger)intersectionCountWithCharacterSet:(NSCharacterSet *)characterSet {
    CFMutableCharacterSetRef intersectionSet = CFCharacterSetCreateMutableCopy(kCFAllocatorDefault, (__bridge CFCharacterSetRef)_characterSet);
    CFCharacterSetIntersect(intersectionSet, (__bridge CFCharacterSetRef)characterSet);
    CFIndex count = CFCharacterSetGetCharacterCount(intersectionSet);
    CFRelease(intersectionSet);
    return count;
}

@end


#if __LP64__
#define uint_p UInt64
#define popcnt(x) __builtin_popcountll(x)
#else
#define uint_p UInt32
#define popcnt(x) __builtin_popcount(x)
#endif


void getUTF16FromHighPlaneCodePoint(UInt32 codePoint, UInt16 *high, UInt16 *low) {
    UInt32 p;
    UInt32 t = codePoint - 0x10000;
    p = t >> 10;
    *high = 0xD800 | p;
    p = t & 0b1111111111;
    *low = 0xDC00 | p;
}


CFIndex CFCharacterSetGetCharacterCount(CFCharacterSetRef characterSet) {
    CFIndex count = 0;

    CFDataRef data = CFCharacterSetCreateBitmapRepresentation(kCFAllocatorDefault, characterSet);
    void const *dataStart = CFDataGetBytePtr(data);
    void const *dataEnd = dataStart + CFDataGetLength(data);
    void const *dataPtr = dataStart;

    while (dataPtr < dataEnd && (size_t)dataPtr % sizeof(uint_p) != 0) {
        count += popcnt(*(UInt8 *)dataPtr);
        dataPtr += 1;
    }

    for (size_t i = (dataEnd - dataPtr) / sizeof(uint_p); i > 0; --i) {
        count += popcnt(*(uint_p *)dataPtr);
        dataPtr += sizeof(uint_p);
    }

    while (dataPtr < dataEnd) {
        count += popcnt(*(UInt8 *)dataPtr);
        dataPtr += 1;
    }

    // before each supplementary plane there is a UInt8 value indicating the plane number;
    // we should remove their influence.
    dataPtr = dataStart + 8192;
    while (dataPtr < dataEnd) {
        count -= popcnt(*(UInt8 *)dataPtr);
        dataPtr += 1 + 8192;
    }

    CFRelease(data);

    return count;
}


CFStringRef CFCharacterSetCreateCoverageString(CFAllocatorRef alloc, CFCharacterSetRef characterSet) {
    CFMutableStringRef string = CFStringCreateMutable(kCFAllocatorDefault, 0);

    CFDataRef data = CFCharacterSetCreateBitmapRepresentation(alloc, characterSet);
    UInt8 const *byteStart = CFDataGetBytePtr(data);
    UInt8 const *byteEnd = byteStart + CFDataGetLength(data);
    UInt8 const *bytePtr = byteStart;

    UInt16 utf16Buffer[256];
    size_t utf16Count = 0;

    {
        for (UInt32 i = 0; i < 65536; i += 8, bytePtr += 1) {
            if (i == 0xd800) {
                i = 0xdb78;
                bytePtr += 111;
                continue;
            }

            UInt32 codePoint = i;
            UInt8 byte = *bytePtr;
            while (byte) {
                if (byte & 1) {
                    if (utf16Count == 256) {
                        CFStringAppendCharacters(string, utf16Buffer, 256);
                        utf16Count = 0;
                    }

                    utf16Buffer[utf16Count] = codePoint;
                    utf16Count += 1;
                }

                codePoint += 1;
                byte >>= 1;
            }
        }
    }

    while (bytePtr < byteEnd) {
        UInt8 planeNumber = *bytePtr;
        bytePtr += 1;

        UInt32 endPlaneNumber = (planeNumber + 1) << 16;
        for (UInt32 i = planeNumber << 16; i < endPlaneNumber; i += 8, bytePtr += 1) {
            UInt32 codePoint = i;
            UInt8 byte = *bytePtr;
            while (byte) {
                if (byte & 1) {
                    if (utf16Count >= 255) {
                        CFStringAppendCharacters(string, utf16Buffer, 256);
                        utf16Count = 0;
                    }

                    getUTF16FromHighPlaneCodePoint(codePoint,
                                                   &utf16Buffer[utf16Count],
                                                   &utf16Buffer[utf16Count + 1]);
                    utf16Count += 2;
                }

                codePoint += 1;
                byte >>= 1;
            }
        }
    }

    if (utf16Count) {
        CFStringAppendCharacters(string, utf16Buffer, utf16Count);
    }

    CFRelease(data);

    return string;
}
