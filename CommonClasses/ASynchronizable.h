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
@protocol ASynchronizableObjectDelegate;

#ifndef ASynchronizable_h
#define ASynchronizable_h

#import "ASWatchConnector.h"
NS_ASSUME_NONNULL_BEGIN

@protocol ASynchronizableDescription <NSObject>
@required
@property (nullable, nonatomic, retain) NSData *uniqueID;
@property (nullable, nonatomic, copy) NSDate *modifyDate;
+ (NSString *)entityName;
+ (NSPredicate *)predicateWithUniqueID:(NSData *)uniqueID;
@optional
@property (nullable, nonatomic, retain) NSString *UUIDString;
@end

@protocol ASynchronizableObject <ASynchronizableDescription>
@property (nonnull, nonatomic, strong) NSDictionary <NSString *, id <NSCoding>> *keyedProperties;
@optional
@property (nullable, nonatomic, weak) id <ASynchronizableObjectDelegate> delegate;
@end

@protocol ASynchronizableRelatableObject <ASynchronizableObject>
@required
- (NSDictionary <NSString *, NSSet <id<ASynchronizableObject>> *> *)relatedObjectsByRelationKey;
- (void)setRelation:(NSString *)relationKey toObject:(id<ASynchronizableObject>)object;
@optional
- (void)clearRelationsToSetRecieved;
@end

@protocol ASynchronizableObjectDelegate <NSObject>
@required
- (void)updateObject:(id <ASynchronizableObject>)object;
@end

@protocol ASynchronizableContextDelegate <NSObject>
@optional
- (void)reloadData;
@end

@protocol ASynchronizableContext <NSObject>
@required
- (void)commit;
- (void)rollback;
@optional
@property (nonatomic, weak) id <ASynchronizableContextDelegate> delegate;
@end

NS_ASSUME_NONNULL_END

#endif /* ASynchronizable_h */

