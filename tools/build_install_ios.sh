#!/bin/bash

# Variables
WORKSPACE="ios/Runner.xcworkspace"
SCHEME="Runner"
APPNAME="LibmuyEnglish"
ARCHIVE_PATH="./build/$APPNAME.xcarchive"
EXPORT_PATH="./build"
EXPORT_OPTIONS_PLIST="./tools/ios_build_export_options.plist"

# Step 1: Build the app
xcodebuild -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           -archivePath "$ARCHIVE_PATH" archive

# Step 2: Export the .ipa file
xcodebuild -exportArchive \
           -archivePath "$ARCHIVE_PATH" \
           -exportPath "$EXPORT_PATH" \
           -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

# Step 3: Install the app on the device
ios-deploy --bundle "$EXPORT_PATH/$APPNAME.ipa"
