//
//  ASynchronizable.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

@protocol ASynchronizableDescription;
@protocol ASynchronizableObject;
@protocol ASynchronizableRelatableObject;

#ifndef ASynchronizable_h
#define ASynchronizable_h

#import "ASWatchConnector.h"
NS_ASSUME_NONNULL_BEGIN

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
    - (NSDictionary <NSString *, id<ASynchronizableDescription>> *)relatedDescriptionByRelationKey;
    - (void)replaceRelation:(NSString *)relationKey toObject:(nullable id<ASynchronizableDescription>)object;
@end

@protocol ASynchronizableMultiRelatableObject <ASynchronizableObject>
@required
- (NSDictionary <NSString *, NSSet <id<ASynchronizableDescription>> *> *)relatedDescriptionSetByRelationKey;
- (void)replaceRelation:(NSString *)relationKey toObjectSet:(NSSet <id<ASynchronizableDescription>> *)objectSet;
@end

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

#endif /* ASynchronizable_h */

