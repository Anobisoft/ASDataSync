//
//  ASCloudReference.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 25.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASCloudReference.h"

@implementation ASCloudReference

+ (instancetype)recordIDWithUniqueData:(NSData *)uniqueData {
    return [[super alloc] initWithRecordName:uniqueData.UUIDString];
}

+ (instancetype)recordIDWithRecordName:(NSString *)recordName {
    return [[super alloc] initWithRecordName:recordName];
}

- (NSUUID *)UUID {
    return [[NSUUID alloc] initWithUUIDString:self.recordName];
}


@end
