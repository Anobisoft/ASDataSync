//
//  ASPrivateProtocol.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//


@protocol ASynchronizableContextPrivate;
@protocol ASCloudContext;
@protocol ASWatchConnector;

@protocol ASContextDataAgregator;
@protocol ASWatchDataAgregator;
@class ASMapping;

#ifndef ASPrivateProtocol_h
#define ASPrivateProtocol_h

#import "ASerializableContext.h"
#import "ASPublicProtocol.h"
#import "ASMapping.h"

#pragma mark - ASynchronizableContextPrivate protocol

@protocol ASynchronizableContextPrivate <ASynchronizableContext>
@required

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSSet <id <ASynchronizableObject>> *updatedObjects;
@property (nonatomic, strong, readonly) NSSet <id <ASynchronizableDescription>> *deletedObjects;

- (void)setAgregator:(id<ASContextDataAgregator>)agregator;

@end

@protocol ASWatchSynchronizableContext <ASynchronizableContextPrivate>
@required
- (void)performMergeWithRecievedContext:(ASerializableContext *)recievedContext;
@end

@protocol ASCloudSynchronizableContext <ASynchronizableContextPrivate>
@required
- (void)performMergeWithCloudContext:(id <ASCloudContext>)cloudContext;
- (ASMapping *)autoMapping;
@end

#pragma mark - ASCloudContext protocol

@protocol ASCloudManager <ASContextDataAgregator>
@required
@property (nonatomic, strong, readonly) ASMapping *mapping;

- (void)setCloudSynchronizableContext:(id <ASCloudSynchronizableContext>)context;
- (BOOL)ready;

@end

@protocol ASCloudContext <NSObject>

+ (instancetype)contextWithUpdatedRecords:(NSSet <id <ASCloudRelatableRecord>> *)updatedRecords deletionInfoRecords:(NSSet <id <ASCloudDescription>> *)deletionInfoRecords;

@property (nonatomic, strong, readonly) NSSet <id <ASCloudRelatableRecord>> *updatedRecords;
@property (nonatomic, strong, readonly) NSSet <id <ASCloudDescription>> *deletionInfoRecords;

@end


#pragma mark - ASWatchConnector protocol

@protocol ASWatchConnector <NSObject>
- (BOOL)sendContext:(ASerializableContext *)context;
- (BOOL)ready;
- (void)setAgregator:(id<ASWatchDataAgregator>)agregator;
@end


#pragma mark - ASDataAgregator protocol

@protocol ASContextDataAgregator <NSObject>
@required
- (void)willCommitContext:(id <ASynchronizableContextPrivate>)context;
@end

@protocol ASWatchDataAgregator <NSObject>
@required
- (void)watchConnector:(id <ASWatchConnector>)connector didRecieveContext:(ASerializableContext *)context;
- (void)watchConnectorGetReady:(id <ASWatchConnector>)connector;
@end

#endif /* ASPrivateProtocol_h */
