//
//  ASRelatableObjectRepresentation.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#ifndef ASRelatableObjectRepresentation_h
#define ASRelatableObjectRepresentation_h

#import <Foundation/Foundation.h>
#import "ASObjectRepresentation.h"

@interface ASRelatableObjectRepresentation : ASObjectRepresentation <ASRelatableToOne, ASRelatableToMany>

@property (nonatomic, strong, readonly) NSDictionary <NSString *, ASReference *> *keyedReferences;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSSet <ASReference *> *> *keyedSetsOfReferences;

@end

#endif
