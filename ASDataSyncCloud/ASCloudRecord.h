//
//  ASCloudRecord.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>
#import "ASPublicProtocol.h"

@class ASCloudID, ASCloudMapping;

@interface ASCloudRecord : CKRecord <ASMappedObject>

+ (instancetype)recordWithRecordType:(NSString *)recordType recordID:(ASCloudID *)recordID;
+ (instancetype)recordWithRecordType:(NSString *)recordType;

- (id <ASDescription>)descriptionOfDeletedObjectWithMapping:(ASCloudMapping *)mapping;
- (id <ASMappedObject>)mappedObjectWithMapping:(ASCloudMapping *)mapping;

- (void)setModificationDate:(NSDate *)date;
- (void)setKeyedDataProperties:(NSDictionary <NSString *, NSObject <NSCoding> *> *)keyedDataProperties;
- (void)replaceRelation:(NSString *)relationKey toReference:(id<ASReference>)reference;
- (void)replaceRelation:(NSString *)relationKey toSetsOfReferences:(NSSet <id<ASReference>> *)setOfReferences;

@end
