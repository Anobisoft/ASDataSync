//
//  ASCloudManager.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ASDataSync/ASDataSync.h>
#import "ASMapping.h"

NS_ASSUME_NONNULL_BEGIN

@interface ASCloudManager : NSObject <ASDataSyncAgregator>

@property (nullable, nonatomic, strong, readonly) ASMapping *mapping;

+ (instancetype)defaultManager;
- (void)initContainerWithIdentifier:(NSString *)identifier withEntityMapping:(ASMapping *)mapping;
- (BOOL)ready;

- (void)setContext:(id <ASynchronizableContext>)context;
- (void)acceptPushNotificationWithUserInfo:(NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
