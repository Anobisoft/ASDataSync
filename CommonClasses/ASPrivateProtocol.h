//
//  ASPrivateProtocol.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//


@protocol ASRepresentableTransaction;
@protocol ASDataSyncContextPrivate;
@protocol ASCloudManager, ASCloudMappingProvider;
@protocol ASWatchConnector;

@protocol ASTransactionsAgregator;
@protocol ASWatchTransactionsAgregator;

@class ASCloudMapping;

#ifndef ASPrivateProtocol_h
#define ASPrivateProtocol_h

#import "ASPublicProtocol.h"
#import "ASCloudMapping.h"

#pragma mark - ASDataSyncContextPrivate protocol

@protocol ASRepresentableTransaction <NSObject>
@required

- (NSString *)contextIdentifier;
- (NSSet <NSObject <ASMappedObject> *> *)updatedObjects;
- (NSSet <NSObject <ASDescription> *> *)deletedObjects;

@end

@protocol ASDataSyncContextPrivate <ASRepresentableTransaction>
@required
- (void)performMergeWithTransaction:(id <ASRepresentableTransaction>)transaction;
- (void)setAgregator:(id<ASTransactionsAgregator>)agregator;
@end

#pragma mark - ASCloudManager protocol

@protocol ASCloudManager <ASTransactionsAgregator>
@required
- (void)setDataSyncContext:(id <ASDataSyncContextPrivate, ASCloudMappingProvider>)context;
- (void)acceptPushNotificationWithUserInfo:(NSDictionary *)userInfo;
- (void)smartReplication;
- (BOOL)ready;
@end

@protocol ASCloudMappingProvider <NSObject>
- (void)setCloudManager:(id<ASCloudManager>)cloudManager;
- (ASCloudMapping *)cloudMapping;

@end

#pragma mark - ASWatchConnector protocol

@protocol ASWatchConnector <NSObject>
- (void)setAgregator:(id<ASWatchTransactionsAgregator>)agregator;
- (BOOL)ready;
- (void)sendTransaction:(id <ASRepresentableTransaction, NSCoding>)transaction;
@end


#pragma mark - ASDataAgregator protocol

@protocol ASTransactionsAgregator <NSObject>
@required
- (void)willCommitTransaction:(id <ASRepresentableTransaction>)transaction;
@end

@protocol ASWatchTransactionsAgregator <NSObject>
@required
- (void)watchConnector:(id <ASWatchConnector>)connector didRecieveTransaction:(id <ASRepresentableTransaction>)transaction;
- (void)watchConnectorGetReady:(id <ASWatchConnector>)connector;
@end

#endif /* ASPrivateProtocol_h */
