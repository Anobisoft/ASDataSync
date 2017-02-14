//
//  ASDataAgregator.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASPublicProtocol.h"

@protocol ASDataSyncContextPrivate, ASCloudMappingProvider;

@interface ASDataAgregator : NSObject

- (void)addWatchSynchronizableContext:(id <ASDataSyncContext>)context;
- (void)setCloudContext:(id <ASDataSyncContextPrivate, ASCloudMappingProvider>)context containerIdentifier:(NSString *)containerIdentifier databaseScope:(ASDatabaseScope)databaseScope __WATCHOS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

+ (instancetype)defaultAgregator;

@end

