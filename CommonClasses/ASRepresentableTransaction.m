//
//  ASRepresentableTransaction.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "ASRepresentableTransaction.h"

@implementation ASRepresentableTransaction {
    NSString *_contextIdentifier;
    NSSet <NSObject <ASMappedObject> *> *_updatedObjects;
    NSSet <NSObject <ASDescription> *> *_deletedObjects;
}

- (NSString *)contextIdentifier {
    return _contextIdentifier;
}

- (NSSet <NSObject <ASMappedObject> *> *)updatedObjects {
    return _updatedObjects;
}

- (NSSet <NSObject <ASDescription> *> *)deletedObjects {
    return _deletedObjects;
}

+ (instancetype)instantiateWithContext:(id <ASRepresentableTransaction>)context {
    return [[self alloc] initWithContext:context];
}

- (instancetype)initWithContext:(id <ASRepresentableTransaction>)context {
    if (self = [super init]) {
        _contextIdentifier = context.contextIdentifier;
        _updatedObjects = context.updatedObjects.copy;
        _deletedObjects = context.deletedObjects.copy;
    }
    return self;
}

- (void)addObjects:(NSSet<NSObject<ASMappedObject> *> *)objects {
    if (!_updatedObjects) _updatedObjects = [NSSet set];
    _updatedObjects = [_updatedObjects setByAddingObjectsFromSet:objects];
}

@end
