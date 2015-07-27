//
//  ModParams.m
//
#import <GHUnit/GHUnit.h>
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface ModParams : GHAsyncTestCase
@end

@implementation ModParams

- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES.
    // Also an async test that calls back on the main thread, you'll probably want to return YES.
    return YES;
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
        GHRunForInterval(1);
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)modParamsEventListener:(NSArray *)userInfo {
    NSString *pSelector = [userInfo objectAtIndex:0];
    NSString *pAdEvent = [userInfo objectAtIndex:1];
    
    [YuMeUnitTestUtils getYuMeEventListenerEvent:pAdEvent completion:^(BOOL bSuccess) {
        if (bSuccess) {
            [self notify:kGHUnitWaitStatusSuccess forSelector:NSSelectorFromString(pSelector)];
        } else {
            [self notify:kGHUnitWaitStatusFailure forSelector:NSSelectorFromString(pSelector)];
        }
    }];
}

/**

 SDK State: Not Initialized	Called when SDK is not initialized.
 Native SDK
 - Returns error message: "yumeSdkModifyAdParams(): YuMe SDK is not Initialized."
 */
- (void)test_MOD_PARAMS_001 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);

    GHTestLog(@" SDK State: Not Initialized");
    
    pError = nil;
    GHAssertFalse([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualObjects(str, @"yumeSdkModifyAdParams(): YuMe SDK is not Initialized.", @"");
        GHTestLog(@"Result: %@", str);
    }
    params = nil;
}

/**
 
 SDK State: Initialized	
 Called with invalid YuMeAdParams object.
 
 Native SDK
 - Returns error message: "yumeSdkModifyAdParams(): Invalid Ad Params object."
 - Remains in Initialized state and the params set during Initialization remains unaltered.
 */
- (void)test_MOD_PARAMS_002 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
        GHAssertTrue([pYuMeSDK yumeSdkInit:params
                              appDelegate:pYuMeTestInterface
                      videoPlayerDelegate:videoController
                                errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                              appDelegate:pYuMeInterface
                                errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params = nil;
    GHTestLog(@"Test Modify AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHAssertFalse([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualObjects(str, @"yumeSdkModifyAdParams(): Invalid Ad Params object.", @"");
        GHTestLog(@"Result: %@", str);
    }
}

/**
SDK State: Initialized	
Called with YuMeAdParams object containing invalid ad server url.
 
Native SDK
- Calls JS SDK ModifyParams.

JS SDK
- Attempts to set the YuMe Ad Params provided by the application but fails.
- Notify the following log to Native SDK: "Invalid Ad Server Url."
- Remains in Initialized state and the params set during Initialization remains unaltered.
*/
- (void)test_MOD_PARAMS_003 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];
    
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
        GHAssertTrue([pYuMeSDK yumeSdkInit:params
                              appDelegate:pYuMeInterface
                      videoPlayerDelegate:videoController
                                errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                              appDelegate:pYuMeInterface
                                errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");

    pError = nil;
    params.pAdServerUrl = nil;
    
    GHTestLog(@"Test Modify AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Called with YuMeAdParams object containing invalid ad server url.");
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;

    GHRunForInterval(0.5);
    
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualObjects(str, @"yumeSdkModifyAdParams(): Invalid Ad Server Url.", @"");
        GHTestLog(@"Result: %@", str);
    }
    
    NSString *testString = @"Invalid Ad Server Url.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        pError = nil;
        GHTestLog(@"Ad server URL : %@", [pYuMeSDK yumeSdkGetAdParams:&pError].pAdServerUrl);
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 
 SDK State: Initialized
 Called with YuMeAdParams object containing malformed ad server url. (e.g) Malformed Ad Server Url: shadow01.yumenetworks.com (url without “http://”)
 
 Native SDK
 - Calls JS SDK ModifyParams.
 
 JS SDK
 - Attempts to set the YuMe Ad Params provided by the application but fails.
 - Notify the following log to Native SDK: "Malformed Ad Server Url."
 - Remains in Initialized state and the params set during Initialization remains unaltered.
 */
- (void)test_MOD_PARAMS_004 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
    GHTestLog(@"Ad server url : %@", params.pAdServerUrl);
    
#if pYuMeMPlayerController
        GHAssertTrue([pYuMeSDK yumeSdkInit:params
                              appDelegate:pYuMeTestInterface
                      videoPlayerDelegate:videoController
                                errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                              appDelegate:pYuMeInterface
                                errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");

    pError = nil;
    params.pAdServerUrl = @"shadow01.yumenetworks.com";
    
    GHTestLog(@"Test Modify AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Called with YuMeAdParams object containing malformed ad server url.");

    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualObjects(str, @"yumeSdkModifyAdParams(): Malformed Ad Server Url.", @"");
        GHTestLog(@"Result: %@", str);
    }
    
    GHRunForInterval(0.5);
    NSString *testString = @"Malformed Ad Server Url.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        
        pError = nil;
        GHTestLog(@"Ad server URL : %@", [pYuMeSDK yumeSdkGetAdParams:&pError].pAdServerUrl);
        
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 
 SDK State: Initialized	
 Called with YuMeAdParams object containing invalid domain id.
 
 Native SDK
 - Calls JS SDK ModifyParams.
 
 JS SDK
 - Attempts to set the YuMe Ad Params provided by the application but fails.
 - Notify the following log to Native SDK: "Invalid Domain Id."
 - Remains in Initialized state and the params set during Initialization remains unaltered.
 */
- (void)test_MOD_PARAMS_005 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");

    pError = nil;
    params.pDomainId = @"";
    GHTestLog(@"Test Modify AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Called with YuMeAdParams object containing invalid domain id.");
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualObjects(str, @"yumeSdkModifyAdParams(): Invalid Domain Id.", @"");
        GHTestLog(@"Result: %@", str);
    }
    
    GHRunForInterval(0.5);
    NSString *testString = @"Invalid Domain Id.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        
        pError = nil;
        GHTestLog(@"Domain Id : %@", [pYuMeSDK yumeSdkGetAdParams:&pError].pDomainId);
        
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 SDK State: Initialized	
 Called with YuMeAdParams object containing ad timeout < 4.
 
 Native SDK
 - Calls JS SDK ModifyParams.
 
 JS SDK
 1. Ignores the new ad timeout value received from app.
 2. Sets the ad timeout to the default value of 5.
 */
- (void)test_MOD_PARAMS_006 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif

    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");

    pError = nil;
    params.adTimeout = 2;
    GHTestLog(@"Called with YuMeAdParams object containing ad timeout : (%ld < 4)", (long)params.adTimeout);
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHFail(@"Error : %@", str.description);
    }
    GHTestLog(@"Result: ModifyParams Successful.");
    
    GHRunForInterval(0.5);
    GHAssertEquals((long)[pYuMeSDK yumeSdkGetAdParams:&pError].adTimeout, (long)5, @"");
    GHTestLog(@"Ignores the new ad timeout value received from app. Sets the ad timeout to the default value of : %ld", (long)[pYuMeSDK yumeSdkGetAdParams:&pError].adTimeout);
}

/**
 SDK State: Initialized	
 Called with YuMeAdParams object containing ad timeout > 60.
 
 Native SDK
 - Calls JS SDK ModifyParams.
 
 JS SDK
 - Attempts to set the YuMe Ad Params provided by the application but fails.
 - Notify the following log to Native SDK: "Invalid Ad Connection Timeout value. It cannot exceed 60."
 - Remains in Initialized state and the params set during Initialization remains unaltered.
 */
- (void)test_MOD_PARAMS_007 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif

    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");

    pError = nil;
    params.adTimeout = 62;
    
    GHTestLog(@"Called with YuMeAdParams object containing ad timeout (%ld > 60).", (long)params.adTimeout);
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualObjects(str, @"yumeSdkModifyAdParams(): Invalid Ad Connection Timeout Value. It cannot exceed 60.", @"");
        GHTestLog(@"Result: %@", str);
    }
    
    GHRunForInterval(0.5);
    NSString *testString = @"Invalid Ad Connection Timeout value. It cannot exceed 60.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        pError = nil;
        GHTestLog(@"AdTimeout : %ld", (long)[pYuMeSDK yumeSdkGetAdParams:&pError].adTimeout);
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 SDK State: Initialized
 Called with YuMeAdParams object containing video timeout < 3.
 
 Native SDK
 - Calls JS SDK ModifyParams.
 
 JS SDK
 1. Ignores the new video timeout value received from app.
 2. Sets the video timeout to the default value of 6.
 */
- (void)test_MOD_PARAMS_008 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif

    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");

    pError = nil;
    params.videoTimeout = 1;
    GHTestLog(@"Called with YuMeAdParams object containing video timeout (%ld > 3).", (long)params.videoTimeout);

    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHFail(@"Error : %@", str.description);
    }
    GHTestLog(@"Result: ModifyParams Successful.");
    
    GHRunForInterval(2);
    GHAssertEquals((long)[pYuMeSDK yumeSdkGetAdParams:&pError].adTimeout, (long)6, @"");
    GHTestLog(@"Ignores the new video timeout value received from app. Sets the video timeout to the default value of : %ld", (long)[pYuMeSDK yumeSdkGetAdParams:&pError].videoTimeout);
}

/**
 SDK State: Initialized	
 Called with YuMeAdParams object containing video timeout > 60.
 
 Native SDK
 - Calls JS SDK ModifyParams.
 
 JS SDK
 - Attempts to set the YuMe Ad Params provided by the application but fails.
 - Notify the following log to Native SDK: "Invalid Progressive Download Timeout Value. It cannot exceed 60."
 - Remains in Initialized state and the params set during Initialization remains unaltered.
 */
- (void)test_MOD_PARAMS_009 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");

    params.videoTimeout = 80;
    GHTestLog(@"Called with YuMeAdParams object containing video timeout :( %ld > 60).", (long)params.videoTimeout);

    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualObjects(str, @"yumeSdkModifyAdParams(): Invalid Progressive Download Timeout Value. It cannot exceed 60 seconds.", @"");
        GHTestLog(@"Result: %@", str);
    }
    
    GHRunForInterval(0.5);
    NSString *testString = @"Invalid Progressive Download Timeout Value. It cannot exceed 60.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        pError = nil;
        GHTestLog(@"VideoTimeout : %ld", (long)[pYuMeSDK yumeSdkGetAdParams:&pError].videoTimeout);
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 SDK State: Initialized	Called with YuMeAdParams object containing valid values for ad server url, domain id, ad time out and video time out.
 
 Native SDK
 - Calls JS SDK ModifyParams.
 
 JS SDK
 - Sets the YuMe Ad Params provided by the application successfully.
 - Shouldn't try to fetch the ad params from CDN.
 */
- (void)test_MOD_PARAMS_010 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif

    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");
    pError = nil;
    
    NSString *testAdserverURL = @"http://qa-web-001.sjc1.yumenetworks.com";
    NSString *testDomainId = @"3679UjYRBTPg";
    
    params.pAdServerUrl = testAdserverURL;
    params.pDomainId = testDomainId;

    GHTestLog(@"Test Modify AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);

    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;

    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHFail(@"Fail : %@", str);
    }
    GHTestLog(@"ModifyParams Successful.");
    
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertEqualStrings([pYuMeSDK yumeSdkGetAdParams:&pError].pAdServerUrl, testAdserverURL, @"Sets the YuMe Ad Params provided by the application successfully");
    GHAssertEqualStrings([pYuMeSDK yumeSdkGetAdParams:&pError].pDomainId, testDomainId, @"Sets the YuMe Ad Params provided by the application successfully");
}

/**
 
 SDK State: Initialized
 SDK Mode: PREFETCH A Prefetched un-expired ad exists in cache and ModifyParams() called with any (or) some (or) some of the following changes:
 a. Mode changed from PREFETCH to STREAMING.
 b. Storage size changes to 0.0f.
 c. Caching disabled
 d. Domain Id set during Initialization is changed.			
 
 Native SDK
 - Calls JS SDK ModifyParams.
 
 JS SDK
 - Stops the ad expiry timer
 - Hits the first party error tracker by appending “&reason=54”
 - Mark the existing prefetched ad as expired.
 - Sets the YuMe Ad Params provided by the application successfully.
 - Shouldn't try to fetch the ad params from CDN.
 */
- (void)test_MOD_PARAMS_011 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(modParamsEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    
    GHRunForInterval(1);

    pError = nil;
    NSString *testDomainId = @"3679UjYRBTPg";
    params.pDomainId = testDomainId;
    
    GHTestLog(@"Test Modify AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    params = nil;
    
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHFail(@"Fail : %@", str);
    }
    GHTestLog(@"ModifyParams Successful.");
    pError = nil;
    
    GHRunForInterval(1);
    
    NSString *consoleLog = [YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)];
    
    NSString *testString = @"Marking ad as Expired due to Modify Params - 5.";
    if ([consoleLog rangeOfString:testString].location != NSNotFound) {
        pError = nil;
        GHTestLog(@"Result: %@ ", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }

    testString = @"&reason=54";
    if ([consoleLog rangeOfString:testString].location != NSNotFound) {
        pError = nil;
        GHTestLog(@"Result: Hits the first party error tracker by appending '%@' ", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }

    GHAssertEqualStrings([pYuMeSDK yumeSdkGetAdParams:&pError].pDomainId, testDomainId, @"Sets the YuMe Ad Params provided by the application successfully");
}

@end
