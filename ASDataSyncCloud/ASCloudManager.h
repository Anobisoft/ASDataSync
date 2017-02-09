//
//  ASCloudManager.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>
#import "ASCloudMapping.h"

NS_ASSUME_NONNULL_BEGIN

@interface ASCloudManager : NSObject

@property (nonatomic, strong, readonly) NSString *instanceIdentifier;

+ (instancetype)instanceWithContainerIdentifier:(NSString *)identifier databaseScope:(CKDatabaseScope)databaseScope; //unique for identifier privateDB as default scope

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


@end

NS_ASSUME_NONNULL_END
