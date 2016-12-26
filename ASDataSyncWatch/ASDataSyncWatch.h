//
//  ASDataSyncWatch.h
//  ASDataSyncWatch
//
//  Created by Stanislav Pletnev on 27.10.16.
//  Copyright © 2016 anobisoft. All rights reserved.
//

#import <WatchKit/WatchKit.h>

//! Project version number for ASDataSyncWatch.
FOUNDATION_EXPORT double ASDataSyncWatchVersionNumber;

//! Project version string for ASDataSyncWatch.
FOUNDATION_EXPORT const unsigned char ASDataSyncWatchVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ASDataSyncWatch/PublicHeader.h>


#import "ASManagedObjectContext.h"
#import "ASynchronizable.h"
#import "ASynchronizablePrivate.h"
#import "ASDataSyncAgregator.h"
#import "ASWatchConnector.h"
#import "NSObject+ASDataSync.h"
#import "NSManagedObject+ASDataSync.h"
#import "NSManagedObjectContext+SQLike.h"
