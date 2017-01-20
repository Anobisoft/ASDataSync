//
//  NSUUID+NSData.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUUID (NSData)

- (NSData *)data;
+ (instancetype)uuidWithData:(NSData *)data;

@end
