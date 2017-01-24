//
//  ASCloudRecord.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>

@interface CKRecordID(ASDataSync)

+ (instancetype)recordIDWithUniqueData:(NSData *)uniqueData;
+ (instancetype)recordIDWithRecordName:(NSString *)recordName;
- (NSUUID *)UUID;

@end

@interface ASCloudRecord : CKRecord

+ (instancetype)recordWithRecordType:(NSString *)recordType recordID:(CKRecordID *)recordID;

@property (nonatomic, copy) NSData *uniqueData;
@property (nonatomic, copy) NSDate *modificationDate;
@property (nonatomic, strong) NSDictionary <NSString *, id <NSCoding>> *keyedProperties;
@property (nonatomic, strong) NSDictionary <NSString *, CKReference *> *keyedReferences;
@property (nonatomic, strong) NSDictionary <NSString *, NSArray <CKReference *> *> *keyedMultiReferences;

@end
