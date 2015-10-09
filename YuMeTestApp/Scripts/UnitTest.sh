#!/bin/bash

# XCTool Setup Path
XCTOOL_HOME=/usr/local/Cellar/xctool/0.2.5
export PATH=$XCTOOL_HOME/bin:$PATH

SCHEME_NAME=YuMeZISTests
TEST_REPORT_FILE="bin/yume_report/test-result.xml"

/Users/Shared/Jenkins/Home/jobs/YuMeiOSZISUnitTest/workspace/YuMeTestApp/YuMeZISTestApp.xcworkspace

PROJECT_FOLDER=YuMeTestApp
PROJECT=$PROJECT_FOLDER/YuMeZISTestApp
PWORKSPACE=$PROJECT.xcworkspace

echo "<<<<<<<<<<<<<<<<<<<<<<< UNIT TEST START >>>>>>>>>>>>>>>>>>>>>>>>>>>"

#xcodebuild -sdk iphonesimulator -workspace $WORKSPACE/$PWORKSPACE -scheme $SCHEME_NAME -configuration Debug RUN_APPLICATION_TESTS_WITH_IOS_SIM=YES ONLY_ACTIVE_ARCH=NO clean build          
    
xctool -workspace "$WORKSPACE/$PWORKSPACE" -scheme $SCHEME_NAME -sdk iphonesimulator8.4 -reporter plain -reporter junit:$TEST_REPORT_FILE test
    
    #-IDECustomDerivedDataLocation=$BUILD_PATH \
	#GCC_GENERATE_TEST_COVERAGE_FILES=YES GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES \
    
echo "<<<<<<<<<<<<<<<<<<<<<<< UNIT TEST END >>>>>>>>>>>>>>>>>>>>>>>>>>>"
