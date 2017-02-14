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
#import "ASTransactionRepresentation.h"

#import "ASCloudManager.h"

@interface ASDataAgregator() <ASWatchTransactionsAgregator, ASTransactionsAgregator>
@property (nonatomic, weak) id<ASWatchConnector> watchConnector;
@end

@implementation ASDataAgregator {
    NSMutableSet <id<ASDataSyncContextPrivate>> *watchContextSet;
#if TARGET_OS_IOS
    NSMutableDictionary <NSString *, id<ASCloudManager>> *cloudManagers[4];
#endif
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
        shared = [[self alloc] initUniqueInstance];
    });
    return shared;
}

- (instancetype)initUniqueInstance {
    if (self = [super init]) {
        self.watchConnector = (id<ASWatchConnector>)ASWatchConnector.sharedInstance;
        [self.watchConnector setAgregator:self];
        watchContextSet = [NSMutableSet new];
#warning UNCOMPLETED reload "replication needed" status
#if TARGET_OS_IOS
        cloudManagers[0] = cloudManagers[ASDatabaseScopePrivate] = [NSMutableDictionary new];
        cloudManagers[ASDatabaseScopePublic] = [NSMutableDictionary new];
        cloudManagers[ASDatabaseScopeShared] = nil;
#endif
    }
    return self;
}

- (void)willCommitTransaction:(id <ASRepresentableTransaction>)transaction {
    if ([watchContextSet containsObject:(id <ASDataSyncContextPrivate>)transaction]) {
        ASTransactionRepresentation *transactionRepresentation = [ASTransactionRepresentation instantiateWithRepresentableTransaction:transaction];
        if (_watchConnector) {
            if (_watchConnector.ready) {
                [_watchConnector sendTransaction:transactionRepresentation];
            } else {
                NSLog(@"[WARNING] %s : watchConnector is not ready", __PRETTY_FUNCTION__);
            }
        }
    }
#if TARGET_OS_IOS
    for (int i = 0; i < 4; i++) {
        id<ASCloudManager> cloudManager = cloudManagers[i][transaction.contextIdentifier];
        if (cloudManager) {
            [cloudManager willCommitTransaction:transaction];
        }
    }
#endif
}

- (void)watchConnectorGetReady:(id<ASWatchConnector>)connector {
#warning UNCOMPLETED Start full replication if connector ready and replication needed.
}

- (void)watchConnector:(ASWatchConnector *)connector didRecieveTransaction:(id<ASRepresentableTransaction>)transaction {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s : <%@>", __PRETTY_FUNCTION__, transaction.contextIdentifier);
#endif
    for (id<ASDataSyncContextPrivate> cc in watchContextSet) {
        if ([cc.contextIdentifier isEqualToString:transaction.contextIdentifier]) {
            [cc performMergeWithTransaction:transaction];
            return ;
        }
    }
    NSLog(@"[ERROR] %s : context <%@> not found", __PRETTY_FUNCTION__, transaction.contextIdentifier);
}

- (void)addWatchSynchronizableContext:(id<ASDataSyncContextPrivate>)context {
    [watchContextSet addObject:context];
    [context setAgregator:self];
#warning UNCOMPLETED Start full replication if connector ready and replication needed.
}

#if TARGET_OS_IOS
- (void)setCloudContext:(id <ASDataSyncContextPrivate, ASCloudMappingProvider>)context containerIdentifier:(NSString *)containerIdentifier databaseScope:(ASDatabaseScope)databaseScope {
    id<ASCloudManager> cloudManager = cloudManagers[databaseScope][context.contextIdentifier];
    if (!cloudManager) {
        cloudManager = (id<ASCloudManager>)[ASCloudManager instanceWithContainerIdentifier:containerIdentifier databaseScope:databaseScope];
        cloudManagers[databaseScope][context.contextIdentifier] = cloudManager;
    }
    [context setAgregator:self];
    [context setCloudManager:cloudManager];
    [cloudManager setDataSyncContext:context];
}
#endif


@end
