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

#define kASCloudRealModificationDate @"changeDate"

@implementation CKRecordID(ASDataSync)


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
            [tmp_keyedProperties setObject:self[key] forKey:key];
        }
    }
    _keyedProperties = tmp_keyedProperties.copy;
    _keyedReferences = tmp_keyedReferences.copy;
    _keyedMultiReferences = tmp_keyedMultiReferences.copy;
}

#pragma mark - setters

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
