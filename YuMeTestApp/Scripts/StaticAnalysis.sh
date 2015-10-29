#!/bin/sh

#  StaticAnalysis.sh
#  YuMeZISTestApp
#
#  Created by yume on 10/29/15.
#  Copyright © 2015 YuMe. All rights reserved.


# OCLint Analysis - PMD Result
# xctool report with json-compilation-database format
xctool -workspace ${WORKSPACE}/YuMeTestApp/YuMeZISTestApp.xcworkspace -scheme "$YUME_TEST_SCHEME" -reporter json-compilation-database:compile_commands.json clean build

#PMD Analysis
oclint-json-compilation-database -e Pods -- -rc=LONG_LINE=500 -rc=NCSS_METHOD=60 -rc=LONG_METHOD=500 -rc LONG_VARIABLE_NAME=100 -rc=MINIMUM_CASES_IN_SWITCH=1 -max-priority-1 1000
-max-priority-2 1000 -max-priority-3 1000 -report-type pmd -o test-reports/yume_oclint.xml
#-report-type html -o test-reports/yume_report.html



#echo "<<<<<<<<<<<<<<<<<<<<<<< OCLINT ANALYZER START >>>>>>>>>>>>>>>>>>>>>>>>>>>"

# set XCTool PATH 
#XCTOOL_HOME=/usr/local/Cellar/xctool/0.2.6
#export PATH=$XCTOOL_HOME/bin:$PATH

# xctool report with json format
#xctool -scheme "$YUME_TEST_SCHEME" -reporter plain -reporter json-compilation-database:compile_commands.json clean build

# set OCLint PATH 
#OCLINT_HOME=/usr/local/Cellar/oclint/0.8.1
#export PATH=$OCLINT_HOME/bin:$PATH

# OCLint report build
#maxPriority=15000

#oclint-json-compilation-database -enable-clang-static-analyzer -- -max-priority-1 $maxPriority -max-priority-2 $maxPriority -max-priority-3 $maxPriority -rc LONG_LINE=500 -rc LONG_VARIABLE_NAME=100 -report-type pmd -o oclint.xml
    
#echo "<<<<<<<<<<<<<<<<<<<<<<< OCLINT ANALYZER END >>>>>>>>>>>>>>>>>>>>>>>>>>>"

#xctool -reporter json-compilation-database:compile_commands.json clean build
#oclint-json-compilation-database -e Pods/** -- -max-priority-1 1000 -max-priority-2 1000 -max-priority-3 1000 -report-type pmd -o Build/oclint.xml