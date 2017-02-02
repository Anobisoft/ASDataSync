//
//  CKReference+ASDataSync.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>

@interface CKReference (ASDataSync)

+ (instancetype)referenceWithUniqueData:(NSData *)uniqueData;
+ (instancetype)referenceWithUUIDString:(NSString *)UUIDString;

@end
