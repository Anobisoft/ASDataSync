//
//  ASerializableRelatableObject.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#define AS_descriptionByRelationKey @"AS_descriptionsByRelationKey"
#define AS_setOfDescriptionsByRelationKey @"AS_setOfDescriptionsByRelationKey"

#import "ASerializableRelatableObject.h"

@interface ASerializableDescription(protected)

- (instancetype)initWithSynchronizableObject:(id <ASynchronizableObject>)object;

@end

@implementation ASerializableRelatableObject

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.descriptionByRelationKey forKey:AS_descriptionByRelationKey];
    [aCoder encodeObject:self.setOfDescriptionsByRelationKey forKey:AS_setOfDescriptionsByRelationKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _descriptionByRelationKey = [aDecoder decodeObjectForKey:AS_descriptionByRelationKey];
        _setOfDescriptionsByRelationKey = [aDecoder decodeObjectForKey:AS_setOfDescriptionsByRelationKey];
    }
    return self;
}

- (instancetype)initWithSynchronizableObject:(id <ASynchronizableObject>)object {
    if (self = [super initWithSynchronizableObject:object]) {
        if ([object conformsToProtocol:@protocol(ASynchronizableRelatableObject)]) {
            id <ASynchronizableRelatableObject> relatableObject = (id <ASynchronizableRelatableObject>)object;
            NSMutableDictionary <NSString *, ASerializableDescription *> *tmpDict = [NSMutableDictionary new];
            NSDictionary <NSString *, id<ASynchronizableDescription>> *relatedDescriptionByRelationKey = [relatableObject relatedDescriptionByRelationKey];
            for (NSString *relationKey in relatedDescriptionByRelationKey.allKeys) {
                [tmpDict setObject:[ASerializableDescription instantiateWithSynchronizableDescription:relatedDescriptionByRelationKey[relationKey]] forKey:relationKey];
            }
            _descriptionByRelationKey = tmpDict.copy;
        }
        if ([object conformsToProtocol:@protocol(ASynchronizableMultiRelatableObject)]) {
            id <ASynchronizableMultiRelatableObject> multiRelatableObject = (id <ASynchronizableMultiRelatableObject>)object;
            NSMutableDictionary <NSString *, ASerializableDescription *> *tmpDict = [NSMutableDictionary new];
            NSDictionary <NSString *, NSSet <id<ASynchronizableDescription>> *> *relatedDescriptionSetByRelationKey = [multiRelatableObject relatedDescriptionSetByRelationKey];
            for (NSString *relationKey in relatedDescriptionSetByRelationKey.allKeys) {
                NSMutableSet <ASerializableDescription *> *innerSet = [NSMutableSet new];
                for (id <ASynchronizableDescription> relatedDescription in relatedDescriptionSetByRelationKey[relationKey]) {
                    [innerSet addObject:[ASerializableDescription instantiateWithSynchronizableDescription:relatedDescription]];
                }
                [tmpDict setObject:innerSet.copy forKey:relationKey];
            }
            _setOfDescriptionsByRelationKey = tmpDict.copy;
        }
    }
    return self;
}

+ (instancetype)instantiateWithSynchronizableObject:(id <ASynchronizableObject>)object {
    return [[self alloc] initWithSynchronizableObject:object];
}


@end
