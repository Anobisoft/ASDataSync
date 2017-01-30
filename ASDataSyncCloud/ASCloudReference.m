//
//  ASCloudReference.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 25.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASCloudReference.h"
#import "NSUUID+NSData.h"

@implementation CKRecordID(ASDataSync)

- (NSUUID *)UUID {
    return [[NSUUID alloc] initWithUUIDString:self.recordName];
}

@end

@implementation ASCloudID {
    NSUUID *uuid;
}

- (NSData *)uniqueData {
    if (!uuid) uuid = self.UUID;
    return uuid.data;
}

- (NSString *)UUIDString {
    return self.recordName;
}

+ (instancetype)cloudIDWithUniqueData:(NSData *)uniqueData {
    return [[super alloc] initWithRecordName:uniqueData.UUIDString];
}

+ (instancetype)cloudIDWithUUIDString:(NSString *)UUIDString {
    return [[super alloc] initWithRecordName:UUIDString];
}

@end

@implementation ASCloudReference {
    NSUUID *uuid;
}

- (NSData *)uniqueData {
    if (!uuid) uuid = self.recordID.UUID;
    return uuid.data;
}

- (NSString *)UUIDString {
    return self.recordID.recordName;
}

+ (instancetype)referenceWithUniqueData:(NSData *)uniqueData {
    return [[super alloc] initWithRecordID:[ASCloudID cloudIDWithUniqueData:uniqueData] action:nil];
}

+ (instancetype)referenceWithUUIDString:(NSString *)UUIDString {
    return [[super alloc] initWithRecordID:[ASCloudID cloudIDWithRecordName:UUIDString] action:nil];
}

@end
