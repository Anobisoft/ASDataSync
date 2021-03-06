//
//  ASReference.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 23.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "ASReference.h"
#import "ASPublicProtocol.h"
#import "NSUUID+NSData.h"

#define ASDataSync_uniqueDataKey @"ASDataSync_uniqueData"

@implementation ASReference {
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

+ (instancetype)instantiateWithReference:(NSObject<ASReference> *)reference {
    return [[self alloc] initWithReference:reference];
}

- (instancetype)initWithReference:(NSObject<ASReference> *)reference {
    if (self = [super init]) {
        _uniqueData = reference.uniqueData;
    }
    return self;
}

- (NSString *)UUIDString {
    if (!uuidString) uuidString = _uniqueData.UUIDString;
    return uuidString;
}


@end
