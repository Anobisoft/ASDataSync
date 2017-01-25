//
//  ASerializableObject.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#define AS_keyedPropertiesKey @"AS_keyedProperties"

#import "ASerializableObject.h"

@interface ASerializableDescription(protected)

- (instancetype)initWithSynchronizableDescription:(id <ASynchronizableDescription>)descriptionObj;

@end

@implementation ASerializableObject

@synthesize keyedProperties = _keyedProperties;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.keyedProperties forKey:AS_keyedPropertiesKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _keyedProperties = [aDecoder decodeObjectForKey:AS_keyedPropertiesKey];
    }
    return self;
}

- (instancetype)initWithSynchronizableObject:(id <ASynchronizableObject>)object {
    if (self = [super initWithSynchronizableDescription:object]) {
        _keyedProperties = object.keyedProperties;
    }
    return self;
}

+ (instancetype)instantiateWithSynchronizableObject:(id <ASynchronizableObject>)object {
    return [[self alloc] initWithSynchronizableObject:object];
}

@end
