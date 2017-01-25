//
//  ASDataAgregator.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASDataAgregator.h"
#import "ASPrivateProtocol.h"

@interface ASDataAgregator() <ASDataAgregator>

@end

@implementation ASDataAgregator {
    NSMutableSet <id<ASynchronizableContextPrivate>> *watchContextSet;
    id<ASynchronizableContextPrivate> *cloudContext;
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
        _watchConnector = ASWatchConnector.sharedInstance;
        _watchConnector se self;
        watchContextSet = [NSMutableSet new];
        cloudContextSet = [NSMutableSet new];
#warning reload "replication needed" status
    }
    return self;
}

- (void)willCommitContext:(id<ASynchronizableContextPrivate>)context {
    if (_watchConnector) {
        if (_watchConnector.ready) {
            if (![_watchConnector sendContext:context]) {
#warning some error on sending context. throw exception? try to send another way?
                [enqueue serializedcontext];
            }
        } else {
            NSLog(@"[WARNING] %s : watchConnector is not ready", __PRETTY_FUNCTION__);
            
        }
    } else {
        //So don't tell me.. I've nothing to do.. 
    }
}

- (void)watchConnectorGetReady:(id<ASWatchConnector>)connector {
#warning Start full replication if connector ready and replication needed.
}

- (void)watchConnector:(ASWatchConnector *)connector didRecieveContext:(ASerializableContext *)context {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s : <%@>", __PRETTY_FUNCTION__, context.identifier);
#endif
    for (id<ASynchronizableContextPrivate> cc in contextSet) {
        if ([cc.identifier isEqualToString:context.identifier]) {
            [cc mergeWithRecievedContext:context];
            return ;
        }
    }
   NSLog(@"[ERROR] %s : context <%@> not found", __PRETTY_FUNCTION__, context.identifier);
}

- (void)addWatchSynchronizableContext:(id<ASynchronizableContextPrivate>)context {
    [watchContextSet addObject:context];
    [context setAgregator:self];
    #warning Start full replication if connector ready and replication needed.
}

@end
