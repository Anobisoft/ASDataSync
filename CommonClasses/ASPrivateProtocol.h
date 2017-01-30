//
//  ASPrivateProtocol.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//


@protocol ASRepresentableTransaction;
@protocol ASDataSyncContextPrivate;
@protocol ASCloudManager;
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
- (NSSet <id <ASMappedObject>> *)updatedObjects;
- (NSSet <id <ASDescription>> *)deletedObjects;

@end

@protocol ASDataSyncContextPrivate <ASRepresentableTransaction>
@required
- (void)performMergeWithTransaction:(id <ASRepresentableTransaction>)transaction;
- (void)setAgregator:(id<ASTransactionsAgregator>)agregator;
@end

#pragma mark - ASCloudManager protocol

@protocol ASCloudManager <ASTransactionsAgregator>
@required
@property (nonatomic, strong, readonly) ASCloudMapping *mapping;

- (void)setDataSyncContext:(id <ASDataSyncContextPrivate>)context;
- (BOOL)ready;

@end

#pragma mark - ASWatchConnector protocol

@protocol ASWatchConnector <NSObject>
- (void)sendTransaction:(id <ASRepresentableTransaction, NSSecureCoding>)transaction;
- (BOOL)ready;
- (void)setAgregator:(id<ASWatchTransactionsAgregator>)agregator;
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
