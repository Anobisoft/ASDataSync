//
//  ASCloudMapping.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef ASCloudMapping_h
#define ASCloudMapping_h

@interface ASCloudMapping : NSObject

- (NSString *)objectForKeyedSubscript:(NSString *)key;

+ (instancetype)mappingWithSynchronizableEntities:(NSArray <NSString *> *)entities;
+ (instancetype)mappingWithRecordTypeKeyedByEntityNameDictionary:(NSDictionary <NSString *, NSString *> *)dictionary;

- (NSDictionary *)map; //recordType keyed by entityName
- (NSDictionary *)reverseMap; //entityName keyed by recordType
- (NSSet <NSString *> *)synchronizableEntities; //all cloud-synchronizable entities

//mutable
- (void)mapRecordType:(NSString *)recordType withEntityName:(NSString *)entityName;
- (void)registerSynchronizableEntity:(NSString *)entityName;

@end

#endif
