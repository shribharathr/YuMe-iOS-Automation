#!/bin/sh

cd $WORKSPACE/YuMeTestApp/

#!/usr/bin/env bash

function init() {
	PROJECT=YuMeZISTestApp
	WORKSPACE=$PROJECT.xcworkspace
	PROJECT_FILE=$PROJECT.xcodeproj
	SCHEME_NAME=YuMeZISTests
}

init

# Clean up generated schemes.
rm -rf $PROJECT_FILE/xcuserdata/*.xcuserdatad/xcschemes

# Listing all information about project
xcodebuild -list -project $PROJECT_FILE

# Clean all targets
xcodebuild -alltargets clean

# define paths
BUILD_PATH="bin/yume_build"

COVERAGE_INFO="bin/coverage.info"
COVERAGE_CSDK_INFO="bin/coverage-csdk.info"
REPORT_PATH="bin/coverage_report"
REPORT_FILE="bin/coverage.xml"

# cleanup the output directory first
rm -rf $BUILD_PATH
