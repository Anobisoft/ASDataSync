//
//  ASObjectRepresentation.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#define ASDataSync_modificationDateKey @"ASDataSync_modificationDate"
#define ASDataSync_keyedDataPropertiesKey @"ASDataSync_keyedDataProperties"

#import "ASObjectRepresentation.h"

@interface ASDescriptionRepresentation(protected)

- (instancetype)initWithDescription:(id <ASDescription>)description;

@end

@implementation ASObjectRepresentation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_modificationDate forKey:ASDataSync_modificationDateKey];
    [aCoder encodeObject:_keyedDataProperties forKey:ASDataSync_keyedDataPropertiesKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _modificationDate = [aDecoder decodeObjectForKey:ASDataSync_modificationDateKey];
        _keyedDataProperties = [aDecoder decodeObjectForKey:ASDataSync_keyedDataPropertiesKey];
    }
    return self;
}

+ (instancetype)instantiateWithMappedObject:(NSObject<ASMappedObject> *)object {
    return [[self alloc] initWithMappedObject:object];
}

- (instancetype)initWithMappedObject:(NSObject<ASMappedObject> *)object {
    if (self = [super initWithDescription:object]) {
        _modificationDate = object.modificationDate;
        NSMutableDictionary *mutableProperties = object.keyedDataProperties.mutableCopy;
        for (NSString *key in object.keyedDataProperties.allKeys)
            if ([object.keyedDataProperties[key] isKindOfClass:[NSNull class]]) [mutableProperties removeObjectForKey:key];
        _keyedDataProperties = mutableProperties.copy;
    }
    return self;
}

@end
