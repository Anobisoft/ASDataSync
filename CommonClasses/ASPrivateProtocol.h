//
//  ASPrivateProtocol.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

@protocol ASDataAgregatorInteracting;
@protocol ASynchronizableContextPrivate;
@protocol ASCloudContext;
@protocol ASWatchConnector;
@protocol ASContextDataAgregator;
@protocol ASWatchDataAgregator;
@protocol ASCloudDataAgregator;

#ifndef ASPrivateProtocol.h
#define ASPrivateProtocol.h

#import "ASerializableContext.h"
#import "ASPublicProtocol.h"

@protocol ASDataAgregatorInteracting <NSObject>
@required
- (void)setAgregator:(id<ASDataAgregator>)agregator;
@end


#pragma mark - ASynchronizableContextPrivate protocol

@protocol ASynchronizableContextPrivate <ASynchronizableContext, ASDataAgregatorInteracting>
@required

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSSet <id <ASynchronizableObject>> *updatedObjects;
@property (nonatomic, strong, readonly) NSSet <id <ASynchronizableDescription>> *deletedObjects;

- (void)performMergeWithRecievedContext:(ASerializableContext *)recievedContext;

@end


#pragma mark - ASCloudContext protocol

@protocol ASCloudContext <ASDataAgregatorInteracting>
@required

@property (nonatomic, strong, readonly) NSSet <id <ASCloudRelatableRecord>> *updatedRecords;
@property (nonatomic, strong, readonly) NSSet <id <ASCloudDescription>> *deletionInfoRecords;

- (void)updateWithSynchronizableContext:(id <ASynchronizableContext>)context;
- (BOOL)ready;

@end


#pragma mark - ASWatchConnector protocol

@protocol ASWatchConnector <ASDataAgregatorInteracting>
- (BOOL)sendContext:(ASerializableContext *)context;
- (BOOL)ready;
@end


#pragma mark - ASDataAgregator protocol

@protocol ASContextDataAgregator <NSObject>
@required
- (void)willCommitContext:(id <ASynchronizableContext>)context;
@end

@protocol ASWatchDataAgregator <NSObject>
@required
- (void)watchConnector:(id <ASWatchConnector>)connector didRecieveContext:(ASerializableContext *)context;
- (void)watchConnectorGetReady:(id <ASWatchConnector>)connector;
@end

@protocol ASCloudDataAgregator <NSObject>
@required
- (void)didRecievedCloudContext:(id <ASCloudContext>)cloudContext;
- (void)cloudContextGetReady:(id <ASCloudContext>)cloudContext;
@end

#endif /* ASPrivateProtocol.h */
