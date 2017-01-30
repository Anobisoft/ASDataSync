//
//  ASCloudMapping.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASCloudMapping.h"

@implementation ASCloudMapping {
    NSMutableDictionary *mutableMap;
    NSMutableDictionary *mutableReverseMap;
    NSMutableSet *mutableSynchronizableEntities;
}

- (instancetype)init {
    if (self = [super init]) {
        mutableMap = [NSMutableDictionary new];
        mutableSynchronizableEntities = [NSMutableSet new];
    }
    return self;
}

+ (instancetype)mappingWithSynchronizableEntities:(NSArray <NSString *> *)entities {
    return [[super alloc] initWithArray:entities];
}


- (instancetype)initWithArray:(NSArray <NSString *> *)array {
    if (self = [self init]) {
        mutableSynchronizableEntities = [NSMutableSet setWithArray:array];
    }
    return self;
}

+ (instancetype)mappingWithRecordTypeKeyedByEntityNameDictionary:(NSDictionary <NSString *, NSString *> *)dictionary {
    return [[super alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSString *> *)dictionary {
    if (self = [self init]) {
        mutableMap = dictionary.mutableCopy;
        [self reverseRecreate];
    }
    return self;
}


- (NSDictionary<NSString *,NSString *> *)map {
    return mutableMap.copy;
}

- (NSDictionary<NSString *,NSString *> *)reverseMap {
    if (!mutableReverseMap) [self reverseRecreate];
    return mutableReverseMap.copy;
}

- (NSSet<NSString *> *)synchronizableEntities {
    return mutableSynchronizableEntities.copy;
}

- (void)reverseRecreate {
    mutableReverseMap = [NSMutableDictionary new];
    for (NSString *key in mutableMap.allKeys) {
        mutableReverseMap[mutableMap[key]] = key;
    }
}

- (void)mapRecordType:(NSString *)recordType withEntityName:(NSString *)entityName {
    if ([recordType isEqualToString:entityName]) {
        [self registerSynchronizableEntity:entityName];
    } else {
        if ([mutableSynchronizableEntities containsObject:entityName]) [mutableSynchronizableEntities removeObject:entityName];
        
        mutableMap[entityName] = recordType;
        if (!mutableReverseMap) [self reverseRecreate];
        else mutableReverseMap[recordType] = entityName;
    }
}

- (void)registerSynchronizableEntity:(NSString *)entityName {
    [mutableSynchronizableEntities addObject:entityName];
    if ([mutableMap.allKeys containsObject:entityName]) {
        [mutableMap removeObjectForKey:entityName];
        [self reverseRecreate];
        if ([mutableReverseMap.allKeys containsObject:entityName]) NSLog(@"ERROR: MAPPING CONSTRAINTS CONFLICT");
    }
}

@end
