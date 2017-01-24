//
//  ASynchronizablePrivate.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

@protocol ASDataSyncAgregator;
@protocol ASynchronizableContext;
@protocol ASynchronizableContextDelegate;

#ifndef ASynchronizableContext_h
#define ASynchronizableContext_h

#import "ASerializableContext.h"
#import "ASynchronizable.h"

@protocol ASynchronizableContextPrivate <ASynchronizableContext>
@required

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSSet <id <ASynchronizableObject>> *updatedObjects;
@property (nonatomic, strong, readonly) NSSet <id <ASynchronizableDescription>> *deletedObjects;

- (void)setAgregator:(id<ASDataSyncAgregator>)agregator;
- (void)mergeWithRecievedContext:(ASerializableContext *)recievedContext;

@end

@protocol ASDataSyncAgregator <NSObject>
@required
- (void)willCommitContext:(id <ASynchronizableContext>)context;
@optional
- (void)watchConnector:(ASWatchConnector *)connector didRecieveContext:(ASerializableContext *)context;
@end

#endif /* ASynchronizableContext_h */
