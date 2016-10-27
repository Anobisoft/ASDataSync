//
//  NSString+LogLevel.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "NSString+LogLevel.h"
#import <asl.h>

@implementation NSString (LogLevel)

- (void)logEmergency {
    [self loglvl:ASL_LEVEL_EMERG];
}

- (void)logAlert {
    [self loglvl:ASL_LEVEL_ALERT];
}

- (void)logCritical {
    [self loglvl:ASL_LEVEL_CRIT];
}

- (void)logError {
    [self loglvl:ASL_LEVEL_ERR];
}

- (void)logWarning {
    [self loglvl:ASL_LEVEL_WARNING];
}

- (void)logNotice {
    [self loglvl:ASL_LEVEL_NOTICE];
}

- (void)logInfo {
    [self loglvl:ASL_LEVEL_INFO];
}

- (void)logDebug {
    [self loglvl:ASL_LEVEL_DEBUG];
}

- (void)loglvl:(int)lvl {
#ifdef DEBUG
    NSLog(@"%@", self);
#else
    asl_log(NULL, NULL, lvl, "%s", [self cStringUsingEncoding:NSUTF8StringEncoding]);
#endif
    
}

@end
