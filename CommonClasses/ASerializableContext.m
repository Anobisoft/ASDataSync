//
//  ASerializableContext.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#define AS_identifierKey @"AS_identifier"
#define AS_updatedObjectsKey @"AS_updatedObjects"
#define AS_deletedObjectsKey @"AS_deletedObjects"

#import "ASerializableContext.h"
#import "ASynchronizablePrivate.h"

@implementation ASerializableContext

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:AS_identifierKey];
    [aCoder encodeObject:_updatedObjects forKey:AS_updatedObjectsKey];
    [aCoder encodeObject:_deletedObjects forKey:AS_deletedObjectsKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _identifier = [aDecoder decodeObjectForKey:AS_identifierKey];
        _updatedObjects = [aDecoder decodeObjectForKey:AS_updatedObjectsKey];
        _deletedObjects = [aDecoder decodeObjectForKey:AS_deletedObjectsKey];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _identifier = [NSUUID UUID].UUIDString;
    }
    return self;
}

- (instancetype)initWithSynchronizableContext:(id <ASynchronizableContextPrivate>)context {
    if (self = [super init]) {
        _identifier = context.identifier;
        NSDate *creationDate = [NSDate date];
        NSSet <id <ASynchronizableObject>>* updatedObjects = context.updatedObjects;
        if (updatedObjects.count) {
            NSMutableSet <ASerializableObject *> *tmpUSet = [NSMutableSet new];
            for (id <ASynchronizableObject> obj in updatedObjects) {
                obj.modificationDate = creationDate;
                [tmpUSet addObject:[ASerializableRelatableObject instantiateWithSynchronizableObject:obj]];
            }
            _updatedObjects = tmpUSet.copy;
        } else {
            _updatedObjects = nil;
        }
        
        NSSet <id <ASynchronizableDescription>>* deletedObjects = context.deletedObjects;
        if (deletedObjects.count) {
            NSMutableSet <ASerializableDescription *> *tmpSet = [NSMutableSet new];
            for (id <ASynchronizableDescription> desc in deletedObjects) {
                [tmpSet addObject:[ASerializableDescription instantiateWithSynchronizableDescription:desc]];
            }
            _deletedObjects = tmpSet.copy;
        } else {
            _deletedObjects = nil;
        }
    }
    return (_deletedObjects || _updatedObjects) ? self : nil;
}

+ (instancetype)instantiateWithSynchronizableContext:(id <ASynchronizableContextPrivate>)context {
    return [[self alloc] initWithSynchronizableContext:context];
}


@end
