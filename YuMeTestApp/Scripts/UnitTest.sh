#!/bin/sh

# XCTool Setup Path
XCTOOL_HOME=/usr/local/Cellar/xctool/0.2.4
export PATH=$XCTOOL_HOME/bin:$PATH

SCHEME_NAME=YuMeZISTests
TEST_REPORT_FILE="bin/yume_report/test-result.xml"

echo "<<<<<<<<<<<<<<<<<<<<<<< UNIT TEST START >>>>>>>>>>>>>>>>>>>>>>>>>>>"

	#xcodebuild -sdk iphonesimulator \
    #       -workspace $WORKSPACE \
    #       -scheme $SCHEME_NAME \
    #       -configuration Debug \
    #       RUN_APPLICATION_TESTS_WITH_IOS_SIM=YES \
    #       ONLY_ACTIVE_ARCH=NO \
    #       clean build           
    
echo $WORKSPACE
echo $SCHEME_NAME
echo $TEST_REPORT_FILE
	
xctool -workspace $WORKSPACE -scheme $SCHEME_NAME -sdk iphonesimulator -reporter plain -reporter junit:$TEST_REPORT_FILE clean test
    

    #-IDECustomDerivedDataLocation=$BUILD_PATH \
	#GCC_GENERATE_TEST_COVERAGE_FILES=YES GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES \
    
echo "<<<<<<<<<<<<<<<<<<<<<<< UNIT TEST END >>>>>>>>>>>>>>>>>>>>>>>>>>>"