//
//  ASWatchConnector.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASWatchConnector.h"
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
            NSLog(@"[ERROR] %s WCSession not supported", __PRETTY_FUNCTION__);
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
            NSLog(@"[ERROR] WCSession activationDidCompleteWithState: WCSessionActivationStateInactive");
            break;
        case WCSessionActivationStateNotActivated:
            NSLog(@"[ERROR] WCSession activationDidCompleteWithState: WCSessionActivationStateNotActivated");

            break;
        default:
            #ifdef DEBUG
            NSLog(@"[DEBUG] WCSession activationDidCompleteWithState: WCSessionActivationStateActivated");
            #endif
            if (self.ready) {
                #ifdef DEBUG
                NSLog(@"[DEBUG] %@ ready", self.class);
                [self dequeue];
                #endif
            } else {
                #if TARGET_OS_IOS
                NSLog(@"[ERROR] %@ not ready: %@, %@", self.class,
                      WCSession.defaultSession.paired ? @"Watch paired" : @"Watch not paired",
                      WCSession.defaultSession.watchAppInstalled ? @"WatchApp installed" : @"WatchApp not installed");
                #endif
            }
            break;
    }
    if (error) NSLog(@"[ERROR] WCSession activation error(%ld): %@\n%@", (long)error.code, error.localizedDescription, error.userInfo);
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
        NSLog(@"[INFO] %@ ready now", self.class);
        [self dequeue];
    } else {
        NSLog(@"[WARNING] %@ not ready: %@, %@", self.class,
              WCSession.defaultSession.paired ? @"Watch paired" : @"Watch not paired",
              WCSession.defaultSession.watchAppInstalled ? @"WatchApp installed" : @"WatchApp not installed");
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
                NSLog(@"[DEBUG] %s context <%@> sended", __PRETTY_FUNCTION__, contextSerializable.identifier);
#endif
            } else {
                [self enqueueUserInfo:userInfo];
#if TARGET_OS_IOS
                NSLog(@"[ERROR] %@ not ready: %@, %@", self.class,
                      WCSession.defaultSession.paired ? @"Watch paired" : @"Watch not paired",
                      WCSession.defaultSession.watchAppInstalled ? @"WatchApp installed" : @"WatchApp not installed");
#else
                NSLog(@"[ERROR] %@ not ready: WCSession has not activated", self.class);
#endif
            }
        } else {
            NSLog(@"[NOTICE] %s empty context, skipped", __PRETTY_FUNCTION__);
        }
        return true;
    } else {
        NSLog(@"[NOTICE] %s context is nil", __PRETTY_FUNCTION__);
        return false;
    }
}

- (void)session:(WCSession * __nonnull)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(nullable NSError *)error {
    if (error) NSLog(@"[ERROR] %s %@\n%@\n%@", __PRETTY_FUNCTION__, userInfoTransfer, error.localizedDescription, error.userInfo);
#ifdef DEBUG
    else NSLog(@"[DEBUG] %s %@ success", __PRETTY_FUNCTION__, userInfoTransfer);
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
        NSLog(@"[NOTICE] WCSession.outstandingUserInfoTransfers: %@", WCSession.defaultSession.outstandingUserInfoTransfers);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [logTimer invalidate];
        });
    }
}
#endif

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    #ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
    #endif
    if ([[userInfo objectForKey:AS_WC_targetKey] isEqualToString:NSStringFromClass(self.class)]) {
        #ifdef DEBUG
        NSLog(@"[DEBUG] Send date: %@", [userInfo objectForKey:AS_WC_dateKey]);
        #endif
        NSData *contextData = [userInfo objectForKey:AS_WC_contextDataKey];
        if (contextData) {
            ASerializableContext *context = [NSKeyedUnarchiver unarchiveObjectWithData:contextData];
            if (self.agregator) {
                if ([self.agregator respondsToSelector:@selector(watchConnector:didRecieveContext:)]) {
                    [self.agregator watchConnector:self didRecieveContext:context];
                } else {
                   NSLog(@"[ERROR] %s %@ agregator not respods to @selector(watchConnector:didRecieveContext:)", __PRETTY_FUNCTION__, self.class);
                }
            } else {
                NSLog(@"[ERROR] %s %@ agregator required", __PRETTY_FUNCTION__, self.class);
            }
        } else {
            NSLog(@"[ERROR] %s contextData is empty", __PRETTY_FUNCTION__);
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
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveApplicationContext:)]) {
        [self.delegate watchConnector:self didReceiveApplicationContext:applicationContext];
    }
}

- (void)session:(WCSession *)session didFinishFileTransfer:(WCSessionFileTransfer *)fileTransfer error:(nullable NSError *)error {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didFinishFileTransfer:error:)]) {
        [self.delegate watchConnector:self didFinishFileTransfer:fileTransfer error:error];
    }
}

- (void)session:(WCSession *)session didReceiveFile:(WCSessionFile *)file {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveFile:)]) {
        [self.delegate watchConnector:self didReceiveFile:file];
    }
}

/** ------------------------- Interactive Messaging ------------------------- */

- (void)sessionReachabilityDidChange:(WCSession *)session {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(sessionReachabilityDidChange:)]) {
        [self.delegate sessionReachabilityDidChange:session.reachable];
    }
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveMessage:)]) {
        [self.delegate watchConnector:self didReceiveMessage:message];
    }
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveMessage:replyHandler:)]) {
        [self.delegate watchConnector:self didReceiveMessage:message replyHandler:replyHandler];
    }
}


- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveMessageData:)]) {
        [self.delegate watchConnector:self didReceiveMessageData:messageData];
    }
}

- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData replyHandler:(void(^)(NSData *replyMessageData))replyHandler {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchConnector:didReceiveMessageData:replyHandler:)]) {
        [self.delegate watchConnector:self didReceiveMessageData:messageData replyHandler:replyHandler];
    }
}






@end
