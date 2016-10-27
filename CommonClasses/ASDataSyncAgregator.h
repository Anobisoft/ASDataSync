//
//  ASDataSyncAgregator.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASynchronizable.h"
#import "ASWatchConnector.h"


@interface ASDataSyncAgregator : NSObject <ASWatchConnectorDelegate>

@property (nonatomic, weak, readonly) ASWatchConnector *watchConnector;
- (void)addSynchronizableContext:(id <ASynchronizableContext>)context;
- (void)recieverStart;
- (void)recieverStop;

- (void)commitAll;
- (void)rollbackAll;

+ (instancetype)defaultAgregator;

+ (instancetype)alloc NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

@end

