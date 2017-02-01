//
//  ASCloudMapping.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASCloudMapping.h"
#import <objc/runtime.h>

//@interface NSDictionary (mapping)
//
//
//@end
//
//@implementation NSDictionary(mapping)
//
//+ (void)initialize {
//    [super initialize];
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        Class class = NSDictionary.class;
//        SEL originalSelector = @selector(objectForKeyedSubscript:);
//        SEL swizzledSelector = @selector(objectOKForKey:);
//        
//        Method originalMethod = class_getInstanceMethod(class, originalSelector);
//        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
//        
//        BOOL didAddMethod =
//        class_addMethod(class,
//                        originalSelector,
//                        method_getImplementation(swizzledMethod),
//                        method_getTypeEncoding(swizzledMethod));
//        
//        if (didAddMethod) {
//            class_replaceMethod(class,
//                                swizzledSelector,
//                                method_getImplementation(originalMethod),
//                                method_getTypeEncoding(originalMethod));
//        } else {
//            method_exchangeImplementations(originalMethod, swizzledMethod);
//        }
//    });
//
//}
//
//- (id)objectOKForKey:(id)aKey {
//    id object = [self objectOKForKey:aKey];
//    NSLog(@"swizzled object %@ aKey %@", object, aKey);
//    if (!object && [aKey isKindOfClass:NSString.class]) {
//        return aKey;
//    }
//    return object;
//}
//
//@end

@implementation ASCloudMapping {
    NSMutableDictionary *mutableMap;
    NSMutableDictionary *mutableReverseMap;
    NSMutableSet *mutableSynchronizableEntities;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
    return self.map[key] ?: self.reverseMap[key] ?: key;
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
    [self registerSynchronizableEntity:entityName];
    if (![recordType isEqualToString:entityName]) {
        mutableMap[entityName] = recordType;
        if (!mutableReverseMap) [self reverseRecreate];
        else mutableReverseMap[recordType] = entityName;
    }
}

- (void)registerSynchronizableEntity:(NSString *)entityName {
    [mutableSynchronizableEntities addObject:entityName];
}

@end
