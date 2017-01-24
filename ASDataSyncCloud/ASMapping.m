//
//  ASMapping.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASMapping.h"
#import "ASDevice.h"

@implementation ASMapping {
    NSMutableDictionary *mutableMap;
    NSMutableDictionary *mutableReverseMap;
}

+ (instancetype)mappingWithSynchronizableEntities:(NSArray <NSString *> *)entities {
    return [[super alloc] initWithArray:entities];
}

- (instancetype)initWithArray:(NSArray <NSString *> *)array {
    if (self = [super init]) {
        mutableMap = [NSMutableDictionary new];
        [mutableMap setValue:[ASDevice entityName] forKey:[ASDevice entityName]];
        for (NSString *entityName in array) {
            [mutableMap setObject:entityName forKey:entityName];
        }
        mutableReverseMap = mutableMap;
        _map = _reverseMap = mutableMap.copy;
    }
    return self;
}

+ (instancetype)mappingWithRecordTypeKeyedByEntityNameDictionary:(NSDictionary <NSString *, NSString *> *)dictionary {
    return [[super alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSString *> *)dictionary {
    if (self = [super init]) {
        mutableMap = dictionary.mutableCopy;
        [mutableMap setValue:[ASDevice entityName] forKey:[ASDevice entityName]];
        _map = mutableMap.copy;
        mutableReverseMap = [NSMutableDictionary new];
        for (NSString *key in _map.allKeys) {
            [mutableReverseMap setObject:key forKey:_map[key]];
        }
        _reverseMap = mutableReverseMap.copy;
    }
    return self;
}

@end
