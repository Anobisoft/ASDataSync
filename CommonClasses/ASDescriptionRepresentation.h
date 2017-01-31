//
//  ASDescriptionRepresentation.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#ifndef ASDescriptionRepresentation_h
#define ASDescriptionRepresentation_h

#import <Foundation/Foundation.h>
#import "ASReference.h"

@interface ASDescriptionRepresentation : ASReference <ASDescription>

+ (instancetype)instantiateWithDescription:(id <ASDescription>)description;

@property (nonatomic, strong, readonly) NSString *entityName;

@end

#endif
