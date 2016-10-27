//
//  ASDataSyncAgregator.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASDataSyncAgregator.h"
#import "NSString+LogLevel.h"
#import "ASWatchConnector.h"
#import "ASynchronizable.h"
#import "ASynchronizablePrivate.h"
#import "ASerializableContext.h"

@interface ASDataSyncAgregator()<ASDataSyncAgregator>

@end

@implementation ASDataSyncAgregator {
    NSMutableSet <id<ASynchronizableContextPrivate>> *contextSet;
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
        _watchConnector.agregator = self;
        contextSet = [NSMutableSet new];
#warning reload "replication needed" status
    }
    return self;
}

- (void)recieverStart {
    [_watchConnector recieverStart];
}

- (void)recieverStop {
    [_watchConnector recieverStop];
}

- (void)willCommitContext:(id<ASynchronizableContextPrivate>)context {
    if (_watchConnector) {
        if (_watchConnector.ready) {
            if (![_watchConnector sendContext:context]) {
#warning some error on sending context. throw error? try to send another way?
            }
        } else {
            [[NSString stringWithFormat:@"%s : watchConnector is not ready", __PRETTY_FUNCTION__] logError];
#warning ERROR -> WARNING. Save status "replication needed".
        }
    } else {
        //So don't tell me.. I've nothing to do.. 
    }
}

- (void)watchConnector:(ASWatchConnector *)connector statusChanged:(BOOL)ready {
#warning Start full replication if connector ready and replication needed.
}


- (void)watchConnector:(ASWatchConnector *)connector didRecieveContext:(ASerializableContext *)context {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s : <%@>", __PRETTY_FUNCTION__, context.identifier] logDebug];
#endif
    for (id<ASynchronizableContextPrivate> cc in contextSet) {
        if ([cc.identifier isEqualToString:context.identifier]) {
            [cc mergeWithRecievedContext:context];
            return ;
        }
    }
   [[NSString stringWithFormat:@"%s : context <%@> not found", __PRETTY_FUNCTION__, context.identifier] logError];
}

- (void)addSynchronizableContext:(id<ASynchronizableContextPrivate>)context {
    [contextSet addObject:context];
#warning Start full replication if connector ready and replication needed.
    [context setAgregator:self];
}

- (void)commitAll {
    for (id<ASynchronizableContext> cc in contextSet) {
        [cc commit];
    }
}

- (void)rollbackAll {
    for (id<ASynchronizableContext> cc in contextSet) {
        [cc rollback];
    }
}

@end
