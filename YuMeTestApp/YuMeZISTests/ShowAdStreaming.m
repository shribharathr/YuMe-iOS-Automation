//
//  ShowAdStreaming.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"


@interface ShowAdStreaming : XCTAsyncTestCase

@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;
@property (nonatomic) BOOL bSDKInitalized;

@end

@implementation ShowAdStreaming

@synthesize adDisplayViewController;
@synthesize presentedAdViewController;
@synthesize bSDKInitalized;

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
    bSDKInitalized = FALSE;
}

- (void)tearDown {
    NSError *pError = nil;
    
    // Run after each test method
    if (pYuMeSDK) {
        [pYuMeSDK yumeSdkDeInit:&pError];
        bSDKInitalized = FALSE;
    }
    [self runForInterval:1];
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)showAdStrEventListener:(NSArray *)userInfo {
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

/*
- (void)presentShowAd:(NSError **)pError {
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    [adDisplayViewController presentViewController:presentedAdViewController animated:NO completion:^() {
        NSLog(@"Presented Roll View Controller in Application: %@", presentedAdViewController);
        XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo:pError], @"");
    }];
}

- (void)dismissShowAd {
    if (adDisplayViewController != nil) {
        [adDisplayViewController dismissViewControllerAnimated:YES completion:^{
            NSLog(@"Dismissed Roll View Controller in Application");
        }];
        adDisplayViewController = nil;
        presentedAdViewController = nil;
    }
}
*/


/**
 SDK State: Not Initialized
 Called when SDK is not initialized.
 
 Native SDK
 - Returns error message: "yumeSdkShowAd(): YuMe SDK is not Initialized."
 */
- (void)test_SHOW_AD_STR_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    XCTAssertFalse([pYuMeSDK yumeSdkShowAd:pYuMeInterface.yViewController.view viewController:pYuMeInterface.yViewController errorInfo:&pError], @"");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkShowAd(): YuMe SDK is not Initialized.", @"");
        NSLog(@"Result: %@", str);
    }
    pError = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Previous Ad play is in progress.
 
 Native SDK
 - Returns error message: "yumeSdkShowAd(): Previous Ad Play in Progress."
 - Previous ad play continues.
 */
- (void)test_SHOW_AD_STR_002 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:1];
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo1];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@" YuMeAdEventAdReadyToPlay event.");
    NSLog(@"yumeSdkShowAd() Successful.");

    [self runForInterval:2];
    
    XCTAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo:&pError], @"");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkShowAd(): Previous Ad Play in Progress.", @"");
        NSLog(@"Result: %@", str);
    }
    pError = nil;
    
    [self runForInterval:2];
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo3];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Invalid Ad View / Ad Layout Passed.
 
 Native SDK
 - Returns error message: "yumeSdkShowAd(): Invalid Ad View handle.", if AdView is invalid.
 (or)
 - Returns error message: "yumeSdkShowAd(): Invalid Ad View Controller handle.", if AdViewController is invalid.
 */
- (void)test_SHOW_AD_STR_003 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:1];
    
    pError = nil;
    XCTAssertFalse([pYuMeSDK yumeSdkShowAd:nil viewController:pYuMeInterface.yViewController errorInfo:&pError], @"");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkShowAd(): Invalid Ad View handle.", @"");
        NSLog(@"Result: %@", str);
    }
    
    [self runForInterval:1];
    
    pError = nil;
    XCTAssertFalse([pYuMeSDK yumeSdkShowAd:pYuMeInterface.yViewController.view viewController:nil errorInfo:&pError], @"");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkShowAd(): Invalid Ad View Controller handle.", @"");
        NSLog(@"Result: %@", str);
    }
    pError = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING	No network connection.
 
 Native SDK
 - Returns error message: "yumeSdkShowAd(): No Network Connection available.".
 */
- (void)test_SHOW_AD_STR_004 {
    XCTFail(@"%@",@"Please do it manually");
    NSLog(@"Result : %@", @"Please do it manually");
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING	Request times out.
 
 Native SDK
 -  the following events from JS SDK:
 1. YuMeAdEventAdNotReady (YuMeAdStatusRequestTimedOut)
 2. YuMeAdEventAdCompleted.
 */
- (void)test_SHOW_AD_STR_005 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);

    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@" YuMeAdEventInitSuccess event.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pAdServerUrl = @"http://172.18.8.176/~bharath/utest/v_404"; ///
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdNotReady event received.");
    [self runForInterval:2];
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
    
    [self runForInterval:1];
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 A non-200 OK response is received (OR)
 A 200 OK response is received but the playlist is empty (OR)
 A 200 OK is received, playlist is filled but doesn't contain the required assets. (OR)
 A 200 OK is received, but error occurred while parsing.
 
 Native SDK
 -  the following events from JS SDK:
 1. YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed)
 2. YuMeAdEventAdCompleted.
 */
- (void)test_SHOW_AD_STR_006 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];

        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pAdServerUrl = EMPTY_VALID_URL; 
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    [self runForInterval:2];
    NSLog(@"ModifyParams Successful.");

    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    //[adDisplayViewController presentViewController:presentedAdViewController animated:NO completion:^() {
        //NSLog(@"Presented Roll View Controller in Application: %@", presentedAdViewController);
        XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    //}];

    //[self presentShowAd:&error];
    if (pError) {
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdNotReady event received.");
    
    [self runForInterval:2];
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;

    dispatch_after(0, dispatch_get_main_queue(), ^{
        //[self dismissShowAd];
    });
    
    [self runForInterval:1];
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING - Valid Filled Playlist received.
 - The playlist contains the required assets and all the assets valid.
 
 Native SDK
 -  the following events from JS SDK:
 1. YuMeAdEventAdReadyToPlay
 2. YuMeAdEventAdPlaying
 3. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess)
 
 JS SDK
 1.  YuMeAdEventAdPlaying event.
 2. Plays the ad from network (uses cached assets, if available) .
 3.  YuMeAdEventAdPlaying event.
 4. Hits the impression trackers received in the playlist, at appropriate times.
 5. On ad completion,
 5a)  YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event.
 */
- (void)test_SHOW_AD_STR_007 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@" YuMeAdEventAdReadyToPlay event.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
    
    [self runForInterval:1];
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 When prefetch operation is performed previously (or) currently in progress .
 
 JS SDK
 1. Stops the prefetch timers, if running (ad expiry timer, prefetch request callback timer & auto prefetch timer).
 2. Aborts the ongoing/paused downloads.
 3. Resets the auto-prefetch time interval.
 4. Makes a new non-prefetch playlist request to the server.
 5. Handles the response received.
 */
- (void)test_SHOW_AD_STR_008 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
        params.pDomainId = @"211EsvNSRHO";
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
        
        XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        params = nil;
        [self runForInterval:2];
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    
    //[YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }
    
    /*
    NSError *error = nil;
    [self presentShowAd:&error];
    if (error) {
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:error] description]);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:error] description]]);
    }
    
    NSString *testString = @"Stopping Ad Expiry Timer.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        pError = nil;
        NSLog(@"Result: %@", testString);
    } else {
        //[self dismissShowAd];
        presentedAdViewController = nil;
        adDisplayViewController = nil;

        XCTFail(@"%@",@"Result : Failed to receive %@", testString);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event received.");
    
    [self runForInterval:2);
     */
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    //[self dismissShowAd];
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    [self runForInterval:1];
}


/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Valid Filled Playlist is received but the main creative (log_url (or) video url)  results in 404 response.
 
 Native SDK
 -  the following events from JS SDK:
 1. YuMeAdEventAdReadyToPlay
 2. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackFailed)
 
 JS SDK
 1.  YuMeAdEventAdReadyToPlay event.
 2. Attempts plays the ad from network (uses cached assets, if available) .
 3. When 404 asset response is received.
 3a)  YuMeAdEventAdCompleted (YuMeAdStatusPlaybackFailed) event.
 */
- (void)test_SHOW_AD_STR_009 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }

    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:2];
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Video play head doesn't move (progress) for the video time interval specified during initialization (before ad play start (or) after ad play start).			Native SDK
 -  the following events from JS SDK:
 1. YuMeAdEventAdReadyToPlay
 2. YuMeAdEventAdPlaying
 3. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackTimedOut)
 
 JS SDK
 1. Ad Play Times out.
 2.  YuMeAdEventAdCompleted (YuMeAdStatusPlaybackTimedOut) event.
 */
- (void)test_SHOW_AD_STR_010 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:2];
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo3];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 
 Asset Selection Logic when SDK is initialized with videoAdFormatsPriorityList:[VideoFormat1, VideoFormat2, VideoFormat3]
 bSupportHighBitRate = default (true)
 bSupportAutoNetworkDetect = default (false)
 
 JS SDK
 1. Selects one of the following bitrate assets based on the order specified by video ad formats priority list:
 a. High Bitrate (384K)
 b. Medium Bitrate (150K)
 c. Low Bitrate (130K)
 d. 1st url received in the playlist, belonging to the particular video ad format.
 
 */
- (void)test_SHOW_AD_STR_011 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:2];
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 
 Asset Selection Logic when SDK is initialized with
 VideoAdFormatsPriorityList: Not specified during Initialization.
 bSupportHighBitRate = default (true)
 bSupportAutoNetworkDetect = default (false)
 
 JS SDK
 1. Set the default priority list as follows:
 - [HLS, MP4, MOV] -> iOS
 - [HLS, MP4, 3GPP] -> Android
 2. Selects one of the following bitrate assets based on the order specified by video ad formats priority list:
 a. High Bitrate (384K)
 b. Medium Bitrate (150K)
 c. Low Bitrate (130K)
 d. 1st url received in the playlist, belonging to the particular video ad format.
 */
- (void)test_SHOW_AD_STR_012 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    params.pVideoAdFormatsPriorityList = nil;
    params.bSupportHighBitRate = YES;
    params.bSupportAutoNetworkDetect = NO;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo3];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 
 Asset Selection Logic when SDK is initialized with
 bsupportHighBitRate = false
 bsupportAutoNetworkDetect = true / false.
 
 JS SDK
 1. Selects one of the following bitrate assets based on the order specified by video ad formats priority list:
 a. Low Bitrate (130K)
 b. Medium Bitrate (150K)
 c. High Bitrate (384K)
 d. 1st url received in the playlist, belonging to the particular video ad format.
 */
- (void)test_SHOW_AD_STR_013 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    params.bSupportHighBitRate = NO;
    params.bSupportAutoNetworkDetect = NO;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Asset Selection Logic when SDK is initialized with
 bsupportHighBitRate = true
 bSupportAutoNetworkDetect = true / false.
 
 JS SDK
 1. Selects one of the following bitrate assets based on the order specified by video ad formats priority list:
 a. High Bitrate (384K)
 b. Medium Bitrate (150K)
 c. Low Bitrate (130K)
 d. 1st url received in the playlist, belonging to the particular video ad format.
 */
- (void)test_SHOW_AD_STR_014 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    params.bSupportHighBitRate = YES;
    params.bSupportAutoNetworkDetect = YES;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 
 Asset Selection Logic when SDK is initialized with
 bsupportHighBitRate = true / false
 bSupportAutoNetworkDetect = true & Cellular connectivity is present & WiFi connectivity is not present.
 JS SDK
 1. Selects one of the following bitrate assets based on the order specified by video ad formats priority list:
 a. Low Bitrate (130K)
 b. Medium Bitrate (150K)
 c. High Bitrate (384K)
 d. 1st url received in the playlist, belonging to the particular video ad format.
 */
- (void)test_SHOW_AD_STR_015 {
    NSString *str = @"Please do it manually.";
    NSLog(@"Result : %@", str);
    XCTFail(@"%@",str);
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Asset Selection Logic when SDK is initialized with
 bsupportHighBitRate = true / false
 bSupportAutoNetworkDetect = true & WiFi connectivity is present.
 
 JS SDK
 1. Selects one of the following bitrate assets based on the order specified by video ad formats priority list:
 a. High Bitrate (384K)
 b. Medium Bitrate (150K)
 c. Low Bitrate (130K)
 d. 1st url received in the playlist, belonging to the particular video ad format.
 */
- (void)test_SHOW_AD_STR_016 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    params.bSupportHighBitRate = YES;
    params.bSupportAutoNetworkDetect = YES;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Valid Playlist received with video url that gets redirected.
 The ad should play fine with the redirected video url.
 */
- (void)test_SHOW_AD_STR_017 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pAdServerUrl = @"";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Valid Playlist received with image url that gets redirected.
 The ad should play fine with the redirected image url.
 */
- (void)test_SHOW_AD_STR_018 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pAdServerUrl = @"";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo3];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Valid Playlist received with overlay url that gets redirected.
 The ad should play fine with the redirected overlay url.
 */
- (void)test_SHOW_AD_STR_019 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    NSLog(@"Initializes with the fetched YuMe Ad Params.");
    if (!bSDKInitalized) {
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
        
        [self prepare];
        NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        
        NSLog(@"YuMeAdEventInitSuccess event received.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitalized = TRUE;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pAdServerUrl = @"";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    pError = nil;
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo: &pError], @"");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        NSLog(@"Error: %@", str);
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , str]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdStrEventListener:) withObject:userInfo3];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event received.");
    
    adDisplayViewController = nil;
    presentedAdViewController = nil;
}


/**
 SDK State: Initialized
 Caching: ON  / OFF
 Auto-Prefetch: ON / OFF
 SDK Mode: STREAMING
	Sending of Excluded ads list in JSON body of the next streaming playlist request.
 
 JS SDK
 - Whenever an invalid playlist is received from the server (unsupported formats, missing tags etc.,), the ad_id of the particular ad should be maintained and the same list should be notified to the server using “exclude_ads” value in the JSON request, when the next playlist request is being sent out.
 
 - If any invalid ad is later found to be valid, it should be removed from the list of ads to be excluded.
 */
- (void)test_SHOW_AD_STR_020 {
    NSString *str = @"Please do it manually.";
    NSLog(@"Result : %@", str);
    XCTFail(@"%@",str);
}

/**
 SDK State: Initialized
 Caching: ON  / OFF
 Auto-Prefetch: ON / OFF
 SDK Mode: STREAMING
	Sending of Config Params version in JSON body of the streaming playlist request.
 
 JS SDK
 - The Config Param version received in the YuMe Config Params (config_params_version) received from CDN during Initialization should be sent to the server using “config_file_version” value in the JSON request, when a the playlist request is being sent out.
 */
- (void)test_SHOW_AD_STR_021 {
    NSString *str = @"Please do it manually.";
    NSLog(@"Result : %@", str);
    XCTFail(@"%@",str);
}

@end
