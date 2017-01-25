//
//  ASCloudReference.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 25.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASCloudReference.h"
#import "NSUUID+NSData.h"

@implementation CKRecordID(ASDataSync)

- (NSUUID *)UUID {
    return [[NSUUID alloc] initWithUUIDString:self.recordName];
}

@end

@implementation ASCloudReference

- (NSData *)uniqueData {
    return [self UUID].data;
}

+ (instancetype)referenceWithUniqueData:(NSData *)uniqueData {
    return [[super alloc] initWithRecordName:uniqueData.UUIDString];
}

+ (instancetype)referenceWithRecordName:(NSString *)recordName {
    return [[super alloc] initWithRecordName:recordName];
}



@end
