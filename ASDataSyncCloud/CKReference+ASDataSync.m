//
//  CKReference+ASDataSync.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
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
    return uniqueData ? [[self alloc] initWithRecordID:[CKRecordID recordIDWithUniqueData:uniqueData] action:CKReferenceActionNone] : nil;
}

+ (instancetype)referenceWithUUIDString:(NSString *)UUIDString {
    return UUIDString ? [[self alloc] initWithRecordID:[CKRecordID recordIDWithUUIDString:UUIDString] action:CKReferenceActionNone] : nil;
}

@end
