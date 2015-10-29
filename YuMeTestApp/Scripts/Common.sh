#!/bin/sh

#  Common.sh
#  YuMeZISTestApp
#
#  Created by yume on 10/29/15.
#  Copyright © 2015 YuMe. All rights reserved.


#import path
export PATH=${PATH}:/usr/local/bin

#check for oclint
hash oclint &> /dev/null
if [ $? -eq 1 ]; then
echo >&2 "oclint not found, analyzing stopped"
exit 1
fi

hash xctool &> /dev/null
if [ $? -eq 1 ]; then
echo >&2 "xctool not found, analyzing stopped"
exit 1
fi

hash gcovr &> /dev/null
if [ $? -eq 1 ]; then
echo >&2 "gcovr not found, analyzing stopped"
exit 1
fi

hash sloccount &> /dev/null
if [ $? -eq 1 ]; then
echo >&2 "sloccount not found, analyzing stopped"
exit 1
fi

output_dir=test-reports
if [ ! -L "$output_dir" ]
then
echo "File doesn't exist. Creating now"
mkdir -p -- "$output_dir"
echo "File created"
else
echo "File exists"
fi

YUME_TEST_SCHEME=YuMeZISTests



#cd $WORKSPACE/YuMeTestApp/

#!/usr/bin/env bash

#function init() {
#	PROJECT=YuMeZISTestApp
#	WORKSPACE=$PROJECT.xcworkspace
#	PROJECT_FILE=$PROJECT.xcodeproj
#	SCHEME_NAME=YuMeZISTests
#}

#init

# Clean up generated schemes.
#rm -rf $PROJECT_FILE/xcuserdata/*.xcuserdatad/xcschemes

# Listing all information about project
#xcodebuild -list -project $PROJECT_FILE

# Clean all targets
#xcodebuild -alltargets clean

# define paths
#BUILD_PATH="bin/yume_build"

#COVERAGE_INFO="bin/coverage.info"
#COVERAGE_CSDK_INFO="bin/coverage-csdk.info"
#REPORT_PATH="bin/coverage_report"
#REPORT_FILE="bin/coverage.xml"

# cleanup the output directory first
#rm -rf $BUILD_PATH
