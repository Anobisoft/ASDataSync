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
@end

@implementation ASDataAgregator {
    NSMutableSet <id<ASDataSyncContextPrivate>> *watchContextSet;
    NSMutableDictionary <NSString *, id<ASCloudManager>> *cloudManagers;
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
        cloudManagers = [NSMutableDictionary new];
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
    id<ASCloudManager> cloudManager = cloudManagers[transaction.contextIdentifier];
    if (cloudManager) {
        [cloudManager willCommitTransaction:transaction];
    }
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

//- (void)context:(id <ASDataSyncContextPrivate>)context recievedPushNotificationWithUserInfo:(NSDictionary *)userInfo {
//    id<ASCloudManager> cloudManager = cloudManagers[context.contextIdentifier];
//    if (cloudManager) {
//        [cloudManager acceptPushNotificationWithUserInfo:userInfo];
//    } else {
//        @throw [NSException exceptionWithName:NSPortReceiveException reason:nil userInfo:nil];
//    }
//}

- (void)addWatchSynchronizableContext:(id<ASDataSyncContextPrivate>)context {
    [watchContextSet addObject:context];
    [context setAgregator:self];
#warning UNCOMPLETED Start full replication if connector ready and replication needed.
}

- (void)setPrivateCloudContext:(id <ASDataSyncContextPrivate, ASCloudMappingProvider>)context forCloudContainerIdentifier:(NSString *)containerIdentifier; {
    id<ASCloudManager> cloudManager = cloudManagers[context.contextIdentifier];
    if (!cloudManager) {
#ifdef DEBUG
        cloudManager = (id<ASCloudManager>)[ASCloudManager instanceWithContainerIdentifier:containerIdentifier databaseScope:ASDatabaseScopePublic];
#else
        cloudManager = (id<ASCloudManager>)[ASCloudManager instanceWithContainerIdentifier:containerIdentifier databaseScope:ASDatabaseScopePrivate];
#endif
        cloudManagers[context.contextIdentifier] = cloudManager;
    }
    [context setAgregator:self];
    [context setCloudManager:cloudManager];
    [cloudManager setDataSyncContext:context];
}



@end
