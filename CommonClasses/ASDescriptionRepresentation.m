//
//  ASDescriptionRepresentation.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASDescriptionRepresentation.h"

#define ASDataSync_entityNameKey @"ASDataSync_entityName"

@interface ASReference(protected)

- (instancetype)initWithReference:(id <ASReference>)reference;

@end

@implementation ASDescriptionRepresentation {
    NSString *_entityName;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_entityName forKey:ASDataSync_entityNameKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _entityName = [aDecoder decodeObjectForKey:ASDataSync_entityNameKey];
    }
    return self;
}


- (instancetype)initWithDescription:(id <ASDescription>)description {
    if (self = [super initWithReference:description]) {
        _entityName = description.entityName;
    }
    return self;
}

+ (instancetype)instantiateWithDescription:(id <ASDescription>)description {
    return [[self alloc] initWithDescription:description];
}

- (NSString *)entityName {
    return _entityName;
}

@end
