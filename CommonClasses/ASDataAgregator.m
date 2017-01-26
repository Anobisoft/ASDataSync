//
//  ASDataAgregator.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASDataAgregator.h"
#import "ASPrivateProtocol.h"
#import "ASWatchConnector.h"
#import "ASCloudManager.h"

@interface ASDataAgregator() <ASWatchDataAgregator, ASContextDataAgregator>
@property (nonatomic, weak) id<ASWatchConnector> watchConnector;
@property (nonatomic, weak) id<ASCloudManager> cloudManager;
@end

@implementation ASDataAgregator {
    NSMutableSet <id<ASWatchSynchronizableContext>> *watchContextSet;
    id<ASCloudSynchronizableContext> cloudPrivateDBContext;
    ASMutableMapping *autoMapping;
}

- (id<ASCloudManager>)cloudManager {
    if (!_cloudManager) {
        _cloudManager = (id<ASCloudManager>)[ASCloudManager defaultManager];
    }
    return _cloudManager;
}

+ (instancetype)new {
    return [self defaultAgregator];
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

+ (instancetype)defaultAgregator {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

- (instancetype)initUniqueInstance {
    if (self = [super init]) {
        self.watchConnector = (id<ASWatchConnector>)ASWatchConnector.sharedInstance;
        [self.watchConnector setAgregator:self];
        watchContextSet = [NSMutableSet new];
#warning UNCOMPLETED reload "replication needed" status
    }
    return self;
}

- (void)willCommitContext:(id<ASynchronizableContextPrivate>)context {
    if ([watchContextSet containsObject:(id<ASWatchSynchronizableContext>)context]) {
        ASerializableContext *serializedContext = [ASerializableContext instantiateWithSynchronizableContext:context];
        if (_watchConnector) {
            if (_watchConnector.ready) {
                if (![_watchConnector sendContext:serializedContext]) {
#warning UNCOMPLETED some error on sending context. throw exception? try to send another way?
                    //                [self enqueueSerializedContext:serializedContext];
                }
            } else {
                NSLog(@"[WARNING] %s : watchConnector is not ready", __PRETTY_FUNCTION__);
            }
        }
    }
    if (context == cloudPrivateDBContext) {
        if (self.cloudManager.ready) {
            [self.cloudManager willCommitContext:context];
        } else {
            NSLog(@"[ERROR] ASCloudManager is not ready. ");
        }
    }
}

- (void)watchConnectorGetReady:(id<ASWatchConnector>)connector {
#warning UNCOMPLETED Start full replication if connector ready and replication needed.
}

- (void)watchConnector:(ASWatchConnector *)connector didRecieveContext:(ASerializableContext *)context {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s : <%@>", __PRETTY_FUNCTION__, context.identifier);
#endif
    for (id<ASWatchSynchronizableContext> cc in watchContextSet) {
        if ([cc.identifier isEqualToString:context.identifier]) {
            [cc performMergeWithRecievedContext:context];
            return ;
        }
    }
    NSLog(@"[ERROR] %s : context <%@> not found", __PRETTY_FUNCTION__, context.identifier);
}

- (void)addWatchSynchronizableContext:(id<ASWatchSynchronizableContext>)context {
    [watchContextSet addObject:context];
    [context setAgregator:self];
#warning UNCOMPLETED Start full replication if connector ready and replication needed.
}

- (void)setPrivateCloudContext:(id<ASCloudSynchronizableContext>)context {
    cloudPrivateDBContext = context;
    [context setAgregator:self];
    [self.cloudManager setCloudSynchronizableContext:context];
}

@end
