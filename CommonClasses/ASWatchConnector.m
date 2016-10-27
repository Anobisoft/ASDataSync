//
//  ASWatchConnector.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASWatchConnector.h"
#import "NSString+LogLevel.h"
#import "ASerializableContext.h"
#import "ASynchronizablePrivate.h"
#import "ASDataSyncAgregator.h"

#define AS_WC_targetKey @"AS_WC_target"
#define AS_WC_dateKey @"AS_WC_date"
#define AS_WC_contextDataKey @"AS_WC_contextData"


@implementation ASWatchConnector {
    dispatch_semaphore_t sessionActivationSemaphore;
    NSTimer *logTimer;
    NSMutableArray <NSDictionary *> *userInfoQueue;
}

#pragma mark initalization and state

+ (instancetype)new {
    return [self sharedInstance];
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        if (WCSession.isSupported) {
            shared = [[super alloc] initUniqueInstance];
        } else {
            [[NSString stringWithFormat:@"%s WCSession not supported", __PRETTY_FUNCTION__] logError];
        }
    });
    return shared;
}

- (instancetype)initUniqueInstance {
    if (self = [super init]) {
        sessionActivationSemaphore = dispatch_semaphore_create(0);
        userInfoQueue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ASWatchConnector.userInfoQueue"];
        if (!userInfoQueue) userInfoQueue = [NSMutableArray new];
    }
    return self;
}

- (void)enqueueUserInfo:(NSDictionary *)userInfo {
    [userInfoQueue addObject:userInfo];
    [[NSUserDefaults standardUserDefaults] setObject:userInfoQueue forKey:@"ASWatchConnector.userInfoQueue"];
}

- (void)dequeue {
    if (self.ready) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSDictionary *userInfo in userInfoQueue) {
                [WCSession.defaultSession transferUserInfo:userInfo];
            }
            [userInfoQueue removeAllObjects];
        });
    }
}

- (BOOL)ready {
#if TARGET_OS_IOS
    return WCSession.defaultSession.paired && WCSession.defaultSession.watchAppInstalled;
#else
    return sessionActivated;
#endif
}

- (void)recieverStart {
    WCSession.defaultSession.delegate = self;
    if (!(sessionActivated = WCSession.defaultSession.activationState == WCSessionActivationStateActivated)) {
        [WCSession.defaultSession activateSession];
        dispatch_semaphore_wait(sessionActivationSemaphore, DISPATCH_TIME_FOREVER);
    }
    if (self.ready) {
        NSError *error = nil;
        [WCSession.defaultSession updateApplicationContext:@{@"WCSession.crutch" : @"request"} error:&error];
    }
}

- (void)recieverStop {
    WCSession.defaultSession.delegate = nil;
}

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
    sessionActivated = activationState == WCSessionActivationStateActivated;
    dispatch_semaphore_signal(sessionActivationSemaphore);
    switch (activationState) {
        case WCSessionActivationStateInactive:
            [[NSString stringWithFormat:@"WCSession activationDidCompleteWithState: WCSessionActivationStateInactive"] logError];
            break;
        case WCSessionActivationStateNotActivated:
            [[NSString stringWithFormat:@"WCSession activationDidCompleteWithState: WCSessionActivationStateNotActivated"] logError];

            break;
        default:
            #ifdef DEBUG
            [[NSString stringWithFormat:@"WCSession activationDidCompleteWithState: WCSessionActivationStateActivated"] logDebug];
            #endif
            if (self.ready) {
                #ifdef DEBUG
                [[NSString stringWithFormat:@"%@ ready", self.class] logDebug];
                [self dequeue];
                #endif
            } else {
                #if TARGET_OS_IOS
                [[NSString stringWithFormat:@"%@ not ready: %@, %@", self.class,
                  WCSession.defaultSession.paired ? @"Watch paired" : @"Watch not paired",
                  WCSession.defaultSession.watchAppInstalled ? @"WatchApp installed" : @"WatchApp not installed"] logError];
                #endif
            }
            break;
    }
    if (error) [[NSString stringWithFormat:@"WCSession activation error(%ld): %@\n%@", (long)error.code, error.localizedDescription, error.userInfo] logError];
}

- (void)sessionDidDeactivate:(WCSession *)session {
    sessionActivated = NO;
}

- (void)sessionDidBecomeInactive:(WCSession *)session {
    sessionActivated = NO;
}

#if TARGET_OS_IOS
- (void)sessionWatchStateDidChange:(WCSession *)session {
    if (self.ready) {
        [[NSString stringWithFormat:@"%@ ready now", self.class] logInfo];
        [self dequeue];
    } else {
        [[NSString stringWithFormat:@"%@ not ready: %@, %@", self.class,
          WCSession.defaultSession.paired ? @"Watch paired" : @"Watch not paired",
          WCSession.defaultSession.watchAppInstalled ? @"WatchApp installed" : @"WatchApp not installed"] logWarning];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:statusChanged:)]) {
        [self.delegate watchConnector:self statusChanged:self.ready];
    }
}
#endif

#pragma mark data send and recieve

- (BOOL)sendContext:(id <ASynchronizableContext>)context {
    if (context) {
        ASerializableContext *contextSerializable = [ASerializableContext instantiateWithSynchronizableContext:context];
        if (contextSerializable) {
            NSData *contextData = [NSKeyedArchiver archivedDataWithRootObject:contextSerializable];
            NSDictionary *userInfo = @{ AS_WC_targetKey : NSStringFromClass(self.class),
                                        AS_WC_contextDataKey : contextData,
                                        AS_WC_dateKey : [NSDate date] };
            if (self.ready) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [WCSession.defaultSession transferUserInfo:userInfo];
                });
#ifdef DEBUG
                [[NSString stringWithFormat:@"%s context <%@> sended", __PRETTY_FUNCTION__, contextSerializable.identifier] logDebug];
#endif
            } else {
                [self enqueueUserInfo:userInfo];
#if TARGET_OS_IOS
                [[NSString stringWithFormat:@"%@ not ready: %@, %@", self.class,
                  WCSession.defaultSession.paired ? @"Watch paired" : @"Watch not paired",
                  WCSession.defaultSession.watchAppInstalled ? @"WatchApp installed" : @"WatchApp not installed"] logError];
#else
                [[NSString stringWithFormat:@"%@ not ready: WCSession has not activated", self.class] logError];
#endif
            }
        } else {
            [[NSString stringWithFormat:@"%s empty context, skipped", __PRETTY_FUNCTION__] logNotice];
        }
        return true;
    } else {
        [[NSString stringWithFormat:@"%s context is nil", __PRETTY_FUNCTION__] logNotice];
        return false;
    }
}

- (void)session:(WCSession * __nonnull)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(nullable NSError *)error {
    if (error) [[NSString stringWithFormat:@"%s %@\n%@\n%@", __PRETTY_FUNCTION__, userInfoTransfer, error.localizedDescription, error.userInfo] logError];
#ifdef DEBUG
    else [[NSString stringWithFormat:@"%s %@ success", __PRETTY_FUNCTION__, userInfoTransfer] logDebug];
    dispatch_async(dispatch_get_main_queue(), ^{
        [logTimer invalidate];
        logTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(logOutstandingUserInfoTransfers) userInfo:nil repeats:YES];
    });
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didFinishUserInfoTransfer:error:)]) {
        [self.delegate watchConnector:self didFinishUserInfoTransfer:userInfoTransfer error:error];
    }
}

#ifdef DEBUG
- (void)logOutstandingUserInfoTransfers {
    if (WCSession.defaultSession.outstandingUserInfoTransfers.count) {
        [[NSString stringWithFormat:@"WCSession.outstandingUserInfoTransfers: %@", WCSession.defaultSession.outstandingUserInfoTransfers] logNotice];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [logTimer invalidate];
        });
    }
}
#endif

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    #ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
    #endif
    if ([[userInfo objectForKey:AS_WC_targetKey] isEqualToString:NSStringFromClass(self.class)]) {
        #ifdef DEBUG
        [[NSString stringWithFormat:@"Send date: %@", [userInfo objectForKey:AS_WC_dateKey]] logDebug];
        #endif
        NSData *contextData = [userInfo objectForKey:AS_WC_contextDataKey];
        if (contextData) {
            ASerializableContext *context = [NSKeyedUnarchiver unarchiveObjectWithData:contextData];
            if (self.agregator) {
                if ([self.agregator respondsToSelector:@selector(watchConnector:didRecieveContext:)]) {
                    [self.agregator watchConnector:self didRecieveContext:context];
                } else {
                   [[NSString stringWithFormat:@"%s %@ agregator not respods to @selector(watchConnector:didRecieveContext:)", __PRETTY_FUNCTION__, self.class] logError];
                }
            } else {
                [[NSString stringWithFormat:@"%s %@ agregator required", __PRETTY_FUNCTION__, self.class] logError];
            }
        } else {
            [[NSString stringWithFormat:@"%s contextData is empty", __PRETTY_FUNCTION__] logError];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveUserInfo:)]) {
            [self.delegate watchConnector:self didReceiveUserInfo:userInfo];
        }
    }
}

/** -------------------------- Background Transfers ------------------------- */

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *, id> *)applicationContext {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveApplicationContext:)]) {
        [self.delegate watchConnector:self didReceiveApplicationContext:applicationContext];
    }
}

- (void)session:(WCSession *)session didFinishFileTransfer:(WCSessionFileTransfer *)fileTransfer error:(nullable NSError *)error {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didFinishFileTransfer:error:)]) {
        [self.delegate watchConnector:self didFinishFileTransfer:fileTransfer error:error];
    }
}

- (void)session:(WCSession *)session didReceiveFile:(WCSessionFile *)file {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveFile:)]) {
        [self.delegate watchConnector:self didReceiveFile:file];
    }
}

/** ------------------------- Interactive Messaging ------------------------- */

- (void)sessionReachabilityDidChange:(WCSession *)session {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(sessionReachabilityDidChange:)]) {
        [self.delegate sessionReachabilityDidChange:session.reachable];
    }
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveMessage:)]) {
        [self.delegate watchConnector:self didReceiveMessage:message];
    }
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveMessage:replyHandler:)]) {
        [self.delegate watchConnector:self didReceiveMessage:message replyHandler:replyHandler];
    }
}


- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveMessageData:)]) {
        [self.delegate watchConnector:self didReceiveMessageData:messageData];
    }
}

- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData replyHandler:(void(^)(NSData *replyMessageData))replyHandler {
#ifdef DEBUG
    [[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] logDebug];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveMessageData:replyHandler:)]) {
        [self.delegate watchConnector:self didReceiveMessageData:messageData replyHandler:replyHandler];
    }
}






@end
