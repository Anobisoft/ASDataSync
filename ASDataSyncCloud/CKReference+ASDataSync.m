//
//  CKReference+ASDataSync.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "CKReference+ASDataSync.h"
#import "CKRecordID+ASDataSync.h"

@implementation CKReference (ASDataSync)

- (NSData *)uniqueData {
    return self.recordID.uniqueData;
}

- (NSString *)UUIDString {
    return self.recordID.recordName;
}

+ (instancetype)referenceWithUniqueData:(NSData *)uniqueData {
    return [[self alloc] initWithRecordID:[CKRecordID recordIDWithUniqueData:uniqueData] action:CKReferenceActionNone];
}

+ (instancetype)referenceWithUUIDString:(NSString *)UUIDString {
    return [[self alloc] initWithRecordID:[CKRecordID recordIDWithUUIDString:UUIDString] action:CKReferenceActionNone];
}

@end
