//
//  ASCloudRecord.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASCloudRecord.h"

#define kASCloudRealModificationDate @"changeDate"

@implementation CKRecordID(ASDataSync)

+ (instancetype)recordIDWithUniqueData:(NSData *)uniqueData {
    return [[super alloc] initWithRecordName:uniqueData.UUIDString];
}

+ (instancetype)recordIDWithRecordName:(NSString *)recordName {
    return [[super alloc] initWithRecordName:recordName];
}

- (NSUUID *)UUID {
    return [[NSUUID alloc] initWithUUIDString:self.recordName];
}

@end

@implementation ASCloudRecord {

}

@synthesize keyedProperties = _keyedProperties;
@synthesize keyedReferences = _keyedReferences;
@synthesize keyedMultiReferences = _keyedMultiReferences;

+ (instancetype)recordWithRecordType:(NSString *)recordType recordID:(CKRecordID *)recordID {
    return [[super alloc] initWithRecordType:recordType recordID:recordID];
}

#pragma mark - getters

- (NSData *)uniqueData {
    return self.recordID.UUID.data;
}

- (NSDate *)modificationDate {
    return self[kASCloudRealModificationDate];
}

- (NSDictionary *)keyedProperties {
    if (!_keyedProperties) [self splitData];
    return _keyedProperties;
}

- (NSDictionary <NSString *, CKReference *> *)keyedReferences {
    if (!_keyedReferences) [self splitData];
    return _keyedReferences;
}

- (NSDictionary <NSString *, NSArray<CKReference *> *> *)keyedMultiReferences {
    if (!_keyedMultiReferences) [self splitData];
    return _keyedMultiReferences;
}

- (void)splitData {
    NSMutableDictionary *tmp_keyedProperties = [NSMutableDictionary new];
    NSMutableDictionary *tmp_keyedReferences = [NSMutableDictionary new];
    NSMutableDictionary *tmp_keyedMultiReferences = [NSMutableDictionary new];
    for (NSString *key in self.allKeys) {
        if ([self[key] isKindOfClass:[CKReference class]]) {
            [tmp_keyedReferences setObject:self[key] forKey:key];
            continue;
        }
        if ([self[key] isKindOfClass:[NSArray class]] && [((NSArray *)self[key]).firstObject isKindOfClass:[CKReference class]]) {
            [tmp_keyedMultiReferences setObject:self[key] forKey:key];
        }
        if (![key isEqualToString:kASCloudRealModificationDate]) {
            [tmp_keyedProperties setObject:self[key] forKey:key];
        }
    }
    _keyedProperties = tmp_keyedProperties.copy;
    _keyedReferences = tmp_keyedReferences.copy;
    _keyedMultiReferences = tmp_keyedMultiReferences.copy;
}

#pragma mark - setters

- (void)setUniqueData:(NSData *)uniqueData {
    NSLog(@"[ERROR] readonly property. Use +recordWithRecordType:recordID: method to get instance with uniqueData");
}

- (void)setModificationDate:(NSDate *)date {
    self[kASCloudRealModificationDate] = date;
}

- (void)setKeyedProperties:(NSDictionary *)keyedProperties {
    for (NSString *key in keyedProperties.allKeys) {
        self[key] = keyedProperties[key];
    }
}

- (void)setKeyedReferences:(NSDictionary<NSString *, CKReference *> *)keyedReferences {
    self[key] = keyedReferences;
}


@end
