//
//  ASLocalTransaction.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 03.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASLocalTransaction.h"

@implementation ASLocalTransaction

- (NSString *)contextIdentifier {
    return mutable.copy;
}
- (NSSet <NSObject <ASMappedObject> *> *)updatedObjects {
    
}
- (NSSet <NSObject <ASDescription> *> *)deletedObjects {
    
}

@end
