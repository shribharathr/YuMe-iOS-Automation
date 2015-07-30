//
//  ClearCache.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

@interface ClearCache : XCTAsyncTestCase

@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;

@end

@implementation ClearCache
@synthesize adDisplayViewController;
@synthesize presentedAdViewController;

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
        [self runForInterval:1];
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    [self runForInterval:2];
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)clearCacheEventListener:(NSArray *)userInfo {
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

- (void)presentShowAd {
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    [adDisplayViewController presentViewController:presentedAdViewController animated:NO completion:^() {
        NSLog(@"Presented Roll View Controller in Application: %@", presentedAdViewController);
        NSError *pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo:&pError], @"");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        pError = nil;
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

/**
 SDK State:Not Initialized
 Called when SDK is not  initialized.
 
 
 Native SDK
 - Returns error message: "yumeSdkClearCache(): YuMe SDK is not Initialized."
 
 */
- (void)test_C_CACHE_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    XCTAssertFalse([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkClearCache(): YuMe SDK is not Initialized.", @"yumeSdkClearCache(): YuMe SDK is not Initialized.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 No prefetch operation is attempted after SDK initialization.
 
 Native SDK
 1. Clears the assets in cache.
 
 */
- (void)test_C_CACHE_002 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(clearCacheEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");

    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: OFF
 
 Prefetch operation is completed (or) currently in progress (or) paused (or) aborted.
 
 
 Native SDK
 1. Clears the assets in cache.
 2. Clears the partly downloaded assets.
 
 JS SDK
 1. Stops the prefetch related timers, if running.
 2. Resets the auto-prefetch time interval.
 3. Aborts the ongoing downloads.
 4. Hits the first party error tracker by appending “&reason=52”.
 5. Clears the assets in cache.
 6. Performs the necessary internal clean-up.
 7. Sets the download status as NOT_IN_PROGRESS.
 
 */
- (void)test_C_CACHE_003 {
    [self runForInterval:2];

    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(clearCacheEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    pError = nil;
    params.bEnableAutoPrefetch = FALSE;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
 
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self runForInterval:2];
    
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
    
    [self runForInterval:2];
    
    pError = nil;
    YuMeDownloadStatus eDownloadStatus = [pYuMeSDK yumeSdkGetDownloadStatus:&pError];
    XCTAssertEqual(eDownloadStatus, YuMeDownloadStatusDownloadsNotInProgress, @"YuMeDownloadStatusDownloadsNotInProgress");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON
 
 Prefetch operation is completed (or) currently in progress (or) paused (or) aborted.
 
 
 Native SDK
 1. Clears the assets in cache.
 2. Clears the partly downloaded assets.
 
 JS SDK
 1. Stops the prefetch related timers, if running.
 2. Resets the auto-prefetch time interval.
 3. Aborts the ongoing downloads.
 4. Hits the first party error tracker by appending “&reason=52”.
 5. Clears the assets in cache.
 6. Performs the necessary internal clean-up.
 7. Sets the download status as NOT_IN_PROGRESS.
 8. Makes a new prefetch request (adSlot: Last fetched slot) to the server.
 9. Handles the response received.
 
 */
- (void)test_C_CACHE_004 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(clearCacheEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    pError = nil;
    params.bEnableAutoPrefetch = TRUE;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self runForInterval:2];
    
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
    
    pError = nil;
    YuMeDownloadStatus eDownloadStatus = [pYuMeSDK yumeSdkGetDownloadStatus:&pError];
    XCTAssertEqual(eDownloadStatus, YuMeDownloadStatusDownloadsNotInProgress, @"YuMeDownloadStatusDownloadsNotInProgress");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@, %@",  [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay],   [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady] ], nil];
    [self performSelectorInBackground:@selector(clearCacheEventListener:) withObject:userInfo1];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay /  YuMeAdEventAdNotReady event.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 
 Streaming / Prefetched Ad play in progress.
 
 
 JS SDK
 - Notify error message to Native SDK:
 "Ad Play in Progress."
 - Ignores the Clear Cache call.

 */
- (void)test_C_CACHE_005 {
    
    [self runForInterval:2];

    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
#if pYuMeMPlayerController
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeTestInterface
                   videoPlayerDelegate:videoController
                             errorInfo:&pError], @"Initialization Successful.");
#else
    XCTAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(clearCacheEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(clearCacheEventListener:) withObject:userInfo1];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");

    [self presentShowAd];
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(clearCacheEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdPlaying event.");

    [self runForInterval:2];
    
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkClearCache(): Ad Play in Progress.", @"yumeSdkClearCache(): Ad Play in Progress..");
        NSLog(@"Result : %@", str);
    }
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkStopAd:&pError], @"yumeSdkStopAd Successful.");
    
    [self dismissShowAd];
}

@end
