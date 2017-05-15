//
//  ASCloudInternalConst.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#ifndef ASCloudInternalConst_h
#define ASCloudInternalConst_h

#define ASCloudMaxModificationDateForEntityUDKey @"ASCloudMaxModificationDateForEntity"
#define ASCloudPreparedToCloudRecordsUDKey @"ASCloudPreparedToCloudRecords"

#define ASCloudDevicesInfoRecordType @"ASDevice"

#define ASCloudDeletionInfoRecordType @"ASDeletionInfo"
#define ASCloudDeletionInfoRecordProperty_recordType @"ASDI_recordType"
#define ASCloudDeletionInfoRecordProperty_recordID @"ASDI_recordID"
#define ASCloudDeletionInfoRecordProperty_deviceID @"ASDI_deviceID"

#define ASCloudRealModificationDateProperty @"realModificationDate"

#define ASCloudInitTimeout 60
#define ASCloudTryToPushTimeout 60
#define ASCloudSmartReplicationTimeout 60

#endif /* ASCloudInternalConst_h */
