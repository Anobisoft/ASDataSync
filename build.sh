#!/usr/local/bin/bash

UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal

# make sure the output directory exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

# Step 1. Build Device and Simulator versions on iOS
xcodebuild clean build -project "${PROJECT_NAME}.xcodeproj" -scheme "${PROJECT_NAME}" -sdk iphoneos
#xcodebuild clean build -project "${PROJECT_NAME}.xcodeproj" -scheme "${PROJECT_NAME}Watch" -sdk watchos -arch 'armv7k'
#xcodebuild clean build -project "${PROJECT_NAME}.xcodeproj" -scheme "${PROJECT_NAME}" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6'
#xcodebuild clean build -project "${PROJECT_NAME}.xcodeproj" -scheme "${PROJECT_NAME}Watch" -sdk watchsimulator -destination 'platform=watchOS Simulator,name=Apple Watch - 42mm' -arch 'x86_64'

# Step 2. Copy the framework structure (from iphoneos build) to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}"

# Step 3. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
"${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
#"${BUILD_DIR}/${CONFIGURATION}-watchos/${PROJECT_NAME}Watch.framework/${PROJECT_NAME}Watch" \
#"${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
#"${BUILD_DIR}/${CONFIGURATION}-watchsimulator/${PROJECT_NAME}Watch.framework/${PROJECT_NAME}Watch"

cp -r ${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework ~/Documents/


