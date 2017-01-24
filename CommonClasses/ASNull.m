//
//  ASNull.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 23.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASNull.h"
#import "ASynchronizable.h"

@implementation ASNull

+ (instancetype)null {
    return [[self alloc] init];
}

- (NSString *)entityName {
    return nil;
}

+ (NSPredicate *)predicateWithUniqueData:(NSData *)uniqueData {
    return nil;
}

- (NSData *)uniqueData {
    return nil;
}

- (void)setUniqueData:(NSData *)uniqueData {
    
}

- (NSDate *)modificationDate {
    return nil;
}

- (void)setModificationDate:(NSDate *)modificationDate {
    
}

@end
