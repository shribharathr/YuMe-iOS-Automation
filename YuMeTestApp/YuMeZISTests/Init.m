//
//  Init.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface Init : XCTAsyncTestCase

@end

@implementation Init

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
    
    [self runForInterval:2];
    NSLog(@"************************ Unit Test - TearDown ************************");
}

#pragma mark -
#pragma mark Private Methods

- (void)initEventListener:(NSArray *)userInfo {
    NSString *pSelector = [userInfo objectAtIndex:0];
    NSString *pAdEvent = [userInfo objectAtIndex:1];
    
    [YuMeUnitTestUtils getYuMeEventListenerEvent:pAdEvent completion:^(BOOL bSuccess) {
        if (bSuccess) {
            [self notify:kXCTUnitWaitStatusSuccess forSelector:NSSelectorFromString(pSelector)];
        } else {
            [self notify:kXCTUnitWaitStatusFailure forSelector:NSSelectorFromString(pSelector)];
        }
    }];
}

#pragma mark -
#pragma mark TestCases

/*!
 @function       test_INIT_001
 @abstract       test_INIT_001 : Check Init API Case -> Pre Condition : SDK State: Not Initialized, JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called for the first time after SDK instantiation (with YuMeAdParams object containing valid values for domain id and a valid 
 YuMeAppInterface (or) YuMeAppDelegate object).
 @param          None
 @result         Native SDK
 - Fetches yume_js_sdk_info.json from CDN (it is well-formed).
 - Stores the JS SDK version and Main Page version in device's Internal Storage.
 - Fetches all the JS SDK Resources and caches them successfully in the device's Internal Storage.
 - Loads the JS SDK Index Page and Calls JS SDK Init.
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 
 JS SDK
 - Fetches YuMe Ad Params (yume_params.json) containing valid values for ad server url, domain id, ad timeout value & video timeout values from CDN successfully.
 - Initializes with the fetched YuMe Ad Params.
 - Notifies YuMeAdEventInitSuccess event.
 - Initialization Successful.
 */
- (void)test_INIT_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
        XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                              appDelegate:pYuMeInterface
                      videoPlayerDelegate:pYuMeMPlayerController
                                errorInfo:&pError], @"Initialization Successful.");
        
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                              appDelegate:pYuMeInterface
                                errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"YuMeAdEventInitSuccess event received.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Successful.");
}

/*!
 @function       test_INIT_002
 @abstract       test_INIT_002 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called with invalid YuMeAdParams object.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): Invalid Ad Params Object."
 - Initialization Fails.
 */
- (void)test_INIT_002 {
    NSError *pError = nil;

    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params =  nil;
    XCTAssertNil(params, @"params object is NULL");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
        XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                               appDelegate:pYuMeInterface
                       videoPlayerDelegate:videoController
                                 errorInfo:&pError], @"Initialization not Successful.");
        
#else
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                               appDelegate:pYuMeInterface
                                 errorInfo:&pError], @"Initialization not Successful.");
#endif
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Invalid Ad Params Object.", @"");
        //GHTestLog(@"Result : %@", str);
    }
}

/*!
 @function       test_INIT_003
 @abstract       test_INIT_003 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called with valid YuMeAdParams object containing invalid domain id (nil (or) "").
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): Invalid Domain Id."
 - Initialization Fails.
 */
- (void)test_INIT_003 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = nil;
    
    XCTAssertNil(params.pDomainId, @"params.pDomainId object is NULL");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                    videoPlayerDelegate:videoController
                              errorInfo:&pError], @"Initialization not Successful.");
    
#else
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                              errorInfo:&pError], @"Initialization not Successful.");
#endif
    params = nil;
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Invalid Domain Id.", @"");
        //GHTestLog(@"Result : %@", str);
    }
}

/*!
 @function       test_INIT_004
 @abstract       test_INIT_004 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called with invalid YuMeAppInterface (or) YuMeAppDelegate object.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): Invalid YuMeAppDelegate object."
 - Initialization Fails.
 */
- (void)test_INIT_004 {
    NSError *pError = nil;

    pYuMeInterface = nil;
    XCTAssertNil(pYuMeInterface, @"pYuMeInterface object is nil");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
        XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                               appDelegate:pYuMeInterface
                       videoPlayerDelegate:videoController
                                 errorInfo:&pError], @"Initialization not Successful.");
        
#else
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                               appDelegate:pYuMeInterface
                                 errorInfo:&pError], @"Initialization not Successful.");
#endif
    params = nil;
    
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Invalid YuMeAppDelegate object.", @"");
        //GHTestLog(@"Result : %@", str);
    }
}

/*!
 @function       test_INIT_005
 @abstract       test_INIT_005 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called with valid YuMeAppDelegate object that doesn't implement the delegate method “yumeEventListener” as defined.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): YuMeAppDelegate must implement yumeEventListener."
 - Initialization Fails.
 */
- (void)test_INIT_005 {
    XCTFail(@"Please do it manually");
    //GHTestLog(@"Result : %@", @"Please do it manually");
}

/*!
 @function       test_INIT_006
 @abstract       test_INIT_006 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called when JS SDK Resource fetching is in progress.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): Initialization Process already in Progress – 1."
 - New Init Call ignored and the previous Initialization continues.
 */
- (void)test_INIT_006 {
    NSError *pError = nil;
    NSError *pError1 = nil;

    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"yumeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);

#if pYuMeMPlayerController
        XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                               appDelegate:pYuMeInterface
                       videoPlayerDelegate:videoController
                                 errorInfo:&pError], @"Initialization not Successful.");
        
#else
    [pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError];
    
    // Call init Again
    [pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError1];
    //GHTestLog(@"New Init Call ignored and the previous Initialization continues.");
#endif
    params = nil;
    
    if (pError1) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError1];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Initialization Process already in Progress - 1.", @"");
        //GHTestLog(@"Result : %@", str);
    }
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Successful.");
}

/*!
 @function       test_INIT_007
 @abstract       test_INIT_007 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called when JS SDK Resource fetching is completed and JS SDK Init is in progress.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): Initialization Process already in Progress – 2."
 - New Init Call ignored and the previous Initialization continues.
 */
- (void)test_INIT_007 {
    NSError *pError = nil;
    NSError *pError1 = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"yumeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                    videoPlayerDelegate:videoController
                              errorInfo:&pError], @"Initialization not Successful.");
    
#else
    [pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError];
    
    [self runForInterval:1];
    
    // Call init Again
    [pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError1];
    //GHTestLog(@"New Init Call ignored and the previous Initialization continues.");
#endif
    params = nil;
    
    if (pError1) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError1];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Initialization Process already in Progress - 2.", @"");
        //GHTestLog(@"Result : %@", str);
    }
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Successful.");
}

/*!
 @function       test_INIT_008
 @abstract       test_INIT_008 : Check Init API Case -> Pre Condition :  Initialized, JS SDK Resources: Cached already.
 @discussion     This function called again with the same YuMeAppDelegate object passed during previous Initialization and a valid (or) invalid YuMeAdParams object.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): YuMe SDK is already Initialized."
 - New Init Call ignored.
 */
- (void)test_INIT_008 {
    NSError *pError = nil;
    NSError *pError1 = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not nil");
    XCTAssertNotNil(pYuMeSDK, @"yumeSDK object not nil");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not nil");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                    videoPlayerDelegate:videoController
                              errorInfo:&pError], @"Initialization not Successful.");
    
#else
    [pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError];
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Successful.");
    
    [self runForInterval:1];
    
    // Call init Again
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError1] , @"New Init Call ignored.");
    //GHTestLog(@"New Init Call ignored.");
    
    if (pError1) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError1];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): YuMe SDK is already Initialized.", @"");
        //GHTestLog(@"Result : %@", str);
    }
}

/*!
 @function       test_INIT_009
 @abstract       test_INIT_009 : Check Init API Case -> Pre Condition :  Initialized, JS SDK Resources: Cached already.
 @discussion     This function called again with a valid but different YuMeAppDelegate object passed during previous Initialization.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): YuMe SDK is already Initialized, Delegate updated."
 - New Init Call ignored.
 */
- (void)test_INIT_009 {
    NSError *pError = nil;
    NSError *pError1 = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not nil");
    XCTAssertNotNil(pYuMeSDK, @"yumeSDK object not nil");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not nil");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                    videoPlayerDelegate:videoController
                              errorInfo:&pError], @"Initialization not Successful.");
    
#else
    [pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError];
    
#endif

    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Successful.");
    
    [self runForInterval:1];
    
    pYuMeInterface = nil;
    pYuMeInterface = [YuMeUnitTestUtils getYuMeInterface];
    
    // Call init Again
    //GHTestLog(@"Different YuMeAppDelegate object");
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError1] , @"New Init Call ignored.");
    //GHTestLog(@"New Init Call ignored.");

    params = nil;
    if (pError1) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError1];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): YuMe SDK is already Initialized, Delegate updated.", @"");
        //GHTestLog(@"Result : %@", str);
    }
}

/*!
 @function       test_INIT_010
 @abstract       test_INIT_010 : Check Init API Case -> Pre Condition :  Initialized, JS SDK Resources: Cached already.
 @discussion     This function called again with an invalid YuMeAppDelegate object.
 @param          None
 @result         Native SDK
 - Returns error message: "yumeSdkInit(): YuMe SDK is already Initialized, Invalid Delegate received and ignored."
 - New Init Call ignored.
 */
- (void)test_INIT_010 {
    NSError *pError = nil;
    NSError *pError1 = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not nil");
    XCTAssertNotNil(pYuMeSDK, @"yumeSDK object not nil");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not nil");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                    videoPlayerDelegate:videoController
                              errorInfo:&pError], @"Initialization not Successful.");
    
#else
    [pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError];
    
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Successful.");
    
    pYuMeInterface = nil;
    // Call init Again
    //GHTestLog(@"Invalid YuMeAppDelegate object");
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params appDelegate:pYuMeInterface errorInfo:&pError1] , @"New Init Call ignored.");
    //GHTestLog(@"New Init Call ignored.");
    params = nil;
    
    if (pError1) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError1];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): YuMe SDK is already Initialized, Invalid Delegate received and ignored.", @"");
        //GHTestLog(@"Result : %@", str);
    }
}

/*!
 @function       test_INIT_011
 @abstract       test_INIT_011 : Check Init API Case -> Pre Condition :  SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called for the first time after SDK instantiation (with YuMeAdParams object containing valid values for domain id and a valid YuMeAppInterface (or) YuMeAppDelegate object). SDK attempts fetching yume_js_sdk_info.json from CDN, which times out.
 @param          None
 @result         Native SDK
 - Notifies YuMeAdEventInitFailed event to application.
 - Initialization Fails.
 */
- (void)test_INIT_011 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not nil");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not nil");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"invalid";
    
    XCTAssertNotNil(params, @"params object not nil");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Fails");
}

/*!
 @function       test_INIT_012
 @abstract       test_INIT_012 : Check Init API Case -> Pre Condition :  SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called for the first time after SDK instantiation (with YuMeAdParams object containing valid values for domain id and a valid YuMeAppInterface (or) YuMeAppDelegate object).
 - SDK attempts fetching yume_js_sdk_info.json from CDN, which fails with a non-success response like 404, 503 etc.,.
 @param          None
 @result         Native SDK
 - Notifies YuMeAdEventInitFailed event to application.
 - Initialization Fails.
 */
- (void)test_INIT_012 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not nil");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not nil");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"404";
    
    XCTAssertNotNil(params, @"params object not nil");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Fails");
}

/*!
 @function       test_INIT_013
 @abstract       test_INIT_013 : Check Init API Case -> Pre Condition :  SDK State: Not Initialized JS SDK Resources: Cached (or) Not Cached already.
 @discussion     This function called for the first time after SDK instantiation (with YuMeAdParams object containing valid values for domain id and a valid YuMeAppInterface (or) YuMeAppDelegate object).
 - SDK fetches yume_js_sdk_info.json from CDN successfully but the JSON data is malformed.
 @param          None
 @result         Native SDK
 - Notifies YuMeAdEventInitFailed event to application.
 - Initialization Fails.
 */
- (void)test_INIT_013 {
    XCTFail(@"Please do it manually");
    //GHTestLog(@"Result : %@", @"Please do it manually");

    /*
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not nil");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not nil");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    //params.pAdServerUrl = @"http://download.yumenetworks.com/yume/demo/bharath/unittest/malformed_json";

    XCTAssertNotNil(params, @"params object not nil");
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", ([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Fails");
     */
}

- (void)test_INIT_014 {
    XCTFail(@"Please do it manually");
    //GHTestLog(@"Result : %@", @"Please do it manually");
}

/*!
 @function       test_INIT_015
 @abstract       test_INIT_015 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already.
 @discussion     This function called for the first time after SDK instantiation (with YuMeAdParams object containing valid values for domain id and a valid YuMeAppInterface (or) YuMeAppDelegate object).
 - SDK fetches yume_js_sdk_info.json from CDN successfully and the JSON data is well-formed.
 - JS SDK version and Main Page version in device's Internal Storage matches with the received version info.
 - All the required JS SDK resources already exists in local cache.
 @param          None
 @result         Native SDK
 - Gets initialized using the already cached JSS Resources.
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 
 JS SDK
 - Completes the Initialization process.
 - Notifies YuMeAdEventInitSuccess event.
 
 - Initialization Successful.
 */
- (void)test_INIT_015 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Successful.");
}

/*!
 @function       test_INIT_016
 @abstract       test_INIT_016 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already.
 @discussion     This function called for the first time after SDK instantiation (with YuMeAdParams object containing valid values for domain id and a valid YuMeAppInterface (or) YuMeAppDelegate object).
 - SDK fetches yume_js_sdk_info.json from CDN successfully and the JSON data is well-formed.
 - JS SDK version and Main Page version in device's Internal Storage matches with the received version info.
 - Some required JS SDK resources missing in local cache.
 @param          None
 @result         Native SDK
 - Deletes the existing JSS resources and fetches all the required resources.
 - Gets initialized using the fetched JSS Resources.
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 
 JS SDK
 - Completes the Initialization process.
 - Notifies YuMeAdEventInitSuccess event.
 
 - Initialization Successful.
 */
- (void)test_INIT_016 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    // Remove some assets internally...
    [YuMeUnitTestUtils deleteFile:@"jquery-1.10.2.min.js"];
    [YuMeUnitTestUtils deleteFile:@"jquery.mobile-1.4.5.js"];
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Initialization Successful.");
}

/*!
 @function       test_INIT_017
 @abstract       test_INIT_017 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already.
 @discussion     This function called for the first time after SDK instantiation (with YuMeAdParams object containing valid values for domain id and a valid YuMeAppInterface (or) YuMeAppDelegate object).
 - SDK fetches yume_js_sdk_info.json from CDN successfully and the JSON data is well-formed.
 - JS SDK version and Main Page version in device's Internal Storage matches with the received version info.
 - All the required JS SDK resources exists in local cache but some extra resources also exists.
 @param          None
 @result         Native SDK
 - Gets initialized using the already cached JSS Resources, ignoring the extra resources in cache.
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 
 JS SDK
 - Completes the Initialization process.
 - Notifies YuMeAdEventInitSuccess event.
 
 - Initialization Successful.
 */
- (void)test_INIT_017 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Result: Initialization Successful.");
}

/*!
 @function       test_INIT_018
 @abstract       test_INIT_018 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already.
 @discussion     This function called for the first time after SDK instantiation (with YuMeAdParams object containing valid values for domain id and a valid YuMeAppInterface (or) YuMeAppDelegate object).
 - SDK fetches yume_js_sdk_info.json from CDN successfully and the JSON data is well-formed.
 - JS SDK version (or) Main Page version in device's Internal Storage differs from the received version info.
 @param          None
 @result         Native SDK
 - Updates the JS SDK version and Main Page version in device's Internal Storage.
 - Deletes existing JSS resources and fetches all the required resources.
 - Gets initialized using the fetched JSS Resources.
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 
 JS SDK
 - Completes the Initialization process.
 - Notifies YuMeAdEventInitSuccess event.
 
 - Initialization Successful.
 */
- (void)test_INIT_018 {
    XCTFail(@"Please do it manually");
    //GHTestLog(@"Result : %@", @"Please do it manually");
}

/*!
 @function       test_INIT_019
 @abstract       test_INIT_019 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already and SDK attempts JS SDK Loading.
 @discussion     This function called at JS SDK Loading fails (or) times out (Time out value: 10 seconds).
 @param          None
 @result         Native SDK
 - Notifies YuMeAdEventInitFailed event to application.
 - Initialization Fails.
 */
- (void)test_INIT_019 {
    XCTFail(@"Please do it manually");
    //GHTestLog(@"Result : %@", @"Please do it manually");
}

/*!
 @function       test_INIT_020
 @abstract       test_INIT_020 : Check Init API Case -> Pre Condition : SDK State: Not Initialized. JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains valid values for ad server url, domain id, ad timeout & video timeout.
 - JS SDK attempts fetching YuMe Ad Params (yume_params.json) which times out (or) fails with non-success (404, 503, etc.,) response (or) succeeds with 200 OK, but JSON malformed.
 @param          None
 @result         JS SDK
 - Gets initialized with the YuMe Ad Params provided by the application – appropriate JS SDK Log should be present to know this.
 - Notifies YuMeAdEventInitSuccess event.
 
 Native SDK
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 - Initialization Successful.
 */
- (void)test_INIT_020 {
    XCTFail(@"Please do it manually");
    //GHTestLog(@"Result : %@", @"Please do it manually");
}

/*!
 @function       test_INIT_021
 @abstract       test_INIT_021 : Check Init API Case -> Pre Condition : SDK State: Not Initialized. JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains valid values for ad server url, domain id, ad timeout & video timeout.
 - JS SDK fetches YuMe Ad Params (yume_params.json) successfully but contains invalid (or) malformed ad server url (or) invalid domainId (or) invalid ad timeout (or) invalid video timeout.
 
 (e.g) Malformed Ad Server Url: shadow01.yumenetworks.com (url without “http://”)
 @param          None
 @result         JS SDK
 - Should print either of the following log based on the invalid mandatory params received:
 Invalid Ad Server Url.
 Malformed  Ad Server Url.
 Invalid Domain Id.
 Invalid Ad Connection Timeout value. It cannot exceed 60.
 Invalid Progressive Download Timeout Value. It cannot exceed 60.
 - Gets initialized with the YuMe Ad Params provided by the application – appropriate JS SDK Log should be present to know this.
 - Notifies YuMeAdEventInitSuccess event.
 
 Native SDK
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 
 - Initialization Successful.
 */
- (void)test_INIT_021 {
    XCTFail(@"Please do it manually");
    //GHTestLog(@"Result : %@", @"Please do it manually");
}

/*!
 @function       test_INIT_022
 @abstract       test_INIT_022 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains valid values for ad server url, domain id, ad timeout & video timeout.
 - JS SDK fetches YuMe Ad Params (yume_params.json) successfully but contains valid ad server url, domainId & video time out values, but  ad timeout is < 4.
 @param          None
 @result         JS SDK
 - Ignores the ad timeout value received in config params.
 - Gets initialized with the YuMe Ad Params retrieved and sets the ad timeout to the default value of 5 seconds – appropriate JS SDK Log should be present to know this.
 - Notifies YuMeAdEventInitSuccess event.
 
 Native SDK
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 - Initialization Successful.
 */
- (void)test_INIT_022 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    params.adTimeout = 2;
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Result: Initialization Successful.");
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    
    XCTAssertEqual(adParams.adTimeout, 5, @"YuMe Ad Params retrieved and sets the ad timeout to the default value of 5 seconds");
}

/*!
 @function       test_INIT_023
 @abstract       test_INIT_023 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains valid values for ad server url, domain id, ad timeout & video timeout.
 - JS SDK fetches YuMe Ad Params (yume_params.json) successfully but contains valid ad server url, domainId & ad time out values, but video timeout is < 3.
 @param          None
 @result         JS SDK
 - Ignores the video timeout value received in config params.
 - Gets initialized with the YuMe Ad Params retrieved and sets the video timeout to the default value of 6 seconds – appropriate JS SDK Log should be present to know this.
 - Notifies YuMeAdEventInitSuccess event.
 
 Native SDK
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 
 - Initialization Successful.
 */
- (void)test_INIT_023 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.videoTimeout = 2;
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Result: Initialization Successful.");
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    
    XCTAssertEqual(adParams.videoTimeout, 6, @"YuMe Ad Params retrieved and sets the video timeout to the default value of 6 seconds");
}

/*!
 @function       test_INIT_024
 @abstract       test_INIT_024 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains invalid ad server url and valid ad timeout & video timeout values.
 - JS SDK attempt to fetch YuMe Ad Params (yume_params.json) fails (or) Fetching succeeds but invalid (or) malformed ad server url (or) invalid domainId (or) invalid ad timeout (or) invalid video timeout received.
 
 (e.g) Malformed Ad Server Url: shadow01.yumenetworks.com (url without “http://”)
 @param          None
 @result         JS SDK
 - Attempts to initialize with the YuMe Ad Params provided by the application but fails.
 - Notify the following log to Native SDK:
 Invalid Ad Server Url.
 - Notifies YuMeAdEventInitFailed event.
 
 Native SDK
 - Notifies YuMeAdEventInitFailed event received from JS SDK to application.
 
 - Initialization Fails.
 */
- (void)test_INIT_024 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211Eshvderer";
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Failed.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
 
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Invalid Ad Server Url.", @"");
        //GHTestLog(@"Result : %@", str);
    }
    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    //GHTestLog(@"Result: Initialization Fails.");
}

/*!
 @function       test_INIT_025
 @abstract       test_INIT_025 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains malformed ad server url and valid ad timeout & video timeout values.
 - JS SDK attempt to fetch YuMe Ad Params (yume_params.json) fails (or) Fetching succeeds but  invalid (or) malformed ad server url (or) invalid domainId (or) invalid ad timeout (or) invalid video timeout received.
 
 (e.g) Malformed Ad Server Url: shadow01.yumenetworks.com (url without “http://”)
 @param          None
 @result         JS SDK
 - Attempts to initialize with the YuMe Ad Params provided by the application but fails.
 - Notify the following log to Native SDK:
 Malformed  Ad Server Url.
 - Notifies YuMeAdEventInitFailed event.
 
 Native SDK
 - Notifies YuMeAdEventInitFailed event received from JS SDK to application.
 
 - Initialization Fails.
 */
- (void)test_INIT_025 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pAdServerUrl = @"shadow01.yumenetworks.com";
    params.pDomainId = @"211EsvNSRHO1";
    
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                              errorInfo:&pError], @"Initialization Failed.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Malformed Ad Server Url.", @"");
        //GHTestLog(@"Result : %@", str);
    }
    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    //GHTestLog(@"Result: Initialization Fails.");
}

/*!
 @function       test_INIT_026
 @abstract       test_INIT_026 : Check Init API Case -> Pre Condition : SDK State: Not Initialized JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains valid ad server url and valid video timeout, but ad timeout is > 60.
 - JS SDK attempt to fetch YuMe Ad Params (yume_params.json) fails (or) Fetching succeeds but  invalid (or) malformed ad server url (or) invalid domainId (or) invalid ad timeout (or) invalid video timeout received.
 
 (e.g) Malformed Ad Server Url: shadow01.yumenetworks.com (url without “http://”)
 @param          None
 @result         JS SDK
 - Attempts to initialize with the YuMe Ad Params provided by the application but fails.
 - Notify the following log to Native SDK:
 Invalid Ad Connection Timeout value. It cannot exceed 60.
 - Notifies YuMeAdEventInitFailed event.
 
 Native SDK
 - Notifies YuMeAdEventInitFailed event received from JS SDK to application.
 
 - Initialization Fails.
 */
- (void)test_INIT_026 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO1";
    params.adTimeout = 61;
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                              errorInfo:&pError], @"Initialization Failed.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Invalid Ad Connection Timeout value. It cannot exceed 60.", @"");
        //GHTestLog(@"Result : %@", str);
    }
    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    //GHTestLog(@"Result: Initialization Fails.");
}

/*!
 @function       test_INIT_027
 @abstract       test_INIT_027 : Check Init API Case -> Pre Condition : SDK State: Not Initialized. JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains valid ad server url and valid ad timeout, but video timeout is > 60.
 - JS SDK attempt to fetch YuMe Ad Params (yume_params.json) fails (or) Fetching succeeds but  invalid (or) malformed ad server url (or) invalid domainId (or) invalid ad timeout (or) invalid video timeout received.
 
 (e.g) Malformed Ad Server Url: shadow01.yumenetworks.com (url without “http://”)
 @param          None
 @result         JS SDK
 - Attempts to initialize with the YuMe Ad Params provided by the application but fails.
 - Notify the following log to Native SDK:
 Invalid Progressive Download Timeout Value. It cannot exceed 60.
 - Notifies YuMeAdEventInitFailed event.
 
 Native SDK
 - Notifies YuMeAdEventInitFailed event received from JS SDK to application.
 
 - Initialization Fails.
 */
- (void)test_INIT_027 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO1";
    params.videoTimeout = 61;
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertFalse([pYuMeSDK yumeSdkInit:params
                            appDelegate:pYuMeInterface
                              errorInfo:&pError], @"Initialization Failed.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkInit(): Invalid Progressive Download Timeout Value. It cannot exceed 60.", @"");
        //GHTestLog(@"Result : %@", str);
    }
    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    //GHTestLog(@"Result: Initialization Fails.");
}

/*!
 @function       test_INIT_028
 @abstract       test_INIT_028 : Check Init API Case -> Pre Condition : SDK State: Not Initialized
 JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains valid ad server url and valid video timeout, but ad timeout is < 4.
 - JS SDK attempt to fetch YuMe Ad Params (yume_params.json) fails (or) Fetching succeeds but  invalid (or) malformed ad server url (or) invalid domainId (or) invalid ad timeout (or) invalid video timeout received.
 
 (e.g) Malformed Ad Server Url: shadow01.yumenetworks.com (url without “http://”)
 @param          None
 @result         JS SDK
 - Ignores the ad timeout value provided by the application.
 - Gets initialized with YuMe Ad Params provided by the application and sets the ad timeout to the default value of 5 seconds – appropriate JS SDK Log should be present to know this.
 - Notifies YuMeAdEventInitSuccess event.
 
 Native SDK
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 - Initialization Successful.
 */
- (void)test_INIT_028 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.adTimeout = 3;
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Result: Initialization Successful.");
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    
    XCTAssertEqual(adParams.adTimeout, 5, @"YuMe Ad Params retrieved and sets the ad timeout to the default value of 5 seconds");
}

/*!
 @function       test_INIT_029
 @abstract       test_INIT_029 : Check Init API Case -> Pre Condition : SDK State: Not Initialized. JS SDK Resources: Cached already and SDK attempts JS SDK Init.
 @discussion     This function called NOTE: YuMe Ad Params from app contains valid ad server url and valid ad timeout, but video timeout is < 3.
 - JS SDK attempt to fetch YuMe Ad Params (yume_params.json) fails (or) Fetching succeeds but  invalid (or) malformed ad server url (or) invalid domainId (or) invalid ad timeout (or) invalid video timeout received.
 
 (e.g) Malformed Ad Server Url: shadow01.yumenetworks.com (url without “http://”)
 @param          None
 @result         JS SDK
 - Ignores the video timeout value provided by the application.
 - Gets initialized with YuMe Ad Params provided by the application and sets the video timeout to the default value of 6 seconds – appropriate JS SDK Log should be present to know this.
 - Notifies YuMeAdEventInitSuccess event.
 
 Native SDK
 - Notifies YuMeAdEventInitSuccess event received from JS SDK to application.
 - Initialization Successful.
 */
- (void)test_INIT_029 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.videoTimeout = 2;
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"Fail : %@", [NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    //GHTestLog(@"Result: Initialization Successful.");
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    
    XCTAssertEqual(adParams.videoTimeout, 6, @"YuMe Ad Params retrieved and sets the video timeout to the default value of 6 seconds");
}

/*!
 @function       test_INIT_030
 @abstract       test_INIT_030 : Check Init API Case -> Pre Condition : SDK State: Not Initialized
 @discussion     This function called When JS SDK fetches yume config params from CDN, it receives a JSON with “disable_ad_serving: true”.
 @param          None
 @result         JS SDK
 - Considers Initialization as Failed and prints the following logs in order:
 - Ad serving has been disabled at this time.
 - No Ads can be served. Please reinitialize and try again.
 - Notifies YuMeAdEventInitFailed event.
 
 Native SDK
 - Notifies YuMeAdEventInitFailed event received from JS SDK to application.
 - Initialization Fails.
 */
- (void)test_INIT_030 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];

    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    
    if (pError) {
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        //GHTestLog(@"Result: Initialization Fails.");
    }
}

/*!
 @function       test_INIT_031
 @abstract       test_INIT_031 : Check Init API Case -> Pre Condition : SDK State: Not Initialized
 @discussion     This function called When JS SDK fetches yume config params from CDN, it receives a JSON which contains the current Native SDK Version as one of the values in “disable_sdk_versions”.
 @param          None
 @result         JS SDK
 - Considers Initialization as Failed and prints the following logs in order:
 - Ad serving has been disabled at this time.
 - No Ads can be served. Please reinitialize and try again.
 - Notifies YuMeAdEventInitFailed event.
 
 Native SDK
 - Notifies YuMeAdEventInitFailed event received from JS SDK to application.
 - Initialization Fails.
 */
- (void)test_INIT_031 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    //GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    //GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    params = nil;
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitFailed], nil];
    [self performSelectorInBackground:@selector(initEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    //GHTestLog(@"Notifies YuMeAdEventInitFailed event.");
    
    if (pError) {
        //GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        //GHTestLog(@"Result: Initialization Fails.");
    }
}

@end
