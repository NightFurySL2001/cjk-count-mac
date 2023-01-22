/*
 *  CodePointSet.h
 *
 *  Created by alpha on 2023/1/10.
 *  Copyright © 2023 alphaArgon.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface CodePointSet : NSObject

@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *groupName;
@property(nonatomic, readonly) NSCharacterSet *characterSet;

@property(nonatomic, readonly, class) NSArray<CodePointSet *> *knownCodePointSets;

- (instancetype)init NS_UNAVAILABLE;

@property(nonatomic, readonly) NSUInteger count;
- (NSUInteger)intersectionCountWithCharacterSet:(NSCharacterSet *)characterSet;

@end


void getUTF16FromHighPlaneCodePoint(UInt32 codePoint, UInt16 *high, UInt16 *low);
CFIndex CFCharacterSetGetCharacterCount(CFCharacterSetRef characterSet);

/// Creates a string which consists of all characters in the given character set. Note that the character set
/// should not contain character `NULL`, otherwise an empty string will be created.
CFStringRef CFCharacterSetCreateCoverageString(CFAllocatorRef alloc, CFCharacterSetRef characterSet);


NS_ASSUME_NONNULL_END
