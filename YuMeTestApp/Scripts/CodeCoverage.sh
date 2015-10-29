#!/bin/sh

#  CodeCoverage.sh
#  YuMeZISTestApp
#
#  Created by yume on 10/29/15.
#  Copyright © 2015 YuMe. All rights reserved.

#import path
export PATH=${PATH}:/usr/local/bin

YUME_TEST_SCHEME=YuMeZISTests

# Code coverage Analysis /usr/local/bin/gcovr
gcovr -r . --object-directory ${WORKSPACE}/build/Build/Intermediates/YuMeZISTestApp.build/Debug-iphonesimulator/YuMeZISTests.build/Objects-normal/i386 --exclude '.*Tests.*' --xml > ${WORKSPACE}/test-reports/yume_cobertura-coverage.xml