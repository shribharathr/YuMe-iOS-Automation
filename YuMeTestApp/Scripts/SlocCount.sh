#!/bin/sh

#  SlocCount.sh
#  YuMeZISTestApp
#
#  Created by yume on 10/29/15.
#  Copyright © 2015 YuMe. All rights reserved.

#import path
export PATH=${PATH}:/usr/local/bin

YUME_TEST_SCHEME=YuMeZISTests

# SLOCCount Analysis
sloccount --duplicates --wide --details ${WORKSPACE}/YuMeTestApp/$YUME_TEST_SCHEME > ${WORKSPACE}/test-reports/yume_sloccount.sc