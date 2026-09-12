#!/bin/bash
set -e

XCODEBUILD_DEVICE_ID="00008120-00110DC93C05A01E"
DEVICECTL_DEVICE_ID="15D2CDB6-F7EA-5C8F-9208-54E16A00FFB2"
BUNDLE_ID="com.michelleconchina.ExpenseTracker"
DERIVED_DATA="$HOME/.xcode-builds/ExpenseTracker"

xcodebuild \
  -project ExpenseTracker.xcodeproj \
  -scheme ExpenseTracker \
  -configuration Debug \
  -destination "platform=iOS,id=$XCODEBUILD_DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/ExpenseTracker.app"

xcrun devicectl device install app --device "$DEVICECTL_DEVICE_ID" "$APP_PATH"
xcrun devicectl device process launch --device "$DEVICECTL_DEVICE_ID" "$BUNDLE_ID"
