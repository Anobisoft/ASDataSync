//
//  ASMapping.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASMapping : NSObject

+ (instancetype)mappingWithSynchronizableEntities:(NSArray <NSString *> *)entities;
+ (instancetype)mappingWithRecordTypeKeyedByEntityNameDictionary:(NSDictionary <NSString *, NSString *> *)dictionary;

- (void)mapWithRecordType:(NSString *)recordType entityName:(NSString *)entityName;

@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSString *> *map;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSString *> *reverseMap;

@end

