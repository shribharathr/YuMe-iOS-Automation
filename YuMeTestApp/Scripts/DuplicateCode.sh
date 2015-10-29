#!/bin/sh

#  DuplicateCode.sh
#  YuMeZISTestApp
#
#  Created by yume on 10/29/15.
#  Copyright © 2015 YuMe. All rights reserved.


# Duplicate Code Analysis
java -DObjC-CPD-LoggingEnabled=YES -Xmx512m -classpath '/usr/local/Cellar/pmd/pmd-bin-4.3/lib/pmd-4.3.jar:/usr/local/Cellar/pmd/ObjCLanguage-0.0.7-SNAPSHOT.jar' net.sourceforge.pmd.cpd.CPD --minimum-tokens 100 --files ${WORKSPACE}/YuMeTestApp/$YUME_TEST_SCHEME --language ObjectiveC --encoding UTF-8 --format net.sourceforge.pmd.cpd.XMLRenderer > ${WORKSPACE}/test-reports/yume_cpd.xml

