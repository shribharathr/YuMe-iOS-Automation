//
//  DeInit.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface DeInit : XCTAsyncTestCase
@end

@implementation DeInit

- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES.
    // Also an async test that calls back on the main thread, you'll probably want to return YES.
    return NO;
}

- (void)setUpClass {
    // Run at start of all tests in the class
    NSLog(@"######################## RUN START - SetUpClass #######################################");
}

- (void)tearDownClass {
    // Run at end of all tests in the class
    NSLog(@"######################## RUN END - TeatDownClass #######################################");
}

- (void)setUp {
    // Run before each test method
    NSLog(@"************************ Unit Test - SetUp ************************");
    pYuMeInterface = [YuMeUnitTestUtils getYuMeInterface];
    pYuMeSDK = [pYuMeInterface getYuMeSDKHandle];
}

- (void)tearDown {
    NSError *pError = nil;
    
    // Run after each test method
    if (pYuMeSDK) {
        [self runForInterval:1];
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

/*!
 @function       test_DEINIT_001
 @abstract       test_DEINIT_001 : Check DeInit API Case -> Pre Condition : SDK State: Not Initialized
 @discussion     This function called when SDK is not initialized.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkDeInit(): YuMe SDK is not Initialized."
 */
- (void)test_DEINIT_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    XCTAssertFalse([pYuMeSDK yumeSdkDeInit:&pError], @"YuMe SDK is not Initialized.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkDeInit(): YuMe SDK is not Initialized.", @"");
        NSLog(@"Result : %@", str);
    } else {
        XCTFail(@"FAIL");
    }
}

/*!
 @function       test_DEINIT_001
 @abstract       test_DEINIT_001 : Check DeInit API Case -> Pre Condition : SDK State: Initialized
 @discussion     This function called when SDK is initialized.
 @param          None
 @result         Native SDK
 - Calls JS SDK DeInit.
 - Cleans up the resources used by the SDK.
 - Moves to Uninitialized state.
 
 JS SDK
 - Stops the ad, if ad play is in progress.
 - Aborts the asset downloads in progress.
 - Cancels the network operations in progress.
 - Stops the running timers (ad expiry timer, prefetch request callback timer & auto prefetch timer).
 - Resets the auto-prefetch time interval.
 - Hits the first party error tracker by appending “&reason=53”, if a valid un-expired ad exists.
 - Cleans up the resources used by the SDK.
 - Moves to Uninitialized state.
 */
- (void)test_DEINIT_002 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                              errorInfo:&pError], @"Initialization Failed.");
    
#endif
    params = nil;
    
    [self runForInterval:5];
    
    XCTAssertTrue([pYuMeSDK yumeSdkDeInit:&pError], @"YuMe SDK is deInitialized.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Fail : %@", str);
    } else {
        NSLog(@"Result: SDK De-Initailized Succesfully.");
    }
}

@end
