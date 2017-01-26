//
//  ASDataSync.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 27.10.16.
//  Copyright © 2016 anobisoft. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for ASDataSync.
FOUNDATION_EXPORT double ASDataSyncVersionNumber;

//! Project version string for ASDataSync.
FOUNDATION_EXPORT const unsigned char ASDataSyncVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ASDataSync/PublicHeader.h>


#import "ASManagedObjectContext.h"
#import "ASPublicProtocol.h"
#import "ASCloudManager.h"
#import "ASWatchConnector.h"
#import "NSManagedObject+ASDataSync.h"
#import "NSManagedObjectContext+SQLike.h"
#import "NSUUID+NSData.h"
#import "ASNull.h"
