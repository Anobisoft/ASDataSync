//
//  CKRecordID+ASDataSync.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "CKRecordID+ASDataSync.h"
#import "NSUUID+NSData.h"

@implementation CKRecordID (ASDataSync)

+ (instancetype)recordIDWithUniqueData:(NSData *)uniqueData {
    return [[self alloc] initWithRecordName:uniqueData.UUIDString];
}

+ (instancetype)recordIDWithUUIDString:(NSString *)UUIDString {
    return [[self alloc] initWithRecordName:UUIDString];
}

- (NSString *)UUIDString {
    return self.recordName;
}

- (NSUUID *)UUID {
    return [[NSUUID alloc] initWithUUIDString:self.UUIDString];
}

- (NSData *)uniqueData {
    return self.UUID.data;
}

@end
