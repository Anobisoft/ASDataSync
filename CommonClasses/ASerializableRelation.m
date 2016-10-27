//
//  ASerializableRelation.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#define AS_descriptionKey @"AS_description"
#define AS_relatedDescriptionKey @"AS_relatedDescription"
#define AS_relationKey @"AS_relationKey"

#import "ASerializableRelation.h"

@implementation ASerializableRelation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.objectDescription forKey:AS_descriptionKey];
    [aCoder encodeObject:self.relatedDescription forKey:AS_relatedDescriptionKey];
    [aCoder encodeObject:self.relationKey forKey:AS_relationKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.objectDescription = [aDecoder decodeObjectForKey:AS_descriptionKey];
        self.relatedDescription = [aDecoder decodeObjectForKey:AS_relatedDescriptionKey];
        self.relationKey = [aDecoder decodeObjectForKey:AS_relationKey];
    }
    return self;
}

- (instancetype)initWithSynchronizableDescription:(id<ASynchronizableDescription>)descriptionObj relatedDescription:(id <ASynchronizableDescription>)relatedDescription relationKey:(NSString *)relationKey {
    if (self = [super init]) {
        self.objectDescription = [ASerializableDescription instantiateWithSynchronizableDescription:descriptionObj];
        self.relatedDescription = [ASerializableDescription instantiateWithSynchronizableDescription:relatedDescription];
    }
    return self;
}

+ (instancetype)instantiateWithSynchronizableDescription:(id<ASynchronizableDescription>)descriptionObj relatedDescription:(id <ASynchronizableDescription>)relatedDescription relationKey:(NSString *)relationKey {
    return [[self alloc] initWithSynchronizableDescription:descriptionObj relatedDescription:relatedDescription relationKey:(NSString *)relationKey];
}


@end
