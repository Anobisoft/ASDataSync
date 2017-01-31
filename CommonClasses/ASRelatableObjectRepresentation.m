//
//  ASRelatableObjectRepresentation.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#define ASDataSync_keyedReferences @"ASDataSync_keyedReferences"
#define ASDataSync_keyedSetsOfReferences @"ASDataSync_keyedSetsOfReferences"

#import "ASRelatableObjectRepresentation.h"

@interface ASObjectRepresentation(protected)

- (instancetype)initWithMappedObject:(id <ASMappedObject>)object;

@end

@implementation ASRelatableObjectRepresentation

+ (NSDictionary<NSString *,NSString *> *)entityNameByRelationKey {
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.keyedReferences forKey:ASDataSync_keyedReferences];
    [aCoder encodeObject:self.keyedSetsOfReferences forKey:ASDataSync_keyedSetsOfReferences];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _keyedReferences = [aDecoder decodeObjectForKey:ASDataSync_keyedReferences];
        _keyedSetsOfReferences = [aDecoder decodeObjectForKey:ASDataSync_keyedSetsOfReferences];
    }
    return self;
}

- (instancetype)initWithMappedObject:(id <ASMappedObject>)object {
    if (self = [super initWithMappedObject:object]) {
        if ([object conformsToProtocol:@protocol(ASRelatableToOne)]) {
            id <ASRelatableToOne> relatableToOneObject = (id <ASRelatableToOne>)object;
            NSMutableDictionary <NSString *, ASReference *> *tmpDict = [NSMutableDictionary new];
            NSDictionary <NSString *, id<ASReference>> *keyedReferences = relatableToOneObject.keyedReferences;
            for (NSString *relationKey in keyedReferences.allKeys) {
                [tmpDict setObject:[ASReference instantiateWithReference:keyedReferences[relationKey]] forKey:relationKey];
            }
            _keyedReferences = tmpDict.copy;
        }
        if ([object conformsToProtocol:@protocol(ASRelatableToMany)]) {
            id <ASRelatableToMany> relatableToManyObject = (id <ASRelatableToMany>)object;
            NSMutableDictionary <NSString *, NSSet <ASReference *> *> *tmpDict = [NSMutableDictionary new];
            NSDictionary <NSString *, NSSet <id<ASReference>> *> *keyedSetsOfReferences = relatableToManyObject.keyedSetsOfReferences;
            for (NSString *relationKey in keyedSetsOfReferences.allKeys) {
                NSMutableSet <ASReference *> *innerSet = [NSMutableSet new];
                for (id <ASReference> reference in keyedSetsOfReferences[relationKey]) {
                    [innerSet addObject:[ASReference instantiateWithReference:reference]];
                }
                [tmpDict setObject:innerSet.copy forKey:relationKey];
            }
            _keyedSetsOfReferences = tmpDict.copy;
        }
    }
    return self;
}

+ (instancetype)instantiateWithMappedObject:(id <ASMappedObject>)object {
    return [[self alloc] initWithMappedObject:object];
}


@end
