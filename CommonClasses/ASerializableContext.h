//
//  ASerializableContext.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#ifndef ASerializableContext_h
#define ASerializableContext_h

#import "ASerializableObject.h"
#import "ASerializableRelation.h"
#import "ASynchronizable.h"

@interface ASerializableContext : NSObject <NSCoding>

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSSet <ASerializableObject *> *updatedObjects;
@property (nonatomic, strong) NSSet <ASerializableDescription *> *deletedObjects;
@property (nonatomic, strong) NSSet <ASerializableRelation *> *relations;

+ (instancetype)instantiateWithSynchronizableContext:(id <ASynchronizableContext>)context;

@end

#endif