#!/bin/sh
#
# Chmod this script with +x and run it in every folder containing GHUnit tests you want to convert.
# The script is NOT recursive, it'll only look for files in the current directory.

find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/: GHTestCase/: XCTestCase/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/: GHAsyncTestCase/: XCTAsyncTestCase/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertTrue/XCTAssertTrue/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/<GHUnitIOS\/GHUnit.h>/<XCTest\/XCTest.h>/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertNotNil/XCTAssertNotNil/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertTrue/XCTAssertTrue/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertFalse/XCTAssertFalse/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHTestCase/XCTestCase/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertEquals/XCTAssertEqual/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertEqualStrings/XCTAssertEqualObjects/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertEqualObjects/XCTAssertEqualObjects/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertNotEquals/XCTAssertNotEqual/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHAssertNil/XCTAssertNil/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHRunForInterval/runForInterval/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHTestLog/NSLog/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/GHFail(/XCTFail(@"%@",/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/kGHUnitWaitStatusSuccess/kXCTUnitWaitStatusSuccess/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/kGHUnitWaitStatusFailure/kXCTUnitWaitStatusFailure/g' -i '' Z
find . -maxdepth 1 | grep "\.h$\|\.m$" | xargs -IZ sed -e 's/<GHUnit\/GHUnit.h>/"XCTAsyncTestCase.h"/g' -i '' Z