//
//  ASCloudManager.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASCloudMapping.h"
#import "ASPublicProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ASCloudManager : NSObject

@property (nonatomic, strong, readonly) NSString *instanceIdentifier;

+ (instancetype)instanceWithContainerIdentifier:(NSString *)identifier databaseScope:(ASDatabaseScope)databaseScope; //unique for identifier+databaseScope. ASDatabaseScopePrivate - default scope
- (void)totalReplication;
- (void)smartReplication;


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


@end

NS_ASSUME_NONNULL_END
