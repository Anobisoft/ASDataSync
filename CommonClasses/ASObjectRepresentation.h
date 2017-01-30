//
//  ASObjectRepresentation.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#ifndef ASObjectRepresentation_h
#define ASObjectRepresentation_h

#import <Foundation/Foundation.h>
#import "ASDescriptionRepresentation.h"

@interface ASObjectRepresentation : ASDescriptionRepresentation <ASMappedObject>

+ (instancetype)instantiateWithMappedObject:(id <ASMappedObject>)object;

@property (nonatomic, strong) NSDate *_modificationDate;
@property (nonatomic, strong) NSDictionary <NSString *, id <NSSecureCoding>> *_keyedDataProperties;

@end

#endif
