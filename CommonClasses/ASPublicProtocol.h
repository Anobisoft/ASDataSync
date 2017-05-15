//
//  ASPublicProtocol.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

@protocol ASManagedObject;
@protocol ASReference, ASMutableReference, ASDescription, ASMutableDescription, ASFindableReference;
@protocol ASMappedObject, ASMutableMappedObject;
@protocol ASRelatable, ASRelatableToOne, ASMutableRelatableToOne, ASRelatableToMany, ASMutableRelatableToMany;
@protocol ASDataSyncContext, ASDataSyncContextDelegate, ASDataSyncSearchableContext;

#ifndef ASPublicProtocol_h
#define ASPublicProtocol_h

typedef NS_ENUM(NSInteger, ASDatabaseScope) {
    ASDatabaseScopeDefault = 0,
    ASDatabaseScopePublic,
    ASDatabaseScopePrivate,
    ASDatabaseScopeShared,
};

NS_ASSUME_NONNULL_BEGIN


#pragma mark - Synchronizable

@protocol ASManagedObject <ASMutableMappedObject, ASMutableReference, ASFindableReference>
@end


@protocol ASReference <NSObject>
@required
- (NSData *)uniqueData;
@optional
- (NSString *)UUIDString;
@end

@protocol ASMutableReference <ASReference>
@required
- (void)setUniqueData:(NSData *)uniqueData;
@optional
- (void)setUUIDString:(NSString *)UUIDString;
- (void)setUUID:(NSUUID *)UUID;
@end;

@protocol ASDescription <ASReference>
@required
- (NSString *)entityName;
@optional
+ (NSString *)recordType;
+ (NSString *)entityName;
@end

@protocol ASMutableDescription <ASDescription, ASMutableReference>
@end

@protocol ASFindableReference <ASReference>
@required
+ (NSString *)entityName;
+ (NSPredicate *)predicateWithUniqueData:(NSData *)uniqueData;
@end

@protocol ASMappedObject <ASDescription>
- (NSDate *)modificationDate;
- (NSDictionary <NSString *, NSObject<NSCoding> *> *)keyedDataProperties;
@end

@protocol ASMutableMappedObject <ASMappedObject>
- (void)setModificationDate:(NSDate *)modificationDate;
- (void)setKeyedDataProperties:(NSDictionary <NSString *, NSObject<NSCoding> *> *)keyedDataProperties;
@end

#pragma mark - Relationships

@protocol ASRelatable
@required
+ (NSDictionary <NSString *, NSString *> *)entityNameByRelationKey;
@end

@protocol ASRelatableToOne <ASRelatable>
@required
- (NSDictionary <NSString *, NSObject<ASReference> *> *)keyedReferences;
@end

@protocol ASMutableRelatableToOne <ASRelatableToOne>
@required
- (void)replaceRelation:(NSString *)relationKey toReference:(NSObject<ASReference> *)reference;
@end

@protocol ASRelatableToMany <ASRelatable>
@required
- (NSDictionary <NSString *, NSSet <NSObject<ASReference> *> *> *)keyedSetsOfReferences;
@end

@protocol ASMutableRelatableToMany <ASRelatableToMany>
@required
- (void)replaceRelation:(NSString *)relationKey toSetsOfReferences:(NSSet<NSObject<ASReference> *> *)setOfReferences;
@end

#pragma mark - SynchronizableContext

@protocol ASDataSyncContext <NSObject>
@required
- (void)commit;
- (void)rollbackCompletion:(nullable void (^)(void))completion;
#if TARGET_OS_IOS
- (void)acceptPushNotificationUserInfo:(NSDictionary *)userInfo;
#endif
@property (nonatomic, weak) id <ASDataSyncContextDelegate> delegate;
@end

@protocol ASDataSyncContextDelegate <NSObject>
@optional
- (void)reloadData;
@end

@protocol ASDataSyncSearchableContext <NSObject>
- (id <ASFindableReference>)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName;
@end



NS_ASSUME_NONNULL_END

#endif /* ASPublicProtocol_h */

