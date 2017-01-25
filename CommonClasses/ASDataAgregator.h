//
//  ASDataAgregator.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASPublicProtocol.h"
#import "ASWatchConnector.h"


@interface ASDataAgregator : NSObject

- (void)addWatchSynchronizableContext:(id <ASynchronizableContext>)context;
- (void)setPrivateCloudContext:(id <ASynchronizableContext>)context;

@property (nonatomic, weak, readonly) ASWatchConnector *watchConnector;

+ (instancetype)defaultAgregator;

+ (instancetype)alloc NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

@end

