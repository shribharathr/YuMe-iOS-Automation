#!/bin/sh

YUME_TEST_SCHEME=YuMeZISTests

echo "<<<<<<<<<<<<<<<<<<<<<<< OCLINT ANALYZER START >>>>>>>>>>>>>>>>>>>>>>>>>>>"

XCTOOL_HOME=/usr/local/Cellar/xctool/0.2.4
export PATH=$XCTOOL_HOME/bin:$PATH

# xctool report with json format
xctool -scheme "$YUME_TEST_SCHEME" -reporter plain -reporter json-compilation-database:compile_commands.json clean build

# set OCLint PATH 
OCLINT_HOME=/usr/local/Cellar/oclint/0.8.1
export PATH=$OCLINT_HOME/bin:$PATH

# OCLint report build
maxPriority=15000

oclint-json-compilation-database -enable-clang-static-analyzer -- -max-priority-1 $maxPriority -max-priority-2 $maxPriority -max-priority-3 $maxPriority -rc LONG_LINE=500 -rc LONG_VARIABLE_NAME=100 -report-type pmd -o bin/oclint.xml
    
echo "<<<<<<<<<<<<<<<<<<<<<<< OCLINT ANALYZER END >>>>>>>>>>>>>>>>>>>>>>>>>>>"

#xctool -reporter json-compilation-database:compile_commands.json clean build
#oclint-json-compilation-database -e Pods/** -- -max-priority-1 1000 -max-priority-2 1000 -max-priority-3 1000 -report-type pmd -o Build/oclint.xml