//
//  CKRecord+ASDataSync.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "CKRecord+ASDataSync.h"
#import "ASCloudRecordRepresentation.h"
#import "NSUUID+NSData.h"
#import "CKRecordID+ASDataSync.h"
#import "CKReference+ASDataSync.h"
#import "ASCloudInternalConst.h"

@implementation CKRecord (ASDataSync)

+ (instancetype)recordWithRecordType:(NSString *)recordType recordID:(CKRecordID *)recordID {
    return [[self alloc] initWithRecordType:recordType recordID:recordID];
}

+ (instancetype)recordWithRecordType:(NSString *)recordType {
    return [[self alloc] initWithRecordType:recordType];
}

- (id <ASDescription>)descriptionOfDeletedObjectWithMapping:(ASCloudMapping *)mapping {
    return [ASCloudDescriptionRepresentation instantiateWithRecordType:self[ASCloudDeletionInfoRecordProperty_recordType] uniqueData:[NSUUID UUIDWithUUIDString:self[ASCloudDeletionInfoRecordProperty_recordID]].data mapping:mapping];
}

- (id <ASMappedObject>)mappedObjectWithMapping:(ASCloudMapping *)mapping {
    return [ASCloudRecordRepresentation instantiateWithCloudRecord:(CKRecord<ASMappedObject> *)self mapping:mapping];
}

#pragma mark - getters

- (NSData *)uniqueData {
    return self.recordID.UUID.data;
}

- (NSString *)UUIDString {
    return self.recordID.recordName;
}

- (NSDate *)modificationDate {
    return self[ASCloudRealModificationDateProperty];
}

- (NSString *)entityName {
    @throw [NSException exceptionWithName:NSObjectInaccessibleException reason:[NSString stringWithFormat:@"[NOTICE] -[CKRecord entityName] unavailable. recordType %@ UUID %@", self.recordType, self.UUIDString] userInfo:nil];
    return nil;
}

- (NSDictionary<NSString *, NSObject <NSCoding> *> *)keyedDataProperties {
    NSMutableDictionary *tmp = [NSMutableDictionary new];
    for (NSString *key in self.allKeys) {
        [tmp setObject:self[key] forKey:key];
    }
    return tmp.copy;
}

#pragma mark - setters

- (void)setModificationDate:(NSDate *)date {
    self[ASCloudRealModificationDateProperty] = date;
}

- (void)setKeyedDataProperties:(NSDictionary <NSString *, NSObject <NSCoding> *> *)keyedDataProperties {
    for (NSString *key in keyedDataProperties.allKeys) {
        self[key] = [keyedDataProperties[key] isKindOfClass:[NSNull class]] ? nil : (__kindof id <CKRecordValue>)keyedDataProperties[key];
    }
}

- (void)replaceRelation:(NSString *)relationKey toReference:(id<ASReference>)reference {
    self[relationKey] = [CKReference referenceWithUniqueData:reference.uniqueData];
}

- (void)replaceRelation:(NSString *)relationKey toSetsOfReferences:(NSSet <id<ASReference>> *)setOfReferences {
    NSMutableArray *tmpArray = [NSMutableArray new];
    for (id<ASReference> reference in setOfReferences) {
        [tmpArray addObject:[CKReference referenceWithUniqueData:reference.uniqueData]];
    }
    self[relationKey] = tmpArray.count ? tmpArray.copy : nil;
}



@end
