//
//  ASDevice.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASObjectRepresentation.h"

@interface ASDevice : ASObjectRepresentation

+ (instancetype)deviceWithMappedObject:(id <ASMappedObject>)mappedObject;

@end
