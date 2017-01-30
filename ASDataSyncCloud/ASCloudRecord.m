//
//  ASCloudRecord.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASCloudRecord.h"
#import "NSUUID+NSData.h"
#import "ASCloudReference.h"
#import "ASCloudMapping.h"

#define kASCloudRealModificationDate @"changeDate"
//#define kASCloudObjectDeletionInfoRecordType @"DeleteQueue"

#pragma mark - ASCloudDescriptionRepresentation

@interface ASCloudDescriptionRepresentation : NSObject <ASDescription>


@end

@implementation ASCloudDescriptionRepresentation {
    NSString *_entityName, *_uuidString;
    NSData *_uniqueData;
}

- (NSString *)entityName {
    return _entityName;
}

- (NSData *)uniqueData {
    return _uniqueData;
}

- (NSString *)UUIDString {
    if (!_uuidString) _uuidString = _uniqueData.UUIDString;
    return _uuidString;
}

+ (instancetype)instantiateWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(ASCloudMapping *)mapping {
    return [[self alloc] initWithRecordType:recordType uniqueData:uniqueData mapping:mapping];
}

- (instancetype)initWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(ASCloudMapping *)mapping {
    if (self = [super init]) {
        _entityName = mapping.reverseMap[recordType] ?: recordType;
        _uniqueData = uniqueData;
    }
    return self;
}

@end

#pragma mark - ASCloudRecordRepresentation

@interface ASCloudRecordRepresentation : ASCloudDescriptionRepresentation <ASMappedObject>


@end

@implementation ASCloudRecordRepresentation {
    NSDate *_modificationDate;
    NSDictionary <NSString *, id <NSSecureCoding>> *_keyedDataProperties;
}

- (NSDate *)modificationDate {
    return _modificationDate
}

- (NSDictionary <NSString *, id <NSSecureCoding>> *)keyedDataProperties {
    return _keyedDataProperties;
}

+ (instancetype)instantiateWithCloudRecord:(ASCloudRecord *)cloudRecord mapping:(ASCloudMapping *)mapping {
    return [[self alloc] initWithCloudRecord:cloudRecord mapping:mapping];
}

- (instancetype)initWithCloudRecord:(ASCloudRecord *)cloudRecord mapping:(ASCloudMapping *)mapping {
    if (self = [super initWithRecordType:cloudRecord.recordType uniqueData:cloudRecord.uniqueData mapping:mapping]) {
        _modificationDate = cloudRecord.modificationDate;
        NSMutableDictionary <NSString *, id <NSSecureCoding>> *tmp_keyedDataProperties = [NSMutableDictionary new];
        NSMutableDictionary <NSString *, ASCloudReference *> *tmp_keyedReferences;
        NSMutableDictionary <NSString *, ASCloudReference *> *tmp_keyedReferences = [NSMutableDictionary new];
        NSMutableDictionary *tmp_keyedMultiReferences = [NSMutableDictionary new];
        for (NSString *key in self.allKeys) {
            if ([self[key] isKindOfClass:[CKReference class]]) {
                CKReference *ref = self[key];
                [tmp_keyedReferences setObject:ref.recordID.UUID.data forKey:key];
                continue;
            }
            if ([self[key] isKindOfClass:[NSArray class]] && [((NSArray *)self[key]).firstObject isKindOfClass:[CKReference class]]) {
                NSMutableArray <NSData *> *refList = [NSMutableArray new];
                for (CKReference *ref in (NSArray *)self[key]) {
                    [refList addObject:ref.recordID.UUID.data];
                }
                [tmp_keyedMultiReferences setObject:refList.copy forKey:key];
            }
            if (![key isEqualToString:kASCloudRealModificationDate]) {
                [tmp_keyedDataProperties setObject:self[key] forKey:key];
            }
        }
        _keyedDataProperties = tmp_keyedDataProperties.copy;
    }
    return self;
}

- (void)splitData {

}

@end



#pragma mark - ASCloudRecord

@implementation ASCloudRecord {

}

- (id <ASDescription>)descriptionOfDeletedObjectWithMapping:(ASCloudMapping *)mapping {
//    if (![self.recordType isEqualToString:kASCloudObjectDeletionInfoRecordType]) return nil;
    return [ASCloudDescriptionRepresentation instantiateWithRecordType:self[@"dq_recordType"] uniqueData:[NSUUID UUIDWithUUIDString:self[@"dq_recordID"]].data mapping:mapping];
}

- (id <ASMappedObject>)mappedObjectWithMapping:(ASCloudMapping *)mapping {
    return [ASCloudRecordRepresentation instantiateWithCloudRecord:self mapping:mapping];
}

+ (instancetype)recordWithRecordType:(NSString *)recordType recordID:(ASCloudID *)recordID {
    return [[super alloc] initWithRecordType:recordType recordID:recordID];
}

+ (instancetype)recordWithRecordType:(NSString *)recordType {
    return [[super alloc] initWithRecordType:recordType];
}

#pragma mark - getters

- (NSData *)uniqueData {
    return self.recordID.UUID.data;
}

- (NSDate *)modificationDate {
    return self[kASCloudRealModificationDate];
}

- (NSString *)entityName {
    @throw [NSException exceptionWithName:NSObjectInaccessibleException reason:nil userInfo:nil];
    return nil;
}

#pragma mark - setters

- (void)setModificationDate:(NSDate *)date {
    self[kASCloudRealModificationDate] = date;
}

- (void)setKeyedDataProperties:(NSDictionary <NSString *, id <NSSecureCoding>> *)keyedDataProperties {
    for (NSString *key in keyedDataProperties.allKeys) {
        self[key] = [keyedDataProperties[key] isKindOfClass:[NSNull class]] ? nil : keyedDataProperties[key];
    }
}

- (void)replaceRelation:(NSString *)relationKey toReference:(id<ASReference>)reference {
    CKReference *ckreference = [[CKReference alloc] initWithRecordID:[ASCloudReference referenceWithUniqueData:reference.uniqueData] action:nil];
    self[relationKey] = ckreference;
}

- (void)replaceRelation:(NSString *)relationKey toSetOfReferences:(NSSet <id<ASReference>> *)setOfReferences {
    NSMutableArray *tmpArray = [NSMutableArray new];
    for (id<ASReference> reference in setOfReferences) {
        CKReference *ckreference = [[CKReference alloc] initWithRecordID:[ASCloudReference referenceWithUniqueData:reference.uniqueData] action:nil];
        [tmpArray addObject:ckreference];
    }
    self[relationKey] = tmpArray.copy;
}


@end
