//
//  ASRepresentableTransaction.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASRepresentableTransaction.h"

@implementation ASRepresentableTransaction {
    NSString *contextIdentifier;
    NSSet <NSObject <ASMappedObject> *> *updatedObjects;
    NSSet <NSObject <ASDescription> *> *deletedObjects;
}

- (NSString *)contextIdentifier {
    return contextIdentifier;
}

- (NSSet <NSObject <ASMappedObject> *> *)updatedObjects {
    return updatedObjects;
}

- (NSSet <NSObject <ASDescription> *> *)deletedObjects {
    return deletedObjects;
}

+ (instancetype)instantiateWithContext:(id <ASRepresentableTransaction>)context {
    return [[self alloc] initWithContext:context];
}

- (instancetype)initWithContext:(id <ASRepresentableTransaction>)context {
    if (self = [super init]) {
        contextIdentifier = context.contextIdentifier;
        updatedObjects = context.updatedObjects.copy;
        
    }
    return self;
}

@end
