#!/usr/local/bin/bash

xcodebuild clean build -project "${PROJECT_NAME}.xcodeproj" -scheme "${PROJECT_NAME}" -sdk iphoneos
xcodebuild clean build -project "${PROJECT_NAME}.xcodeproj" -scheme "${PROJECT_NAME}Watch" -sdk watchos -arch 'armv7k'

cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework" ~/Documents/
cp -R "${BUILD_DIR}/${CONFIGURATION}-watchos/${PROJECT_NAME}Watch.framework" ~/Documents/

