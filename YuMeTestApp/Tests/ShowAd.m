//
//  ShowAd.m
//
#import <GHUnit/GHUnit.h>
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

@interface ShowAd : GHAsyncTestCase

@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;

@end

@implementation ShowAd
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
        GHRunForInterval(1);
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    GHRunForInterval(1);
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)showAdEventListener:(NSArray *)userInfo {
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

- (void)presentShowAd:(NSError **)pError {
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    [adDisplayViewController presentViewController:presentedAdViewController animated:NO completion:^() {
        NSLog(@"Presented Roll View Controller in Application: %@", presentedAdViewController);
        GHAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo:pError], @"");
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
 SDK State: Not Initialized
 Called when SDK is not initialized.
 
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): YuMe SDK is not Initialized."
 
 */
- (void)test_SHOW_AD_001 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): YuMe SDK is not Initialized.", @"yumeSdkShowAd(): YuMe SDK is not Initialized.");
        GHTestLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Previous Ad play is in progress.
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): Previous Ad Play in Progress."
 
 - Previous ad play continues.
 
 */
- (void)test_SHOW_AD_002 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");

    NSError *error = nil;
    [self presentShowAd:&error];
    if (error) {
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:error] description]);
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:error] description]]);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event received.");
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): Previous Ad Play in Progress.", @"yumeSdkShowAd(): Previous Ad Play in Progress.");
        GHTestLog(@"Result : %@", str);
    }

    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo3];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event received.");

    [self dismissShowAd];
    
    GHRunForInterval(1);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Invalid Ad View / Ad Layout Passed.
 
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): Invalid Ad View handle.", if AdView is invalid.
 (or)
 - Returns NO with error message: "yumeSdkShowAd(): Invalid Ad View Controller handle.", if AdViewController is invalid.
 */
- (void)test_SHOW_AD_003 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:nil viewController:presentedAdViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): Invalid Ad View handle.", @"yumeSdkShowAd(): Invalid Ad View handle.");
        GHTestLog(@"Result : %@", str);
    }

    GHRunForInterval(2);
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];

    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:nil errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): Invalid Ad View Controller handle.", @"yumeSdkShowAd(): Invalid Ad View Controller handle.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 No network connection.
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): No Network Connection available.".
 
 */
- (void)test_SHOW_AD_004 {
    NSString *str = @"Please do it manually.";
    GHTestLog(@"Result : %@", str);
    GHFail(str);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 No Prefetch operation of the set Ad Slot, attempted earlier.
 
 
 Native SDK
 - Returns NO with error message “yumePluginShowAd(): No Prefetched Ad Present.”
 
 JS SDK
 1. Hits the Generic Empty tracker.
 (e.g)  http://shadow01.yumenetworks.com/static_register_unfilled_request.gif?sdk_version=3.2.4.6&domain=704oIaHzpGu&make=APPLE&width=320&height=460&slot_type=PREROLL&model=iPhone Simulator 4.2
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 
 */
- (void)test_SHOW_AD_005 {
    
    NSString *str = @"Please do it manually.";
    GHTestLog(@"Result : %@", str);
    GHFail(str);

    /*
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableAutoPrefetch = NO;
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");

    GHRunForInterval(1);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() failed.");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }

    GHRunForInterval(2);

    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumePluginShowAd(): No Prefetched Ad Present.", @"yumePluginShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    GHRunForInterval(1);
     */
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 Prefetched ad is present but empty.
 
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): No Prefetched Ad Present.".
 
 JS SDK
 1. Hits the Unfilled tracker received in the playlist.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 

 */
- (void)test_SHOW_AD_006 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = EMPTY_VALID_URL;
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(2);
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    GHRunForInterval(1);
    
    NSString *testString = @"static_register_unfilled_request.gif?";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        GHTestLog(@"Result: Hits the Unfilled tracker received in the playlist. %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 SDK State: Initialized
 Caching: OFF (OR)
 (Caching: ON & StorageSize: 0.0 MB)
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 
 Prefetched ad is present but assets are not cached.
 NOTE: All / Some of the assets of the current playlist may already have been cached during previous prefetch operations.
 
 
 Native SDK
 - Returns YES.
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops the ad expiry timer.
 2. Hits the Filled tracker received in the playlist.
 3. Plays the ad from network (uses cached assets, if available) .
 4. Notifies YuMeAdEventAdPlaying event.
 5. Hits the impression trackers received in the playlist, at appropriate times.
 6. Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event, on ad completion.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 

 */
- (void)test_SHOW_AD_007 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.bEnableCaching = NO;
    params.bEnableAutoPrefetch = NO;
    params.storageSize = 0.0f;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");

    NSError *error = nil;
    [self presentShowAd:&error];
    if (error) {
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:error] description]);
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:error] description]]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event received.");

    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo3];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event received.");
    
    [self dismissShowAd];
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: OFF (OR)
 (Caching: ON & StorageSize: 0.0 MB)
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 
 
 
 Prefetched ad is present but assets are not cached.
 NOTE: All / Some of the assets of the current playlist may already have been cached during previous prefetch operations.
 
 
 Native SDK
 - Returns YES.
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops the ad expiry timer.
 2. Hits the Filled tracker received in the playlist.
 3. Plays the ad from network (uses cached assets, if available) .
 4. Notifies YuMeAdEventAdPlaying event.
 5. Hits the impression trackers received in the playlist, at appropriate times.
 6. On ad completion,
 6a) Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event.
 6b) auto prefetches a new playlist from the server and handles the new playlist response.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 
 */
- (void)test_SHOW_AD_008 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.bEnableCaching = NO;
    params.bEnableAutoPrefetch = YES;
    params.storageSize = 0.0f;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    NSError *error = nil; 
[self presentShowAd:&error];
    if (error) {
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:error] description]);
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:error] description]]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event received.");
    
    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo3];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event received.");
    
    [self dismissShowAd];
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady]], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo4];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Asset Downloads operation in progress and no ad is readily available for playing.
 
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): No Prefetched Ad Present.".
 
 JS SDK
 1. Hits the Filled tracker received in the playlist.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 */
- (void)test_SHOW_AD_009 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    float percentage = 0.0f;
    do {
        GHRunForInterval(0.2);
        pError = nil;
        percentage = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
        
        NSLog(@"percentage : %f", percentage);
        
    } while( percentage <= 0.2 );

    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 Assets are downloaded and ready for playing.
 
 
 Native SDK
 - Returns YES.
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops the ad expiry timer.
 2. Hits the Filled tracker received in the playlist.
 3. Plays the ad from cache.
 4. Notifies YuMeAdEventAdPlaying event.
 5. Hits the impression trackers received in the playlist, at appropriate times.
 6. Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event, on ad completion.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 */
- (void)test_SHOW_AD_010 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    NSError *error = nil; 
[self presentShowAd:&error];
    if (error) {
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:error] description]);
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:error] description]]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event received.");
    
    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo3];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event received.");
    
    [self dismissShowAd];
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 
 Assets are downloaded and ready for playing.
 
 Native SDK
 - Returns YES.
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops the ad expiry timer.
 2. Hits the Filled tracker received in the playlist.
 3. Plays the ad from cache.
 4. Notifies YuMeAdEventAdPlaying event.
 5. Hits the impression trackers received in the playlist, at appropriate times.
 6. On ad completion,
 6a) Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event.
 6b) auto prefetches a new playlist from the server and handles the new playlist response.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 */
- (void)test_SHOW_AD_011 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    YuMeAdParams *pAdparams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (!pAdparams.bEnableAutoPrefetch) {
        pError = nil;
        params.bEnableAutoPrefetch = YES;
        params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    }
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    NSError *error = nil; 
[self presentShowAd:&error];
    if (error) {
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:error] description]);
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:error] description]]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event received.");
    
    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo3];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event received.");
    
    [self dismissShowAd];

    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady]], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo4];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay / YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 
 No unplayed ad exists in cache (the ad fetched previously is played already).
 
 Native SDK
 - Returns NO with error message “yumePluginShowAd(): No Prefetched Ad Present.”
 
 JS SDK
 1. Hits the Generic Empty tracker.
 (e.g)  http://shadow01.yumenetworks.com/static_register_unfilled_request.gif?sdk_version=3.2.4.6&domain=704oIaHzpGu&make=APPLE&width=320&height=460&slot_type=PREROLL&model=iPhone Simulator 4.2
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 
 */
- (void)test_SHOW_AD_012 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    YuMeAdParams *pAdparams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pAdparams.bEnableAutoPrefetch) {
        pError = nil;
        params.bEnableAutoPrefetch = NO;
        params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    }
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    NSError *error = nil; 
[self presentShowAd:&error];
    if (error) {
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:error] description]);
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:error] description]]);
    }

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event received.");
    
    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo3];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event received.");
    
    [self dismissShowAd];
    
    GHRunForInterval(2);
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON (and)
 Prefetch-On-Ad-Expiry (Ad Config): ON
 SDK Mode: PREFETCH
 
 Ad in cache is expired.
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): No Prefetched Ad Present.".
 
 JS SDK
 1. Hits the Unfilled tracker received in the playlist.
 2. Makes a new prefetch request to the server.
 3. Handles the response received.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 */
- (void)test_SHOW_AD_013 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(120);
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady]], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo4];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay / YuMeAdEventAdNotReady event received.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF (and / or)
 Prefetch-On-Ad-Expiry (Ad Config): OFF
 SDK Mode: PREFETCH
 
 
 Ad in cache is expired.
 
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): No Prefetched Ad Present.".
 
 JS SDK
 1. Hits the Unfilled tracker received in the playlist.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 
 */
- (void)test_SHOW_AD_014 {
    NSString *str = @"Please do it manually.";
    GHTestLog(@"Result : %@", str);
    GHFail(str);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 
 Prefetched ad present but the downloads are aborted.
 
 Native SDK
 - Returns YES.
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Hits the Filled tracker received in the playlist.
 2. Plays the ad from network (uses cached assets, if available) .
 3. Notifies YuMeAdEventAdPlaying event.
 4. Hits the impression trackers received in the playlist, at appropriate times.
 5. On ad completion,
 5a) Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 */
- (void)test_SHOW_AD_015 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    GHAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *pAdparams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pAdparams.bEnableAutoPrefetch) {
        pError = nil;
        params.bEnableAutoPrefetch = NO;
        params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    }
    
    float percentage = 0.0f;
    do {
        GHRunForInterval(0.2);
        pError = nil;
        percentage = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
        
        NSLog(@"percentage : %f", percentage);
        
    } while( percentage <= 0.2 );
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkAbortDownload:&pError], @"yumeSdkAbortDownload fails");
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
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");

    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 
 Prefetched ad present but the downloads are aborted.
 
 Native SDK
 - Returns YES.
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Hits the Filled tracker received in the playlist.
 2. Plays the ad from network (uses cached assets, if available) .
 3. Notifies YuMeAdEventAdPlaying event.
 4. Hits the impression trackers received in the playlist, at appropriate times.
 5. On ad completion,
 5a) Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event.
 5b) auto prefetches a new playlist from the server and handles the new playlist response.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 */
- (void)test_SHOW_AD_016 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    YuMeAdParams *pAdparams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (!pAdparams.bEnableAutoPrefetch) {
        pError = nil;
        params.bEnableAutoPrefetch = YES;
        params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    }
    
    float percentage = 0.0f;
    do {
        GHRunForInterval(0.2);
        pError = nil;
        percentage = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
        
        NSLog(@"percentage : %f", percentage);
        
    } while( percentage <= 0.2 );
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkAbortDownload:&pError], @"yumeSdkAbortDownload fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHRunForInterval(1);
    
    NSError *error = nil; 
[self presentShowAd:&error];
    if (error) {
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:error] description]);
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:error] description]]);
    }

    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(2);
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    
    GHRunForInterval(1);
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady]], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo4];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay / YuMeAdEventAdNotReady event received.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Prefetched ad present but the downloads are paused.
 
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): No Prefetched Ad Present."
 
 JS SDK
 1. Hits the Filled tracker received in the playlist.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 
 */
- (void)test_SHOW_AD_017 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }

    GHRunForInterval(1);
    
    
    float percentage = 0.0f;
    do {
        GHRunForInterval(0.2);
        pError = nil;
        percentage = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
        
        NSLog(@"percentage : %f", percentage);
        
    } while( percentage <= 0.2 );
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHRunForInterval(1);
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;

    GHRunForInterval(2);

}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 Prefetched ad present but asset downloading failed.
 
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): No Prefetched Ad Present."
 
 JS SDK
 1. Hits the Filled tracker received in the playlist.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 
 */
- (void)test_SHOW_AD_018 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_404_URL;
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(2);
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    GHRunForInterval(1);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 ShowAd called in the following condition:
 a. Previous InitAd request returned a valid filled response but none of the required assets were present.
 
 Native SDK
 - Returns NO with error message: "yumeSdkShowAd(): No Prefetched Ad Present."
 
 JS SDK
 1. Hits the Filled tracker received in the playlist.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 */
- (void)test_SHOW_AD_019 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_MISSING_ASSETS_URL;
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(2);
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    GHRunForInterval(1);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 ShowAd called in any of the following conditions:
 a. Previous InitAd request timed out.
 b. Previous InitAd request returned a non-200 OK response.
 c. Previous InitAd request returned an invalid empty response.
 d. Previous InitAd request returned an invalid filled response.
 
 Native SDK
 - Returns NO with error message “yumePluginShowAd(): No Prefetched Ad Present.”
 
 JS SDK
 1. Hits the Generic Empty tracker.
 (e.g)  http://shadow01.yumenetworks.com/static_register_unfilled_request.gif?sdk_version=3.2.4.6&domain=704oIaHzpGu&make=APPLE&width=320&height=460&slot_type=PREROLL&model=iPhone Simulator 4.2
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 
 */
- (void)test_SHOW_AD_020 {
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = EMPTY_VALID_URL;
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
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
    [self performSelectorInBackground:@selector(showAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(2);
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertFalse([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkShowAd(): No Prefetched Ad Present.", @"yumeSdkShowAd(): No Prefetched Ad Present.");
        GHTestLog(@"Result : %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    GHRunForInterval(1);
    
    NSString *testString = @"static_register_unfilled_request.gif?";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        GHTestLog(@"Result: Hits the Unfilled tracker received in the playlist. %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }

}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Video playhead doesn't move (progress) for the video time interval specified during initialization (before ad play start (or) after ad play start).
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Ad Play Times out.
 2. Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackTimedOut) event.
 3. If auto-prefetching enabled, auto prefetches a new playlist from the server and handles the new playlist response.
 */
- (void)test_SHOW_AD_021 {
    NSString *str = @"Please do it manually.";
    GHTestLog(@"Result : %@", str);
    GHFail(str);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Asset Downloads operation in progress, but at least an ad is readily available for playing (Ad Coverage case).
 
 
 Native SDK
 - Returns YES.
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Hits the Filled tracker received in the playlist for the currently playing ad.
 2. Plays the cached ad.
 3. Notifies YuMeAdEventAdPlaying event, if not notified already.
 4. Hits the impression trackers received in the playlist for the currently playing ad, at appropriate times.
 5. One ad completion, continues to play the next valid ad until all ads are played.
 6. On all ads' completion,
 6a) Notifies YuMeAdEventAdCompleted (YuMeAdStatusPlaybackSuccess) event.
 6b) If auto-prefetching enabled, auto prefetches a new playlist from the server and handles the new playlist response.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop) (or) calls this API after calling isAdAvailable().
 
 */
- (void)test_SHOW_AD_022 {
    NSString *str = @"Please do it manually.";
    GHTestLog(@"Result : %@", str);
    GHFail(str);
}

@end
