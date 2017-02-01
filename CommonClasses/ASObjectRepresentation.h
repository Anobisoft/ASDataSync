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

@interface ASObjectRepresentation : ASDescriptionRepresentation <ASMappedObject> {
    @protected
    NSDate *_modificationDate;
    NSDictionary <NSString *, NSObject<NSCoding> *> *_keyedDataProperties;
}

+ (instancetype)instantiateWithMappedObject:(NSObject<ASMappedObject> *)object;

@property (nonatomic, strong, readonly) NSDate *modificationDate;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSObject<NSCoding> *> *keyedDataProperties;

@end

#endif
