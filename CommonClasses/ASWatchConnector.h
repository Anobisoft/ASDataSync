//
//  ASWatchConnector.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>


@protocol ASWatchConnectorDelegate;

#ifndef ASWatchConnector_h
#define ASWatchConnector_h

NS_ASSUME_NONNULL_BEGIN

@interface ASWatchConnector : NSObject <WCSessionDelegate> {
    @protected BOOL sessionActivated;
}

@property (nonatomic, weak, nullable) id <ASWatchConnectorDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL ready;

+ (instancetype)sharedInstance;

+ (instancetype)alloc NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;


@end

@protocol ASWatchConnectorDelegate <NSObject>
@required


@optional
- (void)watchConnector:(ASWatchConnector *)connector statusChanged:(BOOL)ready __WATCHOS_UNAVAILABLE;

/** ------------------------- Interactive Messaging ------------------------- */

- (void)sessionReachabilityDidChange:(BOOL)reachable;

- (void)watchConnector:(ASWatchConnector *)connector didReceiveMessage:(NSDictionary<NSString *, id> *)message;
- (void)watchConnector:(ASWatchConnector *)connector didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler;
- (void)watchConnector:(ASWatchConnector *)connector didReceiveMessageData:(NSData *)messageData;
- (void)watchConnector:(ASWatchConnector *)connector didReceiveMessageData:(NSData *)messageData replyHandler:(void(^)(NSData *replyMessageData))replyHandler;

/** -------------------------- Background Transfers ------------------------- */
- (void)watchConnector:(ASWatchConnector *)connector didReceiveApplicationContext:(NSDictionary<NSString *, id> *)applicationContext;
- (void)watchConnector:(ASWatchConnector *)connector didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(nullable NSError *)error;
- (void)watchConnector:(ASWatchConnector *)connector didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo;
- (void)watchConnector:(ASWatchConnector *)connector didFinishFileTransfer:(WCSessionFileTransfer *)fileTransfer error:(nullable NSError *)error;
- (void)watchConnector:(ASWatchConnector *)connector didReceiveFile:(WCSessionFile *)file;

NS_ASSUME_NONNULL_END

@end

#endif
