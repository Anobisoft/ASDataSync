//
//  ASMapping.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASMutableMapping;

@interface ASMapping : NSObject

+ (instancetype)mappingWithSynchronizableEntities:(NSArray <NSString *> *)entities;
+ (instancetype)mappingWithRecordTypeKeyedByEntityNameDictionary:(NSDictionary <NSString *, NSString *> *)dictionary;

@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSString *> *map;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSString *> *reverseMap;

@end


@interface ASMutableMapping : ASMapping

- (void)mapRecordType:(NSString *)recordType withEntityName:(NSString *)entityName;

@end
