#!/bin/bash

#  UnitTest.sh
#  YuMeZISTestApp
#
#  Created by yume on 10/29/15.
#  Copyright © 2015 YuMe. All rights reserved.

#import path
export PATH=${PATH}:/usr/local/bin

YUME_TEST_SCHEME=YuMeZISTests

# Run test and get JUnit report XML
xctool -workspace ${WORKSPACE}/YuMeTestApp/YuMeZISTestApp.xcworkspace -scheme $YUME_TEST_SCHEME -reporter plain -sdk iphonesimulator -reporter junit:test-reports/yume_test-report.xml test -resetSimulator -freshInstall



############## Testing ###########
# XCTool Setup Path
#XCTOOL_HOME=/usr/local/Cellar/xctool/0.2.6
#export PATH=$XCTOOL_HOME/bin:$PATH

#SCHEME_NAME=YuMeZISTests
#TEST_REPORT_FILE="bin/yume_report/test-result.xml"

#PROJECT_FOLDER=YuMeTestApp
#PROJECT=$PROJECT_FOLDER/YuMeZISTestApp
#PWORKSPACE=$PROJECT.xcworkspace

#echo "<<<<<<<<<<<<<<<<<<<<<<< UNIT TEST START >>>>>>>>>>>>>>>>>>>>>>>>>>>"

#xcodebuild -sdk iphonesimulator -workspace $WORKSPACE/$PWORKSPACE -scheme $SCHEME_NAME -configuration Debug RUN_APPLICATION_TESTS_WITH_IOS_SIM=YES ONLY_ACTIVE_ARCH=NO clean build          
    
#xctool -workspace "$WORKSPACE/$PWORKSPACE" -scheme $SCHEME_NAME -sdk iphonesimulator -reporter plain -reporter junit:$TEST_REPORT_FILE test
    
    #-IDECustomDerivedDataLocation=$BUILD_PATH \
	#GCC_GENERATE_TEST_COVERAGE_FILES=YES GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES \
    
#echo "<<<<<<<<<<<<<<<<<<<<<<< UNIT TEST END >>>>>>>>>>>>>>>>>>>>>>>>>>>"
