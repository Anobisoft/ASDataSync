//
//  ASCloudRecordRepresentation.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "ASCloudRecordRepresentation.h"
#import <CloudKit/CloudKit.h>
#import "CKRecord+ASDataSync.h"
#import "ASCloudInternalConst.h"

@interface ASCloudDescriptionRepresentation(protected)

- (instancetype)initWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(ASCloudMapping *)mapping;

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

+ (instancetype)instantiateWithCloudRecord:(CKRecord<ASMappedObject> *)cloudRecord mapping:(ASCloudMapping *)mapping {
    return [[self alloc] initWithCloudRecord:cloudRecord mapping:mapping];
}

- (instancetype)initWithCloudRecord:(CKRecord<ASMappedObject> *)cloudRecord mapping:(ASCloudMapping *)mapping {
    if (self = [super initWithRecordType:cloudRecord.recordType uniqueData:cloudRecord.uniqueData mapping:mapping]) {
        _modificationDate = cloudRecord.modificationDate;
        NSMutableDictionary <NSString *, NSObject <NSCoding> *> *tmp_keyedDataProperties = [NSMutableDictionary new];
        NSMutableDictionary <NSString *, CKReference<ASReference> *> *tmp_keyedReferences = [NSMutableDictionary new];
        NSMutableDictionary <NSString *, NSSet <CKReference<ASReference> *> *> *tmp_keyedSetsOfReferences = [NSMutableDictionary new];
        for (NSString *key in cloudRecord.allKeys) {
            if ([cloudRecord[key] isKindOfClass:[CKReference class]]) {
                CKReference<ASReference> *reference = cloudRecord[key];
                [tmp_keyedReferences setObject:reference forKey:key];
                continue;
            }
            if ([cloudRecord[key] isKindOfClass:[NSArray class]] && [((NSArray *)cloudRecord[key]).firstObject isKindOfClass:[CKReference class]]) {
                NSMutableSet <CKReference<ASReference> *> *refList = [NSMutableSet new];
                for (CKReference<ASReference> *reference in (NSArray *)cloudRecord[key]) {
                    [refList addObject:reference];
                }
                [tmp_keyedSetsOfReferences setObject:refList.copy forKey:key];
            }
            if (![key isEqualToString:ASCloudRealModificationDateProperty]) {
                [tmp_keyedDataProperties setObject:cloudRecord[key] forKey:key];
            }
        }
        _keyedDataProperties = tmp_keyedDataProperties.copy;
        _keyedReferences = tmp_keyedReferences.copy;
        _keyedSetsOfReferences = tmp_keyedSetsOfReferences.copy;
        
//        NSLog(@"[DEBUG] _keyedDataProperties %@", _keyedDataProperties);
//        NSLog(@"[DEBUG] _keyedReferences %@", _keyedReferences);
//        NSLog(@"[DEBUG] _keyedSetsOfReferences %@", _keyedSetsOfReferences);
    }
    return self;
}


@end
