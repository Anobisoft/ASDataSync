//
//  ASTransactionRepresentation.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#define ASDataSync_contextIdentifierKey @"ASDataSync_contextIdentifier"
#define ASDataSync_updatedObjectsKey @"ASDataSync_updatedObjects"
#define ASDataSync_deletedObjectsKey @"ASDataSync_deletedObjects"

#import "ASTransactionRepresentation.h"
#import "ASPrivateProtocol.h"

@implementation ASTransactionRepresentation {
    NSString *_contextIdentifier;
    NSSet *_updatedObjects;
    NSSet *_deletedObjects;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_contextIdentifier forKey:ASDataSync_contextIdentifierKey];
    [aCoder encodeObject:_updatedObjects forKey:ASDataSync_updatedObjectsKey];
    [aCoder encodeObject:_deletedObjects forKey:ASDataSync_deletedObjectsKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _contextIdentifier = [aDecoder decodeObjectForKey:ASDataSync_contextIdentifierKey];
        _updatedObjects = [aDecoder decodeObjectForKey:ASDataSync_updatedObjectsKey];
        _deletedObjects = [aDecoder decodeObjectForKey:ASDataSync_deletedObjectsKey];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _contextIdentifier = [NSUUID UUID].UUIDString;
    }
    return self;
}

- (instancetype)initWithRepresentableTransaction:(id <ASRepresentableTransaction>)transaction {
    if (self = [super init]) {
        _contextIdentifier = transaction.contextIdentifier;
        NSDate *creationDate = [NSDate date];
        NSSet <id <ASMappedObject>>* updatedObjects = transaction.updatedObjects;
        if (updatedObjects.count) {
            NSMutableSet <ASRelatableObjectRepresentation *> *tmpUSet = [NSMutableSet new];
            for (id <ASMappedObject> updatedObject in updatedObjects) {
                [tmpUSet addObject:[ASRelatableObjectRepresentation instantiateWithMappedObject:updatedObject]];
            }
            _updatedObjects = tmpUSet.copy;
        } else {
            _updatedObjects = nil;
        }
        
        NSSet <id <ASDescription>>* deletedObjects = transaction.deletedObjects;
        if (deletedObjects.count) {
            NSMutableSet <ASDescriptionRepresentation *> *tmpSet = [NSMutableSet new];
            for (id <ASDescription> description in deletedObjects) {
                [tmpSet addObject:[ASDescriptionRepresentation instantiateWithDescription:description]];
            }
            _deletedObjects = tmpSet.copy;
        } else {
            _deletedObjects = nil;
        }
    }
    return (_deletedObjects || _updatedObjects) ? self : nil;
}

+ (instancetype)instantiateWithRepresentableTransaction:(id <ASRepresentableTransaction>)transaction {
    return [[self alloc] initWithRepresentableTransaction:transaction];
}


@end
