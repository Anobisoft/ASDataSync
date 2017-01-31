//
//  ASDataAgregator.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASPublicProtocol.h"

@interface ASDataAgregator : NSObject

- (void)addWatchSynchronizableContext:(id <ASDataSyncContext>)context;
- (void)setPrivateCloudContext:(id <ASDataSyncContext>)context;

+ (instancetype)defaultAgregator;

+ (instancetype)alloc NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

@end

