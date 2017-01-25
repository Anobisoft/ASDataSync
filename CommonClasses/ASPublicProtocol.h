//
//  ASPublicProtocol.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

@protocol ASynchronizableDescription;
@protocol ASynchronizableObject;
@protocol ASynchronizableRelatableObject;
@protocol ASynchronizableMultiRelatableObject;

@protocol ASCloudReference;
@protocol ASCloudDescription;
@protocol ASCloudRecord;
@protocol ASCloudRelatableRecord;

@protocol ASynchronizableContextDelegate;
@protocol ASynchronizableContext;

#ifndef ASPublicProtocol_h
#define ASPublicProtocol_h

NS_ASSUME_NONNULL_BEGIN


#pragma mark - Synchronizable

@protocol ASynchronizableDescription <NSObject>
@required
@property (nullable, nonatomic, retain) NSData *uniqueData;
@property (nullable, nonatomic, copy) NSDate *modificationDate;
- (NSString *)entityName;
@optional
+ (NSString *)entityName;
+ (NSPredicate *)predicateWithUniqueData:(NSData *)uniqueData;
@property (nullable, nonatomic, retain) NSString *UUIDString;
@end

@protocol ASynchronizableObject <ASynchronizableDescription>
@property (nonnull, nonatomic, strong) NSDictionary <NSString *, id <NSCoding>> *keyedProperties;
@end

@protocol ASynchronizableRelatableObject <ASynchronizableObject>
@required
+ (NSString *)entityNameForRelationKey:(NSString *)relationKey;
- (NSDictionary <NSString *, id<ASynchronizableDescription>> *)relatedDescriptionByRelationKey;
- (void)replaceRelation:(NSString *)relationKey toObject:(nullable id<ASynchronizableDescription>)object;
@end

@protocol ASynchronizableMultiRelatableObject <ASynchronizableObject>
@required
+ (NSString *)entityNameForRelationKey:(NSString *)relationKey;
- (NSDictionary <NSString *, NSSet <id<ASynchronizableDescription>> *> *)relatedDescriptionSetByRelationKey;
- (void)replaceRelation:(NSString *)relationKey toObjectSet:(NSSet <id<ASynchronizableDescription>> *)objectSet;
@end


#pragma mark - Cloud

@protocol ASCloudReference <NSObject>
@required
- (NSData *)uniqueData;
@end

@protocol ASCloudDescription <ASCloudReference>
@required
- (NSString *)recordType;
@end

@protocol ASCloudRecord <ASCloudDescription>
@required
@property (nullable, nonatomic, copy) NSDate *modificationDate;
@property (nonnull, nonatomic, strong) NSDictionary <NSString *, id <NSCoding>> *keyedProperties;
@end

@protocol ASCloudRelatableRecord <ASCloudRecord>
@required
@property (nonatomic, strong) NSDictionary <NSString *, id <ASCloudReference>> *keyedReferences;
@property (nonatomic, strong) NSDictionary <NSString *, NSArray <id <ASCloudReference>> *> *keyedMultiReferences;
@end

#pragma mark - SynchronizableContext

@protocol ASynchronizableContextDelegate <NSObject>
@optional
- (void)reloadData;
@end

@protocol ASynchronizableContext <NSObject>
@required
- (void)commit;
- (void)rollbackCompletion:(nullable void (^)(void))completion;
@property (nonatomic, weak) id <ASynchronizableContextDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

#endif /* ASPublicProtocol_h */

