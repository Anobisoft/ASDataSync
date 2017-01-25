//
//  ASMapping.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASMapping.h"

@implementation ASMapping {
    NSMutableDictionary *mutableMap;
    NSMutableDictionary *mutableReverseMap;
}

+ (instancetype)mappingWithSynchronizableEntities:(NSArray <NSString *> *)entities {
    return [[super alloc] initWithArray:entities];
}

- (instancetype)init {
    if (self = [super init]) {
        mutableReverseMap = [NSMutableDictionary new];
    }
    return self;
}

- (instancetype)initWithArray:(NSArray <NSString *> *)array {
    if (self = [self init]) {
        mutableMap = [NSMutableDictionary new];
        for (NSString *entityName in array) {
            [mutableMap setObject:entityName forKey:entityName];
        }
    }
    return self;
}

+ (instancetype)mappingWithRecordTypeKeyedByEntityNameDictionary:(NSDictionary <NSString *, NSString *> *)dictionary {
    return [[super alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSString *> *)dictionary {
    if (self = [self init]) {
        mutableMap = dictionary.mutableCopy;
    }
    return self;
}


- (NSDictionary<NSString *,NSString *> *)map {
    return mutableMap.copy;
}

- (NSDictionary<NSString *,NSString *> *)reverseMap {
    if (!mutableReverseMap) {
        for (NSString *key in mutableMap.allKeys) {
            [mutableReverseMap setObject:key forKey:mutableMap[key]];
        }
    }
    return mutableReverseMap.copy;
}

- (id)mutableCopy {
    return (ASMutableMapping *)self;
}

- (void)mapRecordType:(NSString *)recordType withEntityName:(NSString *)entityName {
    mutableMap[entityName] = recordType;
    mutableReverseMap[recordType] = entityName;
}

@end

@implementation ASMutableMapping

- (id)copy {
    return (ASMapping *)self;
}

@end
