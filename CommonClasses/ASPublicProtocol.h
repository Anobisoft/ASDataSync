//
//  ASPublicProtocol.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

@protocol ASManagedObject;
@protocol ASReference, ASMutableReference, ASDescription, ASMutableDescription, ASFindableEntity;
@protocol ASMappedObject, ASMutableMappedObject;
@protocol ASRelatable, ASRelatableToOne, ASMutableRelatableToOne, ASRelatableToMany, ASMutableRelatableToMany;
@protocol ASDataSyncContext, ASDataSyncContextDelegate, ASDataSyncSearchableContext;

#ifndef ASPublicProtocol_h
#define ASPublicProtocol_h

NS_ASSUME_NONNULL_BEGIN


#pragma mark - Synchronizable

@protocol ASManagedObject <ASMutableMappedObject, ASMutableReference, ASFindableEntity>
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

@protocol ASFindableEntity <NSObject>
@required
+ (NSString *)entityName;
+ (NSPredicate *)predicateWithUniqueData:(NSData *)uniqueData;
@end

@protocol ASMappedObject <ASDescription>
- (NSDate *)modificationDate;
- (NSDictionary <NSString *, id <NSSecureCoding>> *)keyedDataProperties;
@end

@protocol ASMutableMappedObject <ASMappedObject>
- (void)setModificationDate:(NSDate *)modificationDate;
- (void)setKeyedDataProperties:(NSDictionary <NSString *, id <NSCoding>> *)keyedDataProperties;
@end

#pragma mark - Relationships

@protocol ASRelatable
@required
+ (NSDictionary <NSString *, NSString *> *)entityNameByRelationKey;
@end

@protocol ASRelatableToOne <ASRelatable>
@required
- (NSDictionary <NSString *, id<ASReference>> *)keyedReferences;
@end

@protocol ASMutableRelatableToOne <ASRelatableToOne>
@required
- (void)replaceRelation:(NSString *)relationKey toReference:(id<ASReference>)reference;
@end

@protocol ASRelatableToMany <ASRelatable>
@required
- (NSDictionary <NSString *, NSSet <id<ASReference>> *> *)keyedSetOfReferences;
@end

@protocol ASMutableRelatableToMany <ASRelatableToMany>
@required
- (void)replaceRelation:(NSString *)relationKey toSetOfReferences:(NSSet <id<ASReference>> *)setOfReferences;
@end

#pragma mark - SynchronizableContext

@protocol ASDataSyncContext <NSObject>
@required
- (void)commit;
- (void)rollbackCompletion:(nullable void (^)(void))completion;
@property (nonatomic, weak) id <ASDataSyncContextDelegate> delegate;
@end

@protocol ASDataSyncContextDelegate <NSObject>
@optional
- (void)reloadData;
@end

@protocol ASDataSyncSearchableContext <NSObject>
- (id <ASReference>)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName;
@end

NS_ASSUME_NONNULL_END

#endif /* ASPublicProtocol_h */

