//
//  ASReference.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 23.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASReference.h"
#import "ASPublicProtocol.h"
#import "NSUUID+NSData.h"

#define ASDataSync_uniqueDataKey @"ASDataSync_uniqueData"

@implementation ASReference {
    NSData *_uniqueData;
    NSString *uuidString;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_uniqueData forKey:ASDataSync_uniqueDataKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _uniqueData = [aDecoder decodeObjectForKey:ASDataSync_uniqueDataKey];
    }
    return self;
}

+ (instancetype)null {
    return [[self alloc] init];
}

+ (instancetype)instantiateWithReference:(id <ASReference>)reference {
    return [[self alloc] initWithReference:reference];
}

- (instancetype)initWithReference:(id <ASReference>)reference {
    if (self = [super init]) {
        _uniqueData = reference.uniqueData;
    }
    return self;
}

- (NSData *)uniqueData {
    return _uniqueData;
}

- (NSString *)UUIDString {
    if (!uuidString) uuidString = _uniqueData.UUIDString;
    return uuidString;
}


@end
