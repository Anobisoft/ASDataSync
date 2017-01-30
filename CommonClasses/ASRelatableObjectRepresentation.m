//
//  ASRelatableObjectRepresentation.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#define ASDataSync_keyedReferences @"ASDataSync_descriptionsByRelationKey"
#define ASDataSync_keyedReferenceSets @"ASDataSync_keyedReferenceSets"

#import "ASRelatableObjectRepresentation.h"

@interface ASObjectRepresentation(protected)

- (instancetype)initWithMappedObject:(id <ASMappedObject>)object;

@end

@implementation ASRelatableObjectRepresentation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.keyedReferences forKey:ASDataSync_keyedReferences];
    [aCoder encodeObject:self.keyedReferenceSets forKey:ASDataSync_keyedReferenceSets];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _keyedReferences = [aDecoder decodeObjectForKey:ASDataSync_keyedReferences];
        _keyedReferenceSets = [aDecoder decodeObjectForKey:ASDataSync_keyedReferenceSets];
    }
    return self;
}

- (instancetype)initWithMappedObject:(id <ASMappedObject>)object {
    if (self = [super initWithMappedObject:object]) {
        if ([object conformsToProtocol:@protocol(ASRelatableToOne)]) {
            id <ASRelatableToOne> relatableToOneObject = (id <ASRelatableToOne>)object;
            NSMutableDictionary <NSString *, ASReference *> *tmpDict = [NSMutableDictionary new];
            NSDictionary <NSString *, id<ASReference>> *keyedReferences = relatableObject.keyedReferences;
            for (NSString *relationKey in keyedReferences.allKeys) {
                [tmpDict setObject:[ASReference instantiateWithReference:keyedReferences[relationKey]] forKey:relationKey];
            }
            _keyedReferences = tmpDict.copy;
        }
        if ([object conformsToProtocol:@protocol(ASRelatableToMany)]) {
            id <ASRelatableToMany> relatableToManyObject = (id <ASRelatableToMany>)object;
            NSMutableDictionary <NSString *, NSSet <ASReference *> *> *tmpDict = [NSMutableDictionary new];
            NSDictionary <NSString *, NSSet <id<ASReference>> *> *keyedSetOfReferences = relatableToManyObject.keyedSetOfReferences;
            for (NSString *relationKey in keyedSetOfReferences.allKeys) {
                NSMutableSet <ASReference *> *innerSet = [NSMutableSet new];
                for (id <ASReference> reference in keyedSetOfReferences[relationKey]) {
                    [innerSet addObject:[ASReference instantiateWithReference:reference]];
                }
                [tmpDict setObject:innerSet.copy forKey:relationKey];
            }
            _keyedReferenceSets = tmpDict.copy;
        }
    }
    return self;
}

+ (instancetype)instantiateWithMappedObject:(id <ASMappedObject>)object {
    return [[self alloc] initWithMappedObject:object];
}


@end
