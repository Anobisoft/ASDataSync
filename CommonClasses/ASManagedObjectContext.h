//
//  ASManagedObjectContext.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ASPublicProtocol.h"
#import "NSManagedObject+ASDataSync.h"

#define ASC ascending:true
#define DESC ascending:false

NS_ASSUME_NONNULL_BEGIN

typedef void (^FetchObject)(__kindof NSManagedObject *object);

@interface ASManagedObjectContext : NSManagedObjectContext <ASDataSyncContext>

- (instancetype)initWithStoreURL:(NSURL *)storeURL modelURL:(nullable NSURL *)modelURL;
- (instancetype)initWithStoreURL:(NSURL *)storeURL;

+ (instancetype)defaultContext;
@property (nonatomic, weak) id <ASDataSyncContextDelegate> delegate;

- (void)initCloudWithContainerIdentifier:(NSString *)containerIdentifier databaseScope:(ASDatabaseScope)databaseScope __WATCHOS_UNAVAILABLE;
@property (nonatomic, assign) BOOL cloudEnabled __WATCHOS_UNAVAILABLE;
- (void)cloudReplication __WATCHOS_UNAVAILABLE;

- (void)acceptPushNotificationUserInfo:(NSDictionary *)userInfo __WATCHOS_UNAVAILABLE;
- (void)totalReplication __WATCHOS_UNAVAILABLE;
- (void)enableWatchSynchronization;

- (id)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

//Thread safe requests

- (void)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName fetch:(FetchObject)fetch;

- (void)insertTo:(NSString *)entityName fetch:(FetchObject)fetch;
- (void)deleteObject:(NSManagedObject *)object completion:(void (^)(void))completion;

- (void)selectFrom:(NSString *)entity fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity limit:(NSUInteger)limit fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch;

- (void)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause limit:(NSUInteger)limit fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch;

- (void)rollbackCompletion:(nullable void (^)(void))completion;
- (void)rollbackAndWait;

NS_ASSUME_NONNULL_END


@end
