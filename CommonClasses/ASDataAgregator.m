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
#import "ASTransactionRepresentation.h"

@interface ASDataAgregator() <ASWatchTransactionsAgregator, ASTransactionsAgregator>
@property (nonatomic, weak) id<ASWatchConnector> watchConnector;
@property (nonatomic, weak) id<ASCloudManager> cloudManager;
@end

@implementation ASDataAgregator {
    NSMutableSet <id<ASDataSyncContextPrivate>> *watchContextSet;
    id<ASDataSyncContextPrivate> privateCloudContext;
    ASCloudMapping *autoMapping;
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

- (void)willCommitTransaction:(id <ASRepresentableTransaction>)transaction {
    if ([watchContextSet containsObject:transaction]) {
        ASTransactionRepresentation *transactionRepresentation = [ASTransactionRepresentation instantiateWithRepresentableTransaction:transaction];
        if (_watchConnector) {
            if (_watchConnector.ready) {
                [_watchConnector sendTransaction:transactionRepresentation];
            } else {
                NSLog(@"[WARNING] %s : watchConnector is not ready", __PRETTY_FUNCTION__);
            }
        }
    }
    if (context == privateCloudContext) {
        if (self.cloudManager.ready) {
            [self.cloudManager willCommitTransaction:transaction];
        } else {
            NSLog(@"[ERROR] ASCloudManager is not ready. ");
        }
    }
}

- (void)watchConnectorGetReady:(id<ASWatchConnector>)connector {
#warning UNCOMPLETED Start full replication if connector ready and replication needed.
}

- (void)watchConnector:(ASWatchConnector *)connector didRecieveContext:(ASTransactionRepresentation *)context {
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

- (void)setPrivateCloudContext:(id<ASDataSyncContextPrivate>)context {
    cloudPrivateDBContext = context;
    [context setAgregator:self];
    [self.cloudManager setDataSyncContext:context];
}

@end
