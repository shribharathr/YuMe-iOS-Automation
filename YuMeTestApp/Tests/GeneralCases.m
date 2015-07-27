//
//  GeneralCases.m
//
#import <GHUnit/GHUnit.h>
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

@interface GeneralCases : GHAsyncTestCase

@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;

@end

@implementation GeneralCases
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
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    GHRunForInterval(1);
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)genEventListener:(NSArray *)userInfo {
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
 SDK State: Initialized
 SDK Mode: PREFETCH
 Caching: ON/OFF
 Auto-Prefetch: ON / OFF
 
 Prefetch Callback Timer expired.
 
 JS SDK
 1. Makes a new prefetch request to the server.
 2. Handles the response received.
 */
- (void)test_GEN_001 {
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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = EMPTY_VALID_URL;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);
        
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event fired.");

    GHRunForInterval(60);
    
    GHTestLog(@"Prefetch Callback Timer expired.");

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event fired.");
}


/**
 SDK State: Initialized
 SDK Mode: PREFETCH

 - InitAd called and a valid filled playlist is received with a 404 creative.
 - creative_retry_interval: <=0 (or) missing.
 - creative_retry_attempts: 'n'.

 JS SDK
 1. Uses the default value for the creative_retry_interval, which is 10 seconds.
 - Retries downloading the 404 asset 'n' number of times at 10 seconds interval.
*/
- (void)test_GEN_002 {
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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = FILLED_CREATIVERETRYINTERVAL;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event fired.");
}

/**
 SDK State: Initialized
 SDK Mode: PREFETCH	
 
 - InitAd called and a valid filled playlist is received with a 404 creative.
 - creative_retry_interval: 'n'.
 - creative_retry_attempts: <=0 (or) missing.
 
 JS SDK
 1. Uses the default value for the creative_retry_attempts, which is 5.
 
 - Retries downloading the 404 asset 5 times at 'n' seconds interval.
 */
- (void)test_GEN_003 {
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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = FILLED_CREATIVERETRYATTEMPTS;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event fired.");
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING	
 
 Events to be dispatched for Streaming ads.			
 
 1. YuMeAdEventAdNotReady (YuMeAdStatusRequestTimedOut): If request times out.
 2. YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed): If the playlist is invalid, empty (or) non-200 OK response is received.
 3. YuMeAdEventAdReadyToPlay: Valid ad received and required assets found.
 4. YuMeAdEventAdPlaying: If ad play starts.
 5. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess): Ad Play Successful.
 6. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackTimedOut): Ad Play Timed Out.
 7. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackFailed): Ad Play Failed.
 8. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackInterrupted): Ad Play Skipped (or) Call operation performed during ad play.
 */
- (void)test_GEN_004 {
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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pAdServerUrl = @"http://shadow02.yumenetworks.com";
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);
    
    // 1. YuMeAdEventAdNotReady (YuMeAdStatusRequestTimedOut): If request times out.
    GHTestLog(@"1. YuMeAdEventAdNotReady (YuMeAdStatusRequestTimedOut): If request times out.");
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event fired.");

    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    GHRunForInterval(2);


    // 2. YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed): If the playlist is invalid, empty (or) non-200 OK response is received.
    GHTestLog(@"2. YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed): If the playlist is invalid, empty (or) non-200 OK response is received.");

    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pAdServerUrl = EMPTY_VALID_URL;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);

    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event fired.");
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    GHRunForInterval(2);

    
    // 3. YuMeAdEventAdReadyToPlay: Valid ad received and required assets found.
    GHTestLog(@"3. YuMeAdEventAdReadyToPlay: Valid ad received and required assets found.");

    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);

    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo3];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay / YuMeAdEventAdPlaying event fired.");

    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo5 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo5];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");

    presentedAdViewController = nil;
    adDisplayViewController = nil;
}

/**
 SDK State: Initialized
 SDK Mode: PREFETCH	
 
 Events to be dispatched for all initAd (or) auto-prefetch calls.
 
 1. YuMeAdEventAdNotReady (YuMeAdStatusRequestTimedOut): If request times out.
 2. YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed): If the playlist is invalid (or) non-200 OK response is received.
 3. YuMeAdEventAdNotReady (YuMeAdStatusEmptyAdInCache): If empty ad is received (or) exists in cache.
 4. YuMeAdEventAdNotReady (YuMeAdStatusCachingFailed): If assets' caching failed.
 5. YuMeAdEventAdNotReady (YuMeAdStatusCachedAdExpired): If cached ad expired.
 6. YuMeAdEventAdNotReady (YuMeAdStatusCachingInProgress): If asset's caching in progress.
 7. YuMeAdEventAdReadyToPlay: Prefetched ad ready for playing.
 8. YuMeAdEventAdPlaying: If ad play starts.
 9. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess): Ad Play Successful.
 10. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackTimedOut): Ad Play Timed Out.
 11. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackFailed): Ad Play Failed.
 12. YuMeAdEventAdCompleted (YuMeAdStatusPlaybackInterrupted): Ad Play Skipped (or) Call operation performed during ad play.
 */
- (void)test_GEN_005 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pAdServerUrl = EMPTY_VALID_URL;
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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
}

/**
 SDK State: Initialized
 SDK Mode: PREFETCH
 Auto-Prefetch: ON	
 
 1. Call InitAd() with Caching: OFF.
 2. Once, ad is ready for playing, turn Caching: ON
 3. Call ShowAd.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops the ad expiry timer.
 2. Hits the Filled tracker received in the playlist.
 3. Plays the ad from network (uses cached assets, if available) .
 4. Notifies YuMeAdEventAdPlaying event.
 5. Hits the impression trackers received in the playlist, at appropriate times.
 6. On ad completion,
 6a) Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event.
 6b) auto-prefetches a new playlist from the server.
 6c) downloads the assets.
 6d) starts the ad expiry timer, once assets are downloaded.
 */
- (void)test_GEN_006 {
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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    // 1. Call InitAd() with Caching: OFF.
    pError = nil;
    params.bEnableCaching = NO;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");

    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkSetCacheEnabled:YES errorInfo:&pError], @"yumeSdkSetCacheEnabled failed.");
    
    GHRunForInterval(2);
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo3];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay / YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo5 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo5];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;

    [self prepare];
    NSArray *userInfo6 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady]], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo6];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay / YuMeAdEventAdNotReady event fired.");
}

/**
 SDK State: Initialized
 SDK Mode: PREFETCH
 Auto-Prefetch: ON/OFF	
 
 1. Call InitAd() with Caching: OFF.
 2. Once, ad is ready for playing, turn Caching: ON.
 3. Call InitAd again.			
 
 JS SDK
 1. Notifies YuMeAdEventAdReadyToPlay immediately.
 2. Leaves the Ad expiry timer undisturbed.
 3. Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 4. Initiates asset's caching.
 */
- (void)test_GEN_007 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    // 1. Call InitAd() with Caching: OFF.
    pError = nil;
    params.bEnableCaching = NO;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkSetCacheEnabled:YES errorInfo:&pError], @"yumeSdkSetCacheEnabled failed.");
    GHRunForInterval(2);
    
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Call InitAd again.");
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    
    NSString *testString = @"New Init Ad Request IGNORED as it is same as the previous request.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 SDK State: Initialized
 SDK Mode: PREFETCH	
 
 initAd called when all the assets for one (or) more ads exists in cache.
 
 JS SDK
 1. Populates the (ad_guid) element in the JSON object with the ad_guid values of all those ads.
 
 */
- (void)test_GEN_008 {
    //[YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];
    
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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    GHRunForInterval(10);
}

#if 0
/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params "1=one&2=two&3=three&4=four&5=five&6=six&7=seven&8=eight&9=nine&10=ten1,ten2"
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?1=one&2=two&3=three&4=four&5=five&6=six&7=seven&8=eigth&9=nine&10=ten1%2Cten2
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24912154","latitude":"12.995290180000001","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"","imu":[],"publisher_page":""}

 */
- (void)test_GEN_009 {
    //[YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdditionalParams = @"1=one&2=two&3=three&4=four&5=five&6=six&7=seven&8=eight&9=nine&10=ten1,ten2";
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);

    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    NSString *testString = @"http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&1=one&2=two&3=three&4=four&5=five&6=six&7=seven&8=eight&9=nine&10=ten1,ten2";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params
 ""
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24912154","latitude":"12.995290180000001","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"","imu":[],"publisher_page":""}

 */
- (void)test_GEN_010 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params:
 "a=AAA&b=BBB&c=CC C&d=DDDD"
 
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?a=AAA&b=BBB&c=CC%20C&d=DDDD
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24912154","latitude":"12.995290180000001","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"","imu":[],"publisher_page":""}

 */
- (void)test_GEN_011 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params "a=b&a=m&c=d&e=f&age=25&gender=male&interests=Gardening,Reading Books,Listening Music&keywords=key1&income=10000&education=B.E (ECE)&guid=10&title=Ad Video&duration=15&categories=video,audio&tags=india,tamil nadu,andhra"
 
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?a=b&a=m&c=d&e=f
 
 Playlist Request Body
 {"content":{"tags":["india","tamil nadu","andhra"],"guid":"10","categories":["video","audio"],"duration":"15","title":"Ad Video"},"demography":{"gender":"male","keywords":["key1"],"education":"B.E (ECE)","interests":["Gardening","Reading Books","Listening Music"],"income":"10000","age":"25"},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.2448366","latitude":"12.9860368","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"","imu":[],"publisher_page":""}

 */
- (void)test_GEN_012 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params "publisher_channel=channel&publisher_page=yume.com&imu=medrect,widesky,full_banner&exclude_placements=20000,20001&a=b&c=d&e=f&age=25&gender=male&interests=Gardening,Reading Books,Listening Music&keywords=key1&income=10000&education=B.E (ECE)&guid=10&title=Ad Video&duration=15&categories=video,audio&tags=india,tamil nadu,andhra&state=tamilnadu&city=chennai&postal_code=600028"
 
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?a=b&c=d&e=f
 
 Playlist Request Body
 {"content":{"tags":["india","tamil nadu","andhra"],"guid":"10","categories":["video","audio"],"duration":"15","title":"Ad Video"},"demography":{"gender":"male","keywords":["key1"],"education":"B.E (ECE)","interests":["Gardening","Reading Books","Listening Music"],"income":"10000","age":"25"},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"","postal_code":"600028","state":"tamilnadu","gyroscope":"portrait","longitude":"80.24912154","latitude":"12.995290180000001","city":"chennai","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":["20000","20001"],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"channel","imu":["medrect","widesky","full_banner"],"publisher_page":"yume.com"}

 */
- (void)test_GEN_013 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params
 "placement_id=7129"
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?placement_id=7129
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24860685","latitude":"12.993759516666666","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"","imu":[],"publisher_page":""}

 */
- (void)test_GEN_014 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params "publisher_channel=highlights&iabcat=Sports&iabsubcat=WorldSoccer&client_ip=193.35.132.6"
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?iabcat=Sports&iabsubcat=WorldSoccer
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"193.35.132.6","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24860685","latitude":"12.993759516666666","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"highlights","imu":[],"publisher_page":""}

 */
- (void)test_GEN_015 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params
 "education1=B.E (ECE)"
 
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?education1=B.E%20(ECE)
 education1=B.E%20(ECE)
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"193.35.132.6","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24860685","latitude":"12.993759516666666","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"highlights","imu":[],"publisher_page":""}

 */
- (void)test_GEN_016 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING
	
 The following Query string params is passed during Initialization / Modify Params:
 QS Params
 "education1= %^{}|\\\"<>`"
 
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?education1=%20%25%5E%7B%7D%7C%5C%22%3C%3E%60
 education1=%20%25%5E%7B%7D%7C%5C%22%3C%3E%60
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"193.35.132.6","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24860685","latitude":"12.993759516666666","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"highlights","imu":[],"publisher_page":""}

 */
- (void)test_GEN_017 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params
 "education1=~@#$&*()_-+=[]?;:'./"
 
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?education1=~%40%23%24&*()_-%2B=%5B%5D%3F%3B%3A'.%2F
 education1=~%40%23%24&*()_-%2B=%5B%5D%3F%3B%3A' .%2F
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"193.35.132.6","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24860685","latitude":"12.993759516666666","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"highlights","imu":[],"publisher_page":""}

 */
- (void)test_GEN_018 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK Mode: PREFETCH / STREAMING	
 
 The following Query string params is passed during Initialization / Modify Params:
 QS Params
 " higher education = M.E& a=b "
 
 1. SDK frames the playlist url and the JSON object as follows:
 Playlist Url http://shadow01.yumenetworks.com/dynamic_preroll_playlist.xml?%20higher%20education%20=%20M.E&%20a=b%20
 %20higher%20education%20=%20M.E&%20a=b%20
 
 Playlist Request Body
 {"content":{"tags":[],"guid":"","categories":[],"duration":"","title":""},"demography":{"gender":"","keywords":[],"education":"","interests":[],"income":"","age":""},"connection":{"type":"WiFi","bandwidth":"","service_provider":"sprint"},"referrer":"","geography":{"ip_address":"193.35.132.6","postal_code":"","state":"","gyroscope":"portrait","longitude":"80.24860685","latitude":"12.993759516666666","city":"","country":"us"},"player":{"height":"960","width":"540","version":""},"playlist_version":"v2","yume_sdk":{"exclude_placements":[],"pre_fetch":"false","ad_guid":[],"version":"3.0.10.9"},"device":{"os":"Android","storage_quota_in_mb":"10.0","model":"MB855","height":"960","width":"540","hardware_version":"","uuid":"ddfad7619103f352494da8df598bd747","make":"motorola","os_version":"2.3.4"},"domain":"211yCcbVJNQ","publisher_channel":"highlights","imu":[],"publisher_page":""}

 */
- (void)test_GEN_019 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}
#endif

/**
 SDK State: Initialized
 SDK Mode: PREFETCH	
 
 Valid Filled Playlist is received with <expiration_time> element missing (or) expiration_time <= 0.
 
 JS SDK
 1. Uses the default value for the expiration_time, which is 300 seconds.
 
 */
- (void)test_GEN_020 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_EXPIRATIONTIME;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams failed.");
    
    GHRunForInterval(1);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd failed.");
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    GHRunForInterval(1);
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady]], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay/ YuMeAdEventAdNotReady event fired.");
    
    NSString *testString = @"Starting Ad Expiry Timer: Interval (secs): 300";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 SDK State: Initialized
 SDK Mode: PREFETCH	
 
 Valid Empty Playlist is received with <pre_fetch_call_back_interval> element missing (or) pre_fetch_call_back_interval <= 0.
 
 JS SDK
 1. Uses the default value for the pre_fetch_call_back_interval, which is 900 seconds.
 
 */
- (void)test_GEN_021 {
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];

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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_PFCALLBACKINTERVAL;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams failed.");
    
    GHRunForInterval(1);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd failed.");
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event fired.");
    
    NSString *testString = @"Starting Prefetch Request Callback Timer: Interval (secs): 900";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }

}

/**
 SDK State: Initialized
 SDK Mode: STREAMING (or) PREFETCH
	
 Valid Filled 2nd Gen Playlist is received with <cb_active_time> element missing (or) cb_active_time <= 0.
 
 JS SDK
 1. Uses the default value for the cb_active_time, which is 5 seconds.
 
 */
- (void)test_GEN_022 {
    //[YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];
    
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
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_PFCALLBACKINTERVAL;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams failed.");
    
    GHRunForInterval(1);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd failed.");
    GHTestLog(@"yumeSdkInitAd Successful.");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(genEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event fired.");
}

@end
