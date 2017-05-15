//
//  ASCloudManager.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//


#import "ASCloudManager.h"

#import "ASDeviceList.h"
#import "ASPrivateProtocol.h"
#import "NSUUID+NSData.h"

#import "ASCloudTransaction.h"
#import "ASCloudRecordRepresentation.h"
#import "ASCloudDescriptionRepresentation.h"
#import "ASPreparedToCloudRecords.h"

#import "CKRecord+ASDataSync.h"
#import "CKRecordID+ASDataSync.h"
#import "CKReference+ASDataSync.h"

#import "ASCloudInternalConst.h"
#import "NSDate+ASUtilities.h"

typedef void (^FetchRecord)(__kindof CKRecord *record);
typedef void (^FetchRecordsArray)(NSArray <__kindof CKRecord *> *records);

typedef NS_ENUM(NSUInteger, ASCloudState) {
    ASCloudStateAccountStatusAvailable = 1 << 0,
    ASCloudStateThisDeviceUpdated = 1 << 1,
    ASCloudStateDevicesReloaded = 1 << 2,
};

@interface ASCloudManager() <ASCloudManager>
    @property (nonatomic, strong, readonly) NSDictionary <NSString *, NSDate *> *maxCloudModificationDateForEntity;
    - (void)setMaxCloudModificationDate:(NSDate *)date forEntity:(NSString *)entity;

    
@end

@implementation ASCloudManager {
    id <ASDataSyncContextPrivate, ASCloudMappingProvider> syncContext;
    
    ASCloudState state;
    CKContainer *container;
    CKDatabase *db;
    
    ASDeviceList *deviceList;
    NSPredicate *thisDevicePredicate;
    ASPreparedToCloudRecords *preparedToCloudRecords;
    NSMutableSet <CKRecord *> *_recievedUpdatedRecords, *_recievedDeletionInfoRecords;
    
    dispatch_group_t primaryInitializationGroup;
    dispatch_group_t lockCloudGroup;
    dispatch_queue_t waitingQueue;
    BOOL smartReplicationInprogress, totalReplicationInprogress;
    
    NSString *maxCloudModificationDateForEntityUDCompositeKey, *preparedToCloudRecordsUDCompositeKey;
    
    NSTimer *retryToInitTimer;
    NSTimer *resmartTimer;
}


#pragma mark - Private Properties

- (NSSet <CKRecord <ASMappedObject> *> *)recievedUpdatedRecords {
    return _recievedUpdatedRecords.copy;
}

- (NSSet <CKRecord <ASMappedObject> *> *)recievedDeletionInfoRecords {
    return _recievedDeletionInfoRecords.copy;
}

@synthesize maxCloudModificationDateForEntity = _maxCloudModificationDateForEntity;
NSMutableDictionary *maxCloudModificationDateForEntityMutable;
- (NSDictionary <NSString *, NSDate *> *)maxCloudModificationDateForEntity {
    if (!_maxCloudModificationDateForEntity) {
        _maxCloudModificationDateForEntity = [[NSUserDefaults standardUserDefaults] objectForKey:maxCloudModificationDateForEntityUDCompositeKey];
        if (!_maxCloudModificationDateForEntity) _maxCloudModificationDateForEntity = @{};
    }
    return _maxCloudModificationDateForEntity;
}
- (void)setMaxCloudModificationDate:(NSDate *)date forEntity:(NSString *)entity {
    if (date) {
        [maxCloudModificationDateForEntityMutable setObject:date forKey:entity];
    } else {
        [maxCloudModificationDateForEntityMutable removeObjectForKey:entity];
    }
    _maxCloudModificationDateForEntity = maxCloudModificationDateForEntityMutable.copy;
    [[NSUserDefaults standardUserDefaults] setObject:_maxCloudModificationDateForEntity forKey:maxCloudModificationDateForEntityUDCompositeKey];
}



#pragma mark - initialization

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

static NSMutableDictionary<NSString *, id> *instances[4];
+ (void)initialize {
    [super initialize];
    instances[ASDatabaseScopeDefault] = instances[CKDatabaseScopePrivate] = [NSMutableDictionary new];
    instances[CKDatabaseScopePublic] = [NSMutableDictionary new];
    instances[CKDatabaseScopeShared] = [NSMutableDictionary new];
}

+ (instancetype)instanceWithContainerIdentifier:(NSString *)identifier databaseScope:(ASDatabaseScope)databaseScope {
    id instance = [instances[databaseScope % 4] objectForKey:identifier];
    if (!instance) {
        instance = [[self alloc] initWithContainerIdentifier:identifier databaseScope:(CKDatabaseScope)databaseScope];
        [instances[databaseScope % 4] setObject:instance forKey:identifier];
    }    
    return instance;
}

- (instancetype)initWithContainerIdentifier:(NSString *)identifier databaseScope:(CKDatabaseScope)databaseScope {
    if (self = [super init]) {
        primaryInitializationGroup = dispatch_group_create();
        lockCloudGroup = dispatch_group_create();
        waitingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        _recievedUpdatedRecords = [NSMutableSet new];
        _recievedDeletionInfoRecords = [NSMutableSet new];
        deviceList = [ASDeviceList new];
        thisDevicePredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(%@ == %%@)", ASCloudDeletionInfoRecordProperty_deviceID], deviceList.thisDevice.UUIDString];
#ifdef DEBUG
        NSLog(@"[DEBUG] thisDevicePredicate: %@", thisDevicePredicate);
#endif
        
        container = [CKContainer containerWithIdentifier:identifier];
        
        NSString *dbScopeString;
        switch (databaseScope) {
            case CKDatabaseScopePublic:
                db = container.publicCloudDatabase;
                dbScopeString = @"Public";
                break;
            case CKDatabaseScopeShared:
                db = container.sharedCloudDatabase;
                dbScopeString = @"Shared";
                break;
            default:
                dbScopeString = @"Private";
                db = container.privateCloudDatabase;
                break;
        }
        _instanceIdentifier = [NSString stringWithFormat:@"%@%@-%@", NSStringFromClass(self.class), dbScopeString, container.containerIdentifier];
        
        maxCloudModificationDateForEntityUDCompositeKey = [NSString stringWithFormat:@"%@-%@", _instanceIdentifier, ASCloudMaxModificationDateForEntityUDKey];
        maxCloudModificationDateForEntityMutable = self.maxCloudModificationDateForEntity.mutableCopy;
        
        preparedToCloudRecordsUDCompositeKey = [NSString stringWithFormat:@"%@-%@", _instanceIdentifier, ASCloudPreparedToCloudRecordsUDKey];
        NSData *preparedToCloudRecordsData = [[NSUserDefaults standardUserDefaults] objectForKey:preparedToCloudRecordsUDCompositeKey];
        if (preparedToCloudRecordsData) preparedToCloudRecords = [NSKeyedUnarchiver unarchiveObjectWithData:preparedToCloudRecordsData];
        else preparedToCloudRecords = [ASPreparedToCloudRecords new];
        
        [self tryPerformInit];
    }
    return self;
}

@synthesize enabled = _enabled;
- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    if (enabled) {
        [self tryPerformInit];
        [self startSmart];
    } else {
        [self removeAllSubscriptionsCompletion:nil];
    }
}
- (BOOL)enabled {
    return _enabled;
}

- (void)tryPerformInit {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (retryToInitTimer) {
        [retryToInitTimer invalidate];
        retryToInitTimer = nil;
    }
    if (self.enabled) [self performPrimaryInitCompletion:^{
        if (self.ready) {
#ifdef DEBUG
            NSLog(@"[DEBUG] %s READY!!!", __PRETTY_FUNCTION__);
#endif
            if (preparedToCloudRecords.accumulativeTransaction) [self performCloudUpdateWithLocalTransaction:preparedToCloudRecords.accumulativeTransaction];
        } else {
            if (retryToInitTimer) {
                [retryToInitTimer invalidate];
                retryToInitTimer = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                retryToInitTimer = [NSTimer scheduledTimerWithTimeInterval:ASCloudInitTimeout repeats:NO block:^(NSTimer * _Nonnull timer) {
                    [self tryPerformInit];
                }];
            });
        }
    }];
}

- (void)performPrimaryInitCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_group_enter(primaryInitializationGroup);
    [container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ERROR] %@", error.localizedDescription);
        }
        if (accountStatus == CKAccountStatusAvailable) {
            state |= ASCloudStateAccountStatusAvailable;
            [self updateDevicesCompletion:^{
                dispatch_group_leave(primaryInitializationGroup);
                if (completion) completion();
            }];
        } else {
            state ^= state & ASCloudStateAccountStatusAvailable;
            dispatch_group_leave(primaryInitializationGroup);
            if (completion) completion();
        }
    }];
}

- (void)savePreparedToCloudRecords {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:preparedToCloudRecords] forKey:preparedToCloudRecordsUDCompositeKey];
    });    
}



#pragma mark - Devices Update

- (void)updateDevicesCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self enqueueUpdateWithMappedObject:deviceList.thisDevice successBlock:^(BOOL success) {
        if (success) {
#ifdef DEBUG
            NSLog(@"[DEBUG] enqueueUpdateThisDevice success");
#endif
            [self pushQueueWithSuccessBlock:^(BOOL success) {
                if (success) {
#ifdef DEBUG
                    NSLog(@"[DEBUG] pushDevice success");
#endif
                    state |= ASCloudStateThisDeviceUpdated;
                    [self loadAllDevisesCompletion:^{
                        if (completion) completion();
                    }];
                } else {
#ifdef DEBUG
                    NSLog(@"[DEBUG] pushDevice unsuccess");
#endif
                    state ^= state & ASCloudStateThisDeviceUpdated;
                    if (completion) completion();
                }
            }];
        } else {
#ifdef DEBUG
            NSLog(@"[DEBUG] enqueueUpdateThisDevice unsuccess");
#endif
            state ^= state & ASCloudStateThisDeviceUpdated;
            if (completion) completion();
        }
    }];
    
}

- (void)loadAllDevisesCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self getAllRecordsOfEntityName:[ASDevice entityName] fetch:^(NSArray<__kindof CKRecord *> *records) {
        if (records) {
#ifdef DEBUG
            NSLog(@"[DEBUG] %s count: %ld", __PRETTY_FUNCTION__, (long)records.count);
#endif
            for (CKRecord<ASMappedObject> *record in records) {
                ASDevice *device = [ASDevice deviceWithMappedObject:record];
                [deviceList addDevice:device];
            }
            state |= ASCloudStateDevicesReloaded;
        } else {
            state ^= state & ASCloudStateDevicesReloaded;
        }
        if (completion) completion();
    }];
}

- (void)reloadDevisesCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self getNewRecordsOfEntityName:[ASDevice entityName] fetch:^(NSArray<__kindof CKRecord *> *records) {
        if (records) {
#ifdef DEBUG
            NSLog(@"[DEBUG] %s count: %ld", __PRETTY_FUNCTION__, (long)records.count);
#endif
            for (CKRecord<ASMappedObject> *record in records) {
                ASDevice *device = [ASDevice deviceWithMappedObject:record];
                [deviceList addDevice:device];
            }
        }
        if (completion) completion();
    }];
}

#pragma mark - Subscriptions and Remote notifications

- (void)subscribeToRegisteredRecordTypes {
    [self removeAllSubscriptionsCompletion:^{
        [self saveSubscriptions];
    }];
}

- (void)removeAllSubscriptionsCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [db fetchAllSubscriptionsWithCompletionHandler:^(NSArray<CKSubscription *> * _Nullable subscriptions, NSError * _Nullable error) {
        dispatch_group_t removeSubscriptionsGroup = dispatch_group_create();
        
        if (error) NSLog(@"[ERROR] fetchAllSubscriptions error: %@", error.localizedDescription);
        for (CKQuerySubscription *subscription in subscriptions) {
            dispatch_group_enter(removeSubscriptionsGroup);
            [db deleteSubscriptionWithID:subscription.subscriptionID completionHandler:^(NSString * _Nullable subscriptionID, NSError * _Nullable error) {
                if (error) NSLog(@"[ERROR] deleteSubscription error: %@", error.localizedDescription);
                dispatch_group_leave(removeSubscriptionsGroup);
            }];
        }
        if (completion) {
            dispatch_group_wait(removeSubscriptionsGroup, DISPATCH_TIME_FOREVER);
            completion();
        }
    }];
}

typedef void (^SaveSubscriptionCompletionHandler)(CKSubscription * _Nullable subscription, NSError * _Nullable error);
- (void)saveSubscriptions {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    SaveSubscriptionCompletionHandler completionHandler = ^(CKSubscription * _Nullable subscription, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ERROR] Subscription failed: %@", error.localizedDescription);
        } else {
            NSLog(@"[INFO] Success subscripted: %@", subscription);
        }
    };
    for (NSString *recordType in self.mapping.allRecordTypes) {
        CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:recordType
                                                                                  predicate:[NSPredicate predicateWithValue:true]
                                                                                    options:+CKQuerySubscriptionOptionsFiresOnRecordCreation
                                                                                            +CKQuerySubscriptionOptionsFiresOnRecordUpdate
                                                                                            +CKQuerySubscriptionOptionsFiresOnRecordDeletion];
        subscription.notificationInfo = [CKNotificationInfo new];
        //            subscription.notificationInfo.alertBody = @"";
        subscription.notificationInfo.shouldBadge = true;
        subscription.notificationInfo.category = @"CloudKit";
        [db saveSubscription:subscription completionHandler:completionHandler];
    }
    CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:ASCloudDeletionInfoRecordType
                                                                              predicate:thisDevicePredicate
                                                                                options:CKQuerySubscriptionOptionsFiresOnRecordCreation+CKQuerySubscriptionOptionsFiresOnRecordUpdate];
    [db saveSubscription:subscription completionHandler:completionHandler];
}

- (void)acceptPushNotificationUserInfo:(NSDictionary *)userInfo {
    CKQueryNotification *notification = [CKQueryNotification notificationFromRemoteNotificationDictionary:userInfo];
    if (notification.notificationType == CKNotificationTypeQuery && notification.databaseScope == db.databaseScope && [notification.containerIdentifier isEqualToString:container.containerIdentifier]) {
#ifdef DEBUG
        NSLog(@"[DEBUG] %@ acceptPushNotification: %@", self.class, notification);
#endif
        if (notification.queryNotificationReason == CKQueryNotificationReasonRecordDeleted) {
            [self getCloudDeletionInfoCompletion:^{
                [self performMergeAndCleanupIfNeeded];
            }];
        } else {            
            [self recordByRecordID:notification.recordID fetch:^(CKRecord <ASMappedObject>*record, NSError * _Nullable error) {
                if (record) {
                    NSLog(@"[DEBUG] found record %@", record);
                    NSString *entityName = self.mapping.reverseMap[record.recordType];
                    if ([record.recordType isEqualToString:ASCloudDeletionInfoRecordType]) {
                        [_recievedDeletionInfoRecords addObject:record];
                        [preparedToCloudRecords addRecordIDToDelete:record.recordID];
                    } else if (entityName) {
                        [_recievedUpdatedRecords addObject:record];
                    }
                    [self performMergeAndCleanupIfNeeded];
                } else {
                    @throw [NSException exceptionWithName:@"CKFetchRecordsOperation failed"
                                                   reason:[NSString stringWithFormat:@"Object with recordID %@ not found.", notification.recordID.recordName]
                                                 userInfo:nil];
                }
            }];
            [self smartReplication];
        }
        //*/
    } else {
        NSLog(@"[WARNING] Unacceptable notification recieved %@", notification);
    }
}



#pragma mark - ASCloudManager

- (BOOL)ready {
    ASCloudState requiredState = ASCloudStateAccountStatusAvailable | ASCloudStateThisDeviceUpdated | ASCloudStateDevicesReloaded;
    return (state & requiredState) == requiredState;
}

- (void)setDataSyncContext:(id<ASDataSyncContextPrivate, ASCloudMappingProvider>)context {
    syncContext = context;
    [self startSmart];
}

- (void)startSmart {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) dispatch_async(waitingQueue, ^{
        dispatch_group_wait(primaryInitializationGroup, DISPATCH_TIME_FOREVER);
        if (self.ready) {
            [self subscribeToRegisteredRecordTypes];
            [self smartReplication];
        } else {
            if (self.enabled) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ASCloudInitTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.enabled) [self startSmart];
            });
        }
    });
}

- (ASCloudMapping *)mapping {
    return syncContext.cloudMapping;
}

- (id<ASDataSyncContextPrivate, ASCloudMappingProvider>)dataSyncContext {
    return syncContext;
}

- (void)willCommitTransaction:(id<ASRepresentableTransaction>)transaction {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) {
        if (preparedToCloudRecords.accumulativeTransaction) {
            [preparedToCloudRecords.accumulativeTransaction mergeWithRepresentableTransaction:transaction];
            [self savePreparedToCloudRecords];
            [self performCloudUpdateWithLocalTransaction:preparedToCloudRecords.accumulativeTransaction];
        } else [self performCloudUpdateWithLocalTransaction:transaction];
    } else {
        if (preparedToCloudRecords.accumulativeTransaction) {
            [preparedToCloudRecords.accumulativeTransaction mergeWithRepresentableTransaction:transaction];
        } else {
            preparedToCloudRecords.accumulativeTransaction = [ASTransactionRepresentation instantiateWithRepresentableTransaction:transaction];
        }
        [self savePreparedToCloudRecords];
    }


}

- (void)performCloudUpdateWithLocalTransaction:(NSObject <ASRepresentableTransaction> *)transaction {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(primaryInitializationGroup, DISPATCH_TIME_FOREVER);
        if (self.ready) {
            dispatch_group_wait(lockCloudGroup, DISPATCH_TIME_FOREVER);
            dispatch_group_enter(lockCloudGroup);
            for (NSObject<ASMappedObject> *mappedObject in transaction.updatedObjects) {
                [self enqueueUpdateWithMappedObject:mappedObject successBlock:^(BOOL success) {
                    if (!success) {
                        [preparedToCloudRecords addFailedEnqueueUpdateObject:mappedObject];
                        [self savePreparedToCloudRecords];
                        NSLog(@"[WARNING] enqueueUpdateWithMappedObject unsuccess");
                    } else {
#ifdef DEBUG
                        NSLog(@"[DEBUG] enqueueUpdateWithMappedObject success");
#endif
                    }

                }];
            }
            [self reloadDevisesCompletion:^{
                for (NSObject<ASDescription> *description in transaction.deletedObjects) {
                    [self enqueueDeletionWithDescription:description];
                }
                [self pushQueueWithSuccessBlock:^(BOOL success) {
                    if (preparedToCloudRecords.accumulativeTransaction) preparedToCloudRecords.accumulativeTransaction = nil;
                    [self savePreparedToCloudRecords];
                    dispatch_group_leave(lockCloudGroup);
                }];
            }];
        } else {
            if (!preparedToCloudRecords.accumulativeTransaction) {
                preparedToCloudRecords.accumulativeTransaction = [ASTransactionRepresentation instantiateWithRepresentableTransaction:transaction];
                [self savePreparedToCloudRecords];
            }
            if (self.enabled) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ASCloudInitTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.enabled) [self performPrimaryInitCompletion:^{
                    [self performCloudUpdateWithLocalTransaction:preparedToCloudRecords.accumulativeTransaction];
                }];
            });
        }
    });
}



#pragma mark - Replication

- (void)smartReplication {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) [self replicationTotal:false];
}

- (void)totalReplication {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) [self replicationTotal:true];
}

- (void)replicationTotal:(BOOL)total {
    if (total) {
        if (totalReplicationInprogress) return ;
        else totalReplicationInprogress = smartReplicationInprogress = true;
    } else {
        if (smartReplicationInprogress) return ;
        else smartReplicationInprogress = true;
    }
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(primaryInitializationGroup, DISPATCH_TIME_FOREVER);
        if (self.ready) {
            dispatch_group_wait(lockCloudGroup, DISPATCH_TIME_FOREVER);
            dispatch_group_enter(lockCloudGroup);
            [self reloadMappedRecordsTotal:total completion:^{
                dispatch_group_leave(lockCloudGroup);
                totalReplicationInprogress = smartReplicationInprogress = false;
                [self resmart];
            }];
        } else {
            totalReplicationInprogress = smartReplicationInprogress = false;
            [self resmart];
        }
    });
}

- (void)resmart {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) dispatch_async(dispatch_get_main_queue(), ^{
        if (resmartTimer) {
            [resmartTimer invalidate];
            resmartTimer = nil;
        }
        resmartTimer = [NSTimer scheduledTimerWithTimeInterval:ASCloudSmartReplicationTimeout repeats:NO block:^(NSTimer * _Nonnull timer) {
            [resmartTimer invalidate];
            resmartTimer = nil;
            [self smartReplication];
        }];
    });
}

- (void)reloadMappedRecordsTotal:(BOOL)total completion:(void(^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_group_t thisGroup = dispatch_group_create();
    for (NSString *entityName in self.mapping.synchronizableEntities) {
        FetchRecordsArray fetchArrayBlock = ^(NSArray<__kindof CKRecord *> *records) {
            for (CKRecord *record in records) {
                [_recievedUpdatedRecords addObject:record];
            }
            dispatch_group_leave(thisGroup);
        };
        dispatch_group_enter(thisGroup);
        if (total) {
            [self getAllRecordsOfEntityName:entityName fetch:fetchArrayBlock];
        } else {
            [self getNewRecordsOfEntityName:entityName fetch:fetchArrayBlock];
        }
    }
    
    dispatch_group_enter(thisGroup);
    [self getCloudDeletionInfoCompletion:^{
        dispatch_group_leave(thisGroup);
    }];
    
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(thisGroup, DISPATCH_TIME_FOREVER);
        [self performMergeAndCleanupIfNeeded];
        if (completion) completion();
    });
}

- (void)getCloudDeletionInfoCompletion:(void (^)(void))completion {
    [self getRecordsOfEntityName:ASCloudDeletionInfoRecordType withPredicate:thisDevicePredicate fetch:^(NSArray<__kindof CKRecord *> *records) {
        for (CKRecord *record in records) {
            [_recievedDeletionInfoRecords addObject:record];
            [preparedToCloudRecords addRecordIDToDelete:record.recordID]; //cleanup
        }
        if (completion) completion();
    }];
}

- (void)performMergeAndCleanupIfNeeded {
    if (_recievedUpdatedRecords.count + _recievedDeletionInfoRecords.count) {
        [syncContext performMergeWithTransaction:[ASCloudTransaction transactionWithUpdatedRecords:self.recievedUpdatedRecords
                                                                               deletionInfoRecords:self.recievedDeletionInfoRecords
                                                                                           mapping:self.mapping]];
        [_recievedUpdatedRecords removeAllObjects];
        [_recievedDeletionInfoRecords removeAllObjects];
    }
    if (preparedToCloudRecords.recordIDsToDelete) {
        [self pushQueueWithSuccessBlock:^(BOOL success) {
#ifdef DEBUG
            NSLog(@"[DEBUG] Cleanup DeletionInfo %@", success ? @"success" : @"failed");
#endif
        }];
    }
}

#pragma mark - Fetch Records

- (void)getAllRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, entityName);
#endif
    [self setMaxCloudModificationDate:nil forEntity:entityName];
    [self getNewRecordsOfEntityName:entityName fetch:fetch];
}

- (void)getNewRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, entityName);
#endif
    NSDate *maxCloudModificationDate = self.maxCloudModificationDateForEntity[entityName];
    
    NSPredicate *predicate = maxCloudModificationDate ? [NSPredicate predicateWithFormat:@"modificationDate >= %@", maxCloudModificationDate] : nil;
    [self getRecordsOfEntityName:entityName withPredicate:predicate fetch:^(NSArray<__kindof CKRecord *> *records) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDate *maxDate = maxCloudModificationDate;
            BOOL changed = false;
            for (CKRecord *record in records) {
                if (!maxDate || [maxDate compare:(NSDate *)record[@"modificationDate"]] == NSOrderedAscending) {
                    maxDate = record[@"modificationDate"];
                    changed = true;
                }
            }
            if (changed) [self setMaxCloudModificationDate:[maxDate dateByAddingTimeInterval:-60.0f] forEntity:entityName];
        });
        fetch(records);
    }];
}

- (void)getRecordsOfEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] getRecordsOfEntityName: %-20s withPredicate: %@", [entityName UTF8String], predicate);
#endif
    
    NSMutableArray *foundRecords = [NSMutableArray new];
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:self.mapping[entityName] predicate:predicate ?: [NSPredicate predicateWithValue:true]];
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    __block CKQueryOperation *activeOperation = queryOperation;
    
    queryOperation.recordFetchedBlock = ^(CKRecord * _Nonnull record) {
        [foundRecords addObject:record];
    };
    queryOperation.queryCompletionBlock = ^(CKQueryCursor * _Nullable cursor, NSError * _Nullable operationError) {
        if (operationError) {
            NSLog(@"[ERROR] %@", operationError);
            fetch(nil);
        } else {
            if (cursor) {
                CKQueryOperation *fetchNext = [[CKQueryOperation alloc] initWithCursor:cursor];
                fetchNext.recordFetchedBlock = activeOperation.recordFetchedBlock;
                fetchNext.queryCompletionBlock = activeOperation.queryCompletionBlock;
                activeOperation = fetchNext;
                [db addOperation:fetchNext];
            } else {
                fetch(foundRecords.copy);
            }
        }
    };
    
    [db addOperation:queryOperation];
}


- (void)recordByRecordID:(CKRecordID *)recordID fetch:(void (^)(CKRecord<ASMappedObject> *record, NSError * _Nullable error))fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    CKFetchRecordsOperation *fetchOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[recordID]];
    __block NSInteger count = 0;
    __block CKRecord<ASMappedObject> *foundRecord = nil;
    __block NSError *error = nil;
    
    [fetchOperation setPerRecordCompletionBlock:^(CKRecord * _Nullable record, CKRecordID * _Nullable recordID, NSError * _Nullable operationError) {
        if (operationError) {
            NSLog(@"[ERROR] fetchOperationError: %@", operationError);
            error = operationError;
        }
        if (record) {
            foundRecord = (CKRecord<ASMappedObject> *)record;
            count++;
        }
    }];
    
    [fetchOperation setCompletionBlock:^{
        fetch(foundRecord, error);
        if (count > 1) {
            @throw [NSException exceptionWithName:@"CKFetchRecordsOperation error" reason:[NSString stringWithFormat:@"Unique constraint violated: duplicated recordID %@", recordID.recordName] userInfo:nil];
        }
    }];
    
    fetchOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    fetchOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [db addOperation:fetchOperation];
}


#pragma mark - Cloud Update

- (void)enqueueUpdateWithMappedObject:(NSObject<ASMappedObject> *)syncObject successBlock:(void (^)(BOOL success))successBlock {
    if (!syncObject.uniqueData) {
        NSLog(@"[ERROR] %s syncObject.uniqueData == nil. syncObject %@", __PRETTY_FUNCTION__, syncObject);
        return;
    }
#ifdef DEBUG
    else {
        NSLog(@"[DEBUG] %s entity %@ UUID %@", __PRETTY_FUNCTION__, syncObject.entityName, syncObject.uniqueData.UUIDString);
    }
#endif
    dispatch_group_enter(preparedToCloudRecords.lockGroup);
    CKRecordID *recordID = [CKRecordID recordIDWithUUIDString:syncObject.uniqueData.UUIDString];
    [self recordByRecordID:recordID fetch:^(CKRecord<ASMappedObject> *record, NSError * _Nullable error) {
        if (record) {
            if ([record.modificationDate compare:syncObject.modificationDate] != NSOrderedAscending) {
                NSLog(@"[WARNING] Cloud record %@ up to date %@", record.UUIDString, record.modificationDate);
                dispatch_group_leave(preparedToCloudRecords.lockGroup);
                return ; // record update no needed
            }
        } else {
            if (error.code == CKErrorUnknownItem) {
                NSLog(@"[INFO] Not found. Create new record with recordID %@", recordID.recordName);
                record = (CKRecord<ASMappedObject> *)[CKRecord recordWithRecordType:self.mapping[syncObject.entityName] recordID:recordID];
            } else {
                NSLog(@"[ERROR] recordByRecordID error: %@", error);
                
                dispatch_group_leave(preparedToCloudRecords.lockGroup);
                if (successBlock) successBlock(false);
                return ;
            }
        }
        record.keyedDataProperties = syncObject.keyedDataProperties;
        record.modificationDate = syncObject.modificationDate;
        
        if ([syncObject conformsToProtocol:@protocol(ASRelatableToOne)]) {
            NSObject <ASRelatableToOne> *relatableObject = (NSObject <ASRelatableToOne> *)syncObject;
            NSDictionary <NSString *, NSObject<ASReference> *> *keyedReferences = relatableObject.keyedReferences;
            for (NSString *relationKey in keyedReferences.allKeys) {
                [record replaceRelation:relationKey toReference:keyedReferences[relationKey]];
            }
        }
        
        if ([syncObject conformsToProtocol:@protocol(ASRelatableToMany)]) {
            NSObject <ASRelatableToMany> *relatableObject = (NSObject <ASRelatableToMany> *)syncObject;
            NSDictionary <NSString *, NSSet <NSObject<ASReference> *> *> *keyedSetsOfReferences = relatableObject.keyedSetsOfReferences;
            for (NSString *relationKey in keyedSetsOfReferences.allKeys) {
                [record replaceRelation:relationKey toSetsOfReferences:keyedSetsOfReferences[relationKey]];
            }
        }
        
        [preparedToCloudRecords addRecordToSave:record];
        dispatch_group_leave(preparedToCloudRecords.lockGroup);
        if (successBlock) successBlock(true);
    }];
}

- (void)enqueueDeletionWithDescription:(id <ASDescription>)description {
    if (!description.uniqueData) {
        NSLog(@"[ERROR] %s description.uniqueData == nil. description %@", __PRETTY_FUNCTION__, description);
        return;
    }
#ifdef DEBUG
    else NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, description);
#endif
    CKRecordID *recordID = [CKRecordID recordIDWithUUIDString:description.uniqueData.UUIDString];
    [preparedToCloudRecords addRecordIDToDelete:recordID];
    for (ASDevice *device in deviceList) {
        CKRecord *deletionInfo = [CKRecord recordWithRecordType:ASCloudDeletionInfoRecordType];
        deletionInfo[ASCloudDeletionInfoRecordProperty_recordType] = self.mapping[description.entityName];
        deletionInfo[ASCloudDeletionInfoRecordProperty_recordID] = description.uniqueData.UUIDString;
        deletionInfo[ASCloudDeletionInfoRecordProperty_deviceID] = device.UUIDString;
        [preparedToCloudRecords addRecordToSave:deletionInfo];
    }
}

- (void)pushQueueWithSuccessBlock:(void (^)(BOOL success))successBlock {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    for (id<ASMappedObject> mappedObject in preparedToCloudRecords.failedEnqueueUpdateObjects) {
        [self enqueueUpdateWithMappedObject:mappedObject successBlock:^(BOOL success) {
            NSLog(@"[%@] retry enqueueUpdateWithMappedObject %@success", success ? @"INFO" : @"WARNING", success ? @"": @"un");
        }];
    }
    
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(preparedToCloudRecords.lockGroup, DISPATCH_TIME_FOREVER);
        CKModifyRecordsOperation *mop = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:preparedToCloudRecords.recordsToSave
                                                                              recordIDsToDelete:preparedToCloudRecords.recordIDsToDelete];
        [mop setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable operationError) {
            if (operationError) {
                NSLog(@"[ERROR] CKModifyRecordsOperation Error: %@", operationError);
            }
            if (savedRecords.count == preparedToCloudRecords.recordsToSave.count && deletedRecordIDs.count == preparedToCloudRecords.recordIDsToDelete.count) {
                [preparedToCloudRecords clearAll];
                [self savePreparedToCloudRecords];
                if (successBlock) successBlock(true);
            } else {
                [preparedToCloudRecords clearWithSavedRecords:savedRecords deletedRecordIDs:deletedRecordIDs];
                [self savePreparedToCloudRecords];
                if (self.enabled) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ASCloudTryToPushTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    dispatch_async(waitingQueue, ^{
                        dispatch_group_wait(preparedToCloudRecords.lockGroup, DISPATCH_TIME_FOREVER);
                        dispatch_group_wait(lockCloudGroup, DISPATCH_TIME_FOREVER);
                        if (preparedToCloudRecords.recordsToSave.count + preparedToCloudRecords.recordIDsToDelete.count) {
                            dispatch_group_enter(lockCloudGroup);
                            [self pushQueueWithSuccessBlock:^(BOOL success) {
                                dispatch_group_leave(lockCloudGroup);
                            }];
                        }
                    });
                });
                if (successBlock) successBlock(false);
            }
        }];
        mop.queuePriority = NSOperationQueuePriorityVeryHigh;
        mop.qualityOfService = NSQualityOfServiceUserInteractive;
        [db addOperation:mop];
    });
    
}



@end
