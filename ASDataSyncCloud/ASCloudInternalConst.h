//
//  ASCloudInternalConst.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#ifndef ASCloudInternalConst_h
#define ASCloudInternalConst_h

#define ASCloudLastSyncDateForEntityUDKey @"ASCloudLastSyncDateForEntity"
#define ASCloudPreparedToCloudRecordsUDKey @"ASCloudPreparedToCloudRecords"

#define ASCloudDevicesInfoRecordType @"Device"

#define ASCloudDeletionInfoRecordType @"DeleteQueue"
#define ASCloudDeletionInfoRecordProperty_recordType @"dq_recordType"
#define ASCloudDeletionInfoRecordProperty_recordID @"dq_recordID"
#define ASCloudDeletionInfoRecordProperty_deviceID @"dq_deviceID"

#define ASCloudRealModificationDateProperty @"changeDate"

#define ASCloudInitTimeout 60
#define ASCloudTryToPushTimeout 60
#define ASCloudSmartReplicationTimeout 60

#endif /* ASCloudInternalConst_h */
