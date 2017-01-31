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

@interface ASCloudRecordRepresentation : ASCloudDescriptionRepresentation <ASMappedObject, ASRelatableToOne, ASRelatableToMany>


@end

@implementation ASCloudRecordRepresentation {
    NSDate *_modificationDate;
    NSDictionary <NSString *, NSObject <NSCoding> *> *_keyedDataProperties;
    NSDictionary <NSString *, id<ASReference>> *_keyedReferences;
    NSDictionary <NSString *, NSSet <id<ASReference>> *> *_keyedSetsOfReferences;
}

+ (NSDictionary<NSString *,NSString *> *)entityNameByRelationKey {
    return nil;
}

- (NSDate *)modificationDate {
    return _modificationDate;
}

- (NSDictionary <NSString *, NSObject <NSCoding> *> *)keyedDataProperties {
    return _keyedDataProperties;
}

- (NSDictionary <NSString *, id<ASReference>> *)keyedReferences {
    return _keyedReferences;
}

- (NSDictionary <NSString *, NSSet <id<ASReference>> *> *)keyedSetsOfReferences {
    return _keyedSetsOfReferences;
}

+ (instancetype)instantiateWithCloudRecord:(ASCloudRecord *)cloudRecord mapping:(ASCloudMapping *)mapping {
    return [[self alloc] initWithCloudRecord:cloudRecord mapping:mapping];
}

- (instancetype)initWithCloudRecord:(ASCloudRecord *)cloudRecord mapping:(ASCloudMapping *)mapping {
    if (self = [super initWithRecordType:cloudRecord.recordType uniqueData:cloudRecord.uniqueData mapping:mapping]) {
        _modificationDate = cloudRecord.modificationDate;
        NSMutableDictionary <NSString *, NSObject <NSCoding> *> *tmp_keyedDataProperties = [NSMutableDictionary new];
        NSMutableDictionary <NSString *, ASCloudReference *> *tmp_keyedReferences = [NSMutableDictionary new];
        NSMutableDictionary <NSString *, NSSet <ASCloudReference *> *> *tmp_keyedSetsOfReferences = [NSMutableDictionary new];
        for (NSString *key in cloudRecord.allKeys) {
            if ([cloudRecord[key] isKindOfClass:[CKReference class]]) {
                ASCloudReference *reference = cloudRecord[key];
                [tmp_keyedReferences setObject:reference forKey:key];
                continue;
            }
            if ([cloudRecord[key] isKindOfClass:[NSArray class]] && [((NSArray *)cloudRecord[key]).firstObject isKindOfClass:[CKReference class]]) {
                NSMutableSet <ASCloudReference *> *refList = [NSMutableSet new];
                for (ASCloudReference *reference in (NSArray *)cloudRecord[key]) {
                    [refList addObject:reference];
                }
                [tmp_keyedSetsOfReferences setObject:refList.copy forKey:key];
            }
            if (![key isEqualToString:kASCloudRealModificationDate]) {
                [tmp_keyedDataProperties setObject:cloudRecord[key] forKey:key];
            }
        }
        _keyedDataProperties = tmp_keyedDataProperties.copy;
        _keyedReferences = tmp_keyedReferences.copy;
        _keyedSetsOfReferences = tmp_keyedSetsOfReferences.copy;
    }
    return self;
}

@end


#pragma mark - ASCloudRecord

@implementation ASCloudRecord {
    NSDictionary *keyedProperties;
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

- (NSDictionary<NSString *, NSObject <NSCoding> *> *)keyedDataProperties {
    if (!keyedProperties) {
        NSMutableDictionary *tmp = [NSMutableDictionary new];
        for (NSString *key in self.allKeys) {
            [tmp setObject:self[key] forKey:key];
        }
        keyedProperties = tmp.copy;
    }
    return keyedProperties;
}

#pragma mark - setters

- (void)setModificationDate:(NSDate *)date {
    self[kASCloudRealModificationDate] = date;
}

- (void)setKeyedDataProperties:(NSDictionary <NSString *, NSObject <NSCoding> *> *)keyedDataProperties {
    for (NSString *key in keyedDataProperties.allKeys) {
        self[key] = [keyedDataProperties[key] isKindOfClass:[NSNull class]] ? nil : (__kindof id <CKRecordValue>)keyedDataProperties[key];
    }
}

- (void)replaceRelation:(NSString *)relationKey toReference:(id<ASReference>)reference {
    self[relationKey] = [ASCloudReference referenceWithUniqueData:reference.uniqueData];
}

- (void)replaceRelation:(NSString *)relationKey toSetsOfReferences:(NSSet <id<ASReference>> *)setOfReferences {
    NSMutableArray *tmpArray = [NSMutableArray new];
    for (id<ASReference> reference in setOfReferences) {
        [tmpArray addObject:[ASCloudReference referenceWithUniqueData:reference.uniqueData]];
    }
    self[relationKey] = tmpArray.copy;
}


@end
