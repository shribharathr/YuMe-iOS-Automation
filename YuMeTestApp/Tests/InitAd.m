//
//  InitAd.m
//
#import <GHUnit/GHUnit.h>
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

@interface InitAd : GHAsyncTestCase

@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;

@end

@implementation InitAd
@synthesize adDisplayViewController;
@synthesize presentedAdViewController;


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
        GHRunForInterval(1);
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    GHRunForInterval(1);
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)initAdEventListener:(NSArray *)userInfo {
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

- (void)presentShowAd {
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    [adDisplayViewController presentViewController:presentedAdViewController animated:NO completion:^() {
        NSLog(@"Presented Roll View Controller in Application: %@", presentedAdViewController);
        NSError *pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:presentedAdViewController errorInfo:&pError], @"");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
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
 SDK State: Not Initialized
 Called when SDK is not initialized.
 
 Native SDK
 - Returns error message: "yumeSdkInitAd(): YuMe SDK is not Initialized."
 
 */
- (void)test_INIT_AD_001 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    GHAssertFalse([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkInitAd(): YuMe SDK is not Initialized.", @"yumeSdkInitAd(): YuMe SDK is not Initialized.");
        GHTestLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 
 Request times out / No network connection.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 - Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestTimedOut)
 
 */
- (void)test_INIT_AD_002 {
    NSString *str = @"Please do it manually.";
    GHTestLog(@"Result : %@", str);
    GHFail(str);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 Request times out / No network connection.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Starts auto prefetch timer.
 1a) attempts auto-prefetching in 2, 4, 8, 16, 32, 64, 128, 128, 128... seconds interval, until a response is received.
 1b) Notifies YuMeAdEventAdReadyToPlay (or) YuMeAdEventAdNotReady (with appropriate Ad Status) events, as appropriate, on receiving a success/non-success response from the server.
 */
- (void)test_INIT_AD_003 {
    NSString *str = @"Please do it manually.";
    GHTestLog(@"Result : %@", str);
    GHFail(str);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 
 Non-200 OK response is received.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed).
 */
- (void)test_INIT_AD_004 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = @"http://shadow02.yumenetworks.com";
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 Non-200 OK response is received.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed).
 2. Starts auto prefetch timer.
 2a) attempts auto-prefetching in 2, 4, 8, 16, 32, 64, 128, 128, 128... seconds interval, until a 200 OK response is received.
 
 */
- (void)test_INIT_AD_005 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = @"http://shadow02.yumenetworks.com";
    params.bEnableCaching = YES;
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
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(20);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is EMPTY and Invalid.
 
 NOTE: An empty playlist is invalid, if
 <unfilled> tracker is missing (or) empty.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed).
 
 */
- (void)test_INIT_AD_006 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = EMPTY_INVALID_URL;
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is EMPTY and Invalid.
 
 NOTE: An empty playlist is invalid, if
 <unfilled> tracker is missing (or) empty.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed).
 2. Starts auto prefetch timer.
 2a) attempts auto-prefetching in 2, 4, 8, 16, 32, 64, 128, 128, 128... seconds interval, until a 200 OK response is received.
 
 */
- (void)test_INIT_AD_007 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = EMPTY_INVALID_URL;
    params.bEnableCaching = YES;
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
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(20);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is FILLED and Invalid.
 
 NOTE: A filled playlist is invalid, if,
 a. <filled> tracker is missing (or) empty. (OR)
 b. <unfilled> tracker is missing (or) empty.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed).
 
 */
- (void)test_INIT_AD_008 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_INVALID_URL;
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is FILLED and Invalid.
 
 NOTE: A filled playlist is invalid, if,
 a. <filled> tracker is missing (or) empty. (OR)
 b. <unfilled> tracker is missing (or) empty.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed).
 2. Starts auto prefetch timer.
 2a) attempts auto-prefetching in 2, 4, 8, 16, 32, 64, 128, 128, 128... seconds interval, until a 200 OK response is received.
 
 */
- (void)test_INIT_AD_009 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_INVALID_URL;
    params.bEnableCaching = YES;
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
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(20);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is EMPTY and Valid.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusEmptyAdInCache).
 2. Starts Prefetch Request Callback Timer.
 2a) makes a new prefetch request to server, when prefetch request callback timer expires.
 
 */
- (void)test_INIT_AD_010 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    params.pAdditionalParams = @"";
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(60);
    
    GHTestLog(@"Starts Prefetch Request Callback Timer.");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is EMPTY and Valid.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops Auto Prefetch timer, if running.
 2. Notifies YuMeAdEventAdNotReady (YuMeAdStatusEmptyAdInCache).
 3. Starts Prefetch Request Callback Timer.
 3a) makes a new prefetch request to server, when prefetch request callback timer expires.
 
 */
- (void)test_INIT_AD_011 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(60);
    
    GHTestLog(@"Starts Prefetch Request Callback Timer.");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is FILLED but missing all of the required assets.
 NOTE:
 a. For video, only mp4 creatives would be considered.
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed).
 2. Prints the placementId_adId of this playlist in logs.
 
 */
- (void)test_INIT_AD_012 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is FILLED but missing all of the required assets.
 NOTE:
 a. For video, only mp4 creatives would be considered.
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops Auto Prefetch timer, if running.
 2. Notifies YuMeAdEventAdNotReady (YuMeAdStatusRequestFailed).
 3. Starts auto prefetch timer.
 3a) Prints the placementId_adId of this playlist in logs.
 3b) attempts auto-prefetching in 2, 4, 8, 16, 32, 64, 128, 128, 128... seconds interval, until a valid playlist is received.
 
 */
- (void)test_INIT_AD_013 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(20);
}

/**
 SDK State: Initialized
 Caching: OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 - 200 OK response is received.
 - Playlist is FILLED and contains at least one of the required creatives.
 NOTE:
 a. For video, only mp4 creatives would be considered.
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 c. No 404 mp4 / logo creatives should be present in the playlist.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Notifies YuMeAdEventAdReadyToPlay.
 3. Starts ad expiry timer.
 
 */
- (void)test_INIT_AD_014 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_URL;
    params.bEnableCaching = NO;
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
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Storage Size: 0.0MB (or)
 (Storage Mode = EXTERNAL & WRITE_EXTERNAL_STORAGE permission not set) (Android specific).
 
 - 200 OK response is received.
 - Playlist is FILLED and contains at least one of the required creatives.
 NOTE:
 a. For video, only mp4 creatives would be considered.
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 c. No 404 mp4 / logo creatives should be present in the playlist.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Notifies YuMeAdEventAdReadyToPlay.
 3. Starts ad expiry timer.
 */

- (void)test_INIT_AD_015 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_URL;
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = YES;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 0.0f;
    params.pAdditionalParams = @"";
    
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
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Storage Size: 10.0MB
 
 - 200 OK response is received.
 - Playlist is FILLED and contains at least one (or) all of the required creatives.
 NOTE:
 a. For video, only mp4 creatives would be considered
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 c. No 404 mp4 / logo creatives should be present in the playlist.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Identifies the assets to be downloaded.
 3. Fetches the size of the assets to be downloaded using HEAD request (HEAD request to be issued only if the 'size' attribute is missing (or) contains a value <= 0 for an asset).
 4. Calculates the space requirements for high bitrate, checks if space is available for high bitrate, downloads high bitrate assets, if available space is sufficient. If space not sufficient, then tries with medium and low bitrate assets in the specified order.
 NOTE: If all the high, medium & low bitrate mp4s are not present, then the 1st available mp4 would be considered.
 5. Sets the download status to IN_PROGRESS.
 6. Once all the assets are downloaded,
 6a) Sets the download status to NOT_IN_PROGRESS.
 6b) Notifies YuMeAdEventAdReadyToPlay.
 6c) Starts ad expiry timer.
 
 */
- (void)test_INIT_AD_016 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = YES;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    /*
     pError = nil;
     params.pAdServerUrl = FILLED_URL;
     params.bEnableCaching = YES;
     params.bEnableAutoPrefetch = YES;
     params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
     params.storageSize = 10.0f;
     
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
     */
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Storage Size: 0.2MB
 
 - 200 OK response is received.
 - Playlist is FILLED and contains at least one (or) all of the required creatives.
 - Space available not sufficient for any of high, medium or low bitrate assets.
 NOTE:
 a. For video, only mp4 creatives would be considered
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 c. No 404 mp4 / logo creatives should be present in the playlist.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Identifies the assets to be downloaded.
 3. Fetches the size of the assets to be downloaded using HEAD request (HEAD request to be issued only if the 'size' attribute is missing (or) contains a value <= 0 for an asset).
 4. Calculates the space requirements for high, medium, low bitrate assets.
 5. Notifies YuMeAdEventAdReadyToPlay.
 6. Starts ad expiry timer.
 
 */
- (void)test_INIT_AD_017 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = YES;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 0.2f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    /*
     pError = nil;
     params.pAdServerUrl = FILLED_URL;
     params.bEnableCaching = YES;
     params.bEnableAutoPrefetch = YES;
     params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
     params.storageSize = 10.0f;
     
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
     */
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 Storage Size: 10.0MB
 
 - 200 OK response is received.
 - Playlist is FILLED and contains at least one (or) all of the required creatives.
 - Fetching size using HEAD Request / Asset download fails (timeout (or) 404 creatives). (OR)
 - Network cable is unplugged when asset downloads is in progress.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Identifies the assets to be downloaded.
 3. Fetches the size of the assets to be downloaded using HEAD request (HEAD request to be issued only if the 'size' attribute is missing (or) contains a value <= 0 for an asset).
 4. Calculates the space requirements for high, medium, low bitrate assets and starts downloading.
 5. Sets the download status to IN_PROGRESS.
 6. Retries 'n' number of times at every 'x' interval of time.
 6a) 'n' = value of <creative_retry_attempts> in the playlist.
 6b) 'x' = value of <creative_retry_interval> in the playlist.
 7. After retry attempts, starts auto prefetch timer.
 7a) Sets the download status to NOT_IN_PROGRESS.
 7b) Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachingFailed).
 7c) attempts auto-prefetching in 2, 4, 8, 16, 32, 64, 128, 128, 128... seconds interval, until a valid playlist is received.
 */
- (void)test_INIT_AD_018 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = YES;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    params.bEnableAutoPrefetch = YES;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(20);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 Storage Size: 10.0MB
 
 - 200 OK response is received.
 - Playlist is FILLED and contains at least one (or) all of the required creatives.
 - Fetching size using HEAD Request / Asset download fails (timeout (or) 404 creatives). (OR)
 - Network cable is unplugged when asset downloads is in progress.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Identifies the assets to be downloaded.
 3. Fetches the size of the assets to be downloaded using HEAD request (HEAD request to be issued only if the 'size' attribute is missing (or) contains a value <= 0 for an asset).
 4. Calculates the space requirements for high, medium, low bitrate assets and starts downloading.
 5. Sets the download status to IN_PROGRESS.
 6. Retries 'n' number of times at every 'x' interval of time.
 6a) 'n' = value of <creative_retry_attempts> in the playlist.
 6b) 'x' = value of <creative_retry_interval> in the playlist.
 7. After retry attempts,
 7a) Sets the download status to NOT_IN_PROGRESS.
 7b) Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachingFailed).
 
 */
- (void)test_INIT_AD_019 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Storage Size: 2.0MB
 
 - 200 OK response is received.
 - Playlist is FILLED and contains at least one (or) all of the required creatives.
 - Space available not sufficient – old assets not associated with the current playlist deleted for reclaiming space for new assets.
 
 NOTE
 a. No 404 mp4 / logo creatives should be present in the playlist.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Identifies the assets to be downloaded.
 3. Fetches the size of the assets to be downloaded using HEAD request (HEAD request to be issued only if the 'size' attribute is missing (or) contains a value <= 0 for an asset).
 4. Calculates the space requirements for high, medium, low bitrate assets, reclaims space for new assets by deleting old assets (FIFO logic) not associated with current playlist. If space available sufficient, starts downloading assets.
 5. Sets the download status to IN_PROGRESS.
 6. Once all the assets are downloaded
 6a) Sets the download status to NOT_IN_PROGRESS.
 6b) Notifies YuMeAdEventAdReadyToPlay.
 6c) Starts ad expiry timer.
 
 */
- (void)test_INIT_AD_020 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 2.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    /*
     pError = nil;
     params.pAdServerUrl = FILLED_URL;
     params.bEnableCaching = YES;
     params.bEnableAutoPrefetch = NO;
     params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
     params.storageSize = 2.0f;
     
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
     */
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 InitAd called without any pattern change, when a a filled prefetched ad is already available.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdReadyToPlay.
 2. Ad expiry timer continues to run, if running.
 3. No new playlist request made to the server.
 4. Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 */
- (void)test_INIT_AD_021 {
    
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];
    
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    GHRunForInterval(2);
    
    NSString *testString = @"New Init Ad Request IGNORED as it is same as the previous request.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 InitAd called with pattern change (different ad block type (or) qs params changed), when a filled prefetched ad is already available.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops the Ad Expiry Timer.
 2. Makes a new prefetch request to the server.
 3. Handles the response received.
 
 */
- (void)test_INIT_AD_022 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
    
    pError = nil;
    params.pAdditionalParams = @"a=b";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    params = nil;
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd API called again");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 InitAd called without any pattern change, when previous InitAd's download operation (of the 1st ad in the playlist) is in progress.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachingInProgress) immediately.
 2. The first InitAd's download operation continues.
 3. Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 4. Once the previous InitAd's assets are downloaded,
 4a) Sets the download status to NOT_IN_PROGRESS.
 4b) Notifies YuMeAdEventAdReadyToPlay.
 4c) Starts ad expiry timer.
 
 */
- (void)test_INIT_AD_023 {
    
    [YuMeUnitTestUtils createConsoleLogFile:NSStringFromSelector(_cmd)];
    
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd API called again");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    NSString *testString = @"New Init Ad Request IGNORED as it is same as the previous request.";
    if ([[YuMeUnitTestUtils readConsoleLogFile:NSStringFromSelector(_cmd)] rangeOfString:testString].location != NSNotFound) {
        GHTestLog(@"Result: %@", testString);
    } else {
        GHFail(@"Result : Failed to receive %@", testString);
    }
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 InitAd called with pattern change (different ad block type (or) QS params changed), when previous InitAd's download operation is in progress.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Aborts the ongoing downloads.
 2. Makes a new prefetch request to the server.
 3. Handles the response received.
 
 */
- (void)test_INIT_AD_024 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.bEnableCaching = YES;
    params.bEnableAutoPrefetch = NO;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.storageSize = 10.0f;
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    
    
    pError = nil;
    params.pAdditionalParams = @"c=d";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    params = nil;
    
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd API called again");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 InitAd called when Streaming Ad Play is in progress.
 
 
 JS SDK
 - Returns error message: "yumeSdkInitAd(): Previous STREAMING Ad Play in Progress."
 - Notifies the following error message to Native SDK:
 "Operation not allowed as SDK is Initialized in STREAMING mode."
 
 - Init Ad Call ignored.
 - Streaming Ad play continues.
 */
- (void)test_INIT_AD_025 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"YuMeAdEventInitSuccess event received.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.pDomainId = @"211EsvNSRHO";
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    params = nil;
    
    GHRunForInterval(2);
    
    pError = nil;
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    [self presentShowAd];
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@" YuMeAdEventAdReadyToPlay event.");
    
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        GHAssertEqualStrings(str, @"yumeSdkInitAd(): Previous STREAMING Ad Play in Progress.", @"yumeSdkInitAd(): Previous STREAMING Ad Play in Progress.");
        GHTestLog(@"Result: %@", str);
    }
    GHTestLog(@"yumeSdkInitAd API called");
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo4];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event received.");
    
    [self dismissShowAd];
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 InitAd called when Prefetched Ad Play is in progress.
 
 
 JS SDK
 - Returns error message: "yumeSdkInitAd(): Previous PREFETCED Ad Play in Progress."
 
 - Prefetched Ad play continues.
 
 */
- (void)test_INIT_AD_026 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    params.pDomainId = @"211EsvNSRHO";
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
    
#if pYuMeMPlayerController
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                   videoPlayerDelegate:pYuMeMPlayerController
                             errorInfo:&pError], @"Initialization Successful.");
    
#else
    GHAssertTrue([pYuMeSDK yumeSdkInit:params
                           appDelegate:pYuMeInterface
                             errorInfo:&pError], @"Initialization Successful.");
    
#endif
    
    [self prepare];
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"YuMeAdEventInitSuccess event received.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event.");

    [self presentShowAd];

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event.");

    GHRunForInterval(2);
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        NSString *str = [[YuMeUnitTestUtils getErrDesc:pError] description];
        GHAssertEqualStrings(str, @"yumeSdkInitAd(): Previous PREFETCED Ad Play in Progress.", @"yumeSdkInitAd(): Previous PREFETCED Ad Play in Progress.");
        GHTestLog(@"Result: %@", str);
    }
    GHTestLog(@"yumeSdkInitAd API called");
    
    GHRunForInterval(2);

    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo4];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event received.");
    
    [self dismissShowAd];

}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 InitAd called (with (or) without pattern change) in any of the following conditions:
 a. Previous InitAd request timed out.
 b. Previous InitAd request returned a non-200 OK response.
 c. Previous InitAd request returned an invalid empty response.
 d. Previous InitAd request returned an invalid filled response.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Makes a new prefetch request to the server.
 2. Handles the response received.

*/
- (void)test_INIT_AD_027 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    params.pAdServerUrl = FILLED_INVALID_URL;
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHTestLog(@"Invalid filled response received.");
    
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd called again");

    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 InitAd called (with (or) without pattern change) in the following condition:
 a. Previous InitAd request returned a valid filled response but none of the required assets were present.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Makes a new prefetch request to the server.
 2. Handles the response received.
 
 */
- (void)test_INIT_AD_028 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 InitAd called without any pattern change, when an empty prefetched ad is already available.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusEmptyAdInCache) immediately.
 2. The Prefetch Request Callback Timer continues to run.
 
 */
- (void)test_INIT_AD_029 {
    
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    params.pAdditionalParams = @"";
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHTestLog(@"Empty prefetched ad is already available.");
    
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd called again");

    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");

    GHRunForInterval(2);

}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 InitAd called with pattern change (different ad block type (or) QS params changed), when an empty prefetched ad is already available.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Stops the Prefetch Request Callback Timer.
 2. Makes a new prefetch request to the server.
 3. Handles the response received.

 */
- (void)test_INIT_AD_030 {
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo];
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
    params.pAdditionalParams = @"";
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
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady event received.");
    
    GHTestLog(@"Empty prefetched ad is already available.");
    
    pError = nil;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(2);
    
    pError = nil;
    GHTestLog(@"Modify AdParams: \n%@", [pYuMeSDK yumeSdkGetAdParams:&pError]);
    
    GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"yumeSdkInitAd called again");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(initAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdReadyToPlay event received.");
    
    GHRunForInterval(2);
    
}

#if 0
/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 InitAd called (with (or) without pattern change) in the following condition:
 a. Previous InitAd request returned a valid filled response but download attempts failed due to 404 creative.
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Makes a new prefetch request to the server.
 2. Handles the response received.

 */
- (void)test_INIT_AD_031 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 InitAd called with pattern change (different ad block type (or) QS params changed), when the previous InitAd's downloads are paused.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Makes a new prefetch request to the server.
 2. Handles the response received.
 
 */
- (void)test_INIT_AD_032 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 InitAd called without pattern change, when the previous InitAd's downloads (of the 1st ad in the playlist) are paused.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachingInProgress) immediately.
 2. The first InitAd's download operations remains paused.
 3. Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 
 */
- (void)test_INIT_AD_033 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 InitAd called (with (or) without pattern change), when the previous InitAd's downloads are aborted.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Makes a new prefetch request to the server.
 2. Handles the response received.
 
 */
- (void)test_INIT_AD_034 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 Media file URL of the following format is received - the asset creative url contains "?" followed by some QS params after the file name:
 http://ads.eyeviewads.com/1007520203384/36a53f27-d9b1-49b5-8a48-0a2bb8de0ba3.mp4?madid=476&adid=20203384&trid=2481&origintrid=2484&uip=203.129.222.154&tyld=GRBG&uid=aa11dc0812a4eb34&madhashid=fcaf7c28&did=10075&rfv=7&asv=1843&adp=VAST2
 
 Native SDK
 The asset should get cached successfully by taking the appropriate file name.
 
 */
- (void)test_INIT_AD_035 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 
 InitAd called with pattern change, when auto prefetch is in progress.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 The ongoing auto prefetch operation should be stopped and the new initAd() should be honored.
 
 */
- (void)test_INIT_AD_036 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 InitAd called without pattern change, when auto prefetch is in progress.
 
 JS SDK
 - Returns error message: "yumeSdkInitAd(): Init Ad Request IGNORED as a similar request is in progress."
 - The ongoing auto-prefetch should continue.
 */
- (void)test_INIT_AD_037 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 Valid Playlist received with video url that gets redirected.
 
 
 Native SDK
 The cached video asset should get stored using the file name received in the final redirected url.
 */
- (void)test_INIT_AD_038 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 Valid Playlist received with image url that gets redirected.
 
 
 Native SDK
 The cached image asset should get stored using the file name received in the final redirected url.

 */
- (void)test_INIT_AD_039 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}


/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 Valid Playlist received with overlay url that gets redirected.
 
 
 Native SDK
 The cached overlay asset should get stored using the file name received in the final redirected url.

 */
- (void)test_INIT_AD_040 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON / OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 Prefetch-On-Ad-Expiry (Ad Config): ON
 Cached ad expires before showAd() is called.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachedAdExpired) event.
 2. Hits the first party error tracker by appending “&reason=51”.
 3. Prints the log “Prefetching a new ad on Ad Expiry...”.
 4. Makes a new prefetch request to the server.
 5. Handles the response received.
 
 */
- (void)test_INIT_AD_041 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}


/**
 SDK State: Initialized
 Caching: ON  / OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 Prefetch-On-Ad-Expiry (Ad Config): OFF
 Cached ad expires before showAd() is called.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachedAdExpired) event.
 2. Hits the first party error tracker by appending “&reason=51”.
 3. Prints the log “Not Prefetching a new ad on Ad Expiry.”.
 
 Doesn't make a new initAd() request automatically.
 
 */
- (void)test_INIT_AD_042 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON  / OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 Prefetch-On-Ad-Expiry (Ad Config): ON
 Cached ad expires before showAd() is called.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachedAdExpired) event.
 2. Hits the first party error tracker by appending “&reason=51”.
 3. Prints the log “Not Prefetching a new ad on Ad Expiry.”.
 
 Doesn't make a new initAd() request automatically.
 
 */
- (void)test_INIT_AD_043 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON  / OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 Prefetch-On-Ad-Expiry (Ad Config): OFF
 Cached ad expires before showAd() is called.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachedAdExpired) event.
 2. Hits the first party error tracker by appending “&reason=51”.
 3. Prints the log “Not Prefetching a new ad on Ad Expiry.”.
 
 Doesn't make a new initAd() request automatically.

 */
- (void)test_INIT_AD_044 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON  / OFF
 Auto-Prefetch: ON
 SDK Mode: PREFETCH
 
 Ad Events gets notified for Auto-Prefetch operations.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 Appropriate ad events that gets notified for InitAd() operations, should get notified for Auto-Prefetch operations as well.
 
 NOTE: If auto-prefetch goes on in 2,4,8, 16... seconds cycle, then ad events should be notified ONLY if the Ad Event and/or the associated YuMeAdStatus is different from that of the previously notified event.
 
 */
- (void)test_INIT_AD_045 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Not Initialized
 Caching: ON  / OFF
 Auto-Prefetch: ON / OFF
 
 
 First ad Prefetched automatically, immediately after successful Initialization in PREFETCH mode.
 
 
 JS SDK
 - As soon Initialization is successfully completed in PREFETCH mode, the first prefetched ad should be fetched automatically.

 */
- (void)test_INIT_AD_046 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON  / OFF
 Auto-Prefetch: ON / OFF
 SDK Mode: PREFETCH
 
 Sending of Excluded ads list in JSON body of the next prefetch playlist request.
 
 
 JS SDK
 - Whenever an invalid playlist is received from the server (unsupported formats, missing tags etc.,), the ad_id of the particular ad should be maintained and the same list should be notified to the server using “exclude_ads” value in the JSON request, when the next playlist request is being sent out.
 
 - If any invalid ad is later found to be valid, it should be removed from the list of ads to be excluded.
 
 */
- (void)test_INIT_AD_047 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: STREAMING
 Called when SDK is initialized in STREAMING mode.
 
 
 JS SDK
 - Notifies the following error message to Native SDK:
 "Operation not allowed as SDK is Initialized in STREAMING mode."
 
 - Init Ad Call ignored.

 */
- (void)test_INIT_AD_048 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF
 SDK Mode: PREFETCH
 InitAd called without pattern change, when previous initAd response is not received.
 
 
 JS SDK
 - Returns error message: "yumeSdkInitAd(): Init Ad Request IGNORED as a similar request is in progress."
 - The previous InitAd request should continue.
 */
- (void)test_INIT_AD_049 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 InitAd called without any pattern change, when previous InitAd's download operation (of the 2nd ad so on) is in progress, but assets of at least one ad of the same playlist are cached already (Ad Coverage case).
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Notifies YuMeAdEventAdReadyToPlay immediately.
 2. The first InitAd's download operation continues.
 3. Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 4. Once the previous InitAd's assets are downloaded,
 4a) Sets the download status to NOT_IN_PROGRESS.
 4b) Starts ad expiry timer.
 */
- (void)test_INIT_AD_050 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 InitAd called without pattern change, when the previous InitAd's downloads (of the 2nd ad so on) are paused, but assets of at least one ad of the same playlist are cached already (Ad Coverage case).
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdReadyToPlay immediately.
 2. The first InitAd's download operations remains paused.
 3. Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 */
- (void)test_INIT_AD_051 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 
 InitAd called without any pattern change, when a filled prefetched ad(s) is already available for playing (i.e., all the ads in the playlist are cached already) (Ad Coverage case).
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 
 JS SDK
 1. Notifies YuMeAdEventAdReadyToPlay.
 2. Ad expiry timer continues to run, if running.
 3. No new playlist request made to the server.
 4. Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 
 */
- (void)test_INIT_AD_052 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: OFF
 SDK Mode: PREFETCH
 Auto-Prefetch: ON/OFF
 InitAd called without any pattern change when the previous InitAd's response is just received and processing in progress.
 
 
 JS SDK
 1. Notifies YuMeAdEventAdReadyToPlay immediately.
 - Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 */
- (void)test_INIT_AD_053 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 SDK Mode: PREFETCH
 Auto-Prefetch: ON/OFF
 InitAd called without any pattern change when the previous InitAd's response is just received and processing in progress.
 
 
 JS SDK
 1. Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachingInProgress) immediately.
 - Prints the log “New Init Ad Request IGNORED as it is same as the previous request.”.
 
 */
- (void)test_INIT_AD_054 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Storage Size: 30.0MB
 
 - 200 OK response is received.
 - Playlist is FILLED and an Ad Coverage Playlist.
 - All the ads in the playlist contains at least one (or) all of the required creatives.
 NOTE:
 a. For video, only mp4 creatives would be considered
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 c. No 404 mp4 / logo creatives should be present in the playlist.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Identifies the assets to be downloaded for the 1st ad.
 3. Fetches the size of the 1st ad's assets to be downloaded using HEAD request (HEAD request to be issued only if the 'size' attribute is missing (or) contains a value <= 0 for an asset).
 4. Calculates the space requirements for high bitrate, checks if space is available for high bitrate, downloads high bitrate assets, if available space is sufficient. If space not sufficient, then tries with medium and low bitrate assets in the specified order.
 NOTE: If all the high, medium & low bitrate mp4s are not present, then the 1st available mp4 would be considered.
 5. Sets the download status to IN_PROGRESS.
 6. Once all the assets of current ad are downloaded,
 6a) Notifies YuMeAdEventAdReadyToPlay.
 6b) Starts with the asset downloading of next ad in the playlist.
 7. Once the assets of all ads in the playlist are downloaded,
 7a) Sets the download status to NOT_IN_PROGRESS.
 7c) Starts ad expiry timer.
 
 */
- (void)test_INIT_AD_055 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Storage Size: 30.0MB
 
 - 200 OK response is received.
 - Playlist is FILLED and an Ad Coverage Playlist.
 - Some ads in the playlist contains at least one (or) all of the required creatives (and) Some ads contains 404 creatives.
 NOTE:
 a. For video, only mp4 creatives would be considered
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 c. No 404 mp4 / logo creatives should be present in the playlist.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Identifies the assets to be downloaded for the 1st ad.
 3. Fetches the size of the 1st ad's assets to be downloaded using HEAD request (HEAD request to be issued only if the 'size' attribute is missing (or) contains a value <= 0 for an asset).
 4. Calculates the space requirements for high bitrate, checks if space is available for high bitrate, downloads high bitrate assets, if available space is sufficient. If space not sufficient, then tries with medium and low bitrate assets in the specified order.
 NOTE: If all the high, medium & low bitrate mp4s are not present, then the 1st available mp4 would be considered.
 5. Sets the download status to IN_PROGRESS.
 6. Once all the assets of current ad are downloaded (or) fails,
 6a) Notifies YuMeAdEventAdReadyToPlay, if downloads succeeded.
 6b) Starts with the asset downloading of next ad in the playlist.
 7. Once caching of assets of all ads in the playlist are attempted,
 7a) Sets the download status to NOT_IN_PROGRESS.
 7c) Starts ad expiry timer.
 */
- (void)test_INIT_AD_056 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

/**
 SDK State: Initialized
 Caching: ON
 Auto-Prefetch: ON/OFF
 SDK Mode: PREFETCH
 Storage Size: 30.0MB
 
 - 200 OK response is received.
 - Playlist is FILLED and an Ad Coverage Playlist.
 - All ads contains 404 creatives.
 NOTE:
 a. For video, only mp4 creatives would be considered
 b. For slate based ads, only 1st slate would be considered, when checking for the presence of required assets.
 c. No 404 mp4 / logo creatives should be present in the playlist.
 
 
 Native SDK
 - Notifies the ad events from JS SDK to application.
 - Handles the asset operations like GetAssetSize, CheckSpaceAvailability and GetAsset and local caching.
 
 JS SDK
 1. Resets auto prefetch time interval to its default value.
 2. Identifies the assets to be downloaded for the 1st ad.
 3. Fetches the size of the 1st ad's assets to be downloaded using HEAD request (HEAD request to be issued only if the 'size' attribute is missing (or) contains a value <= 0 for an asset).
 4. Calculates the space requirements for high bitrate, checks if space is available for high bitrate, downloads high bitrate assets, if available space is sufficient. If space not sufficient, then tries with medium and low bitrate assets in the specified order.
 NOTE: If all the high, medium & low bitrate mp4s are not present, then the 1st available mp4 would be considered.
 5. Sets the download status to IN_PROGRESS.
 6. Once all the assets of current ad fails,
 6a) Starts with the asset downloading of next ad in the playlist.
 7. Once caching of assets of all ads in the playlist are attempted,
 7a) Sets the download status to NOT_IN_PROGRESS.
 7b) Notifies YuMeAdEventAdNotReady (YuMeAdStatusCachingFailed).
 7c) Starts with auto-prefetch operation, if enabled.

 */
- (void)test_INIT_AD_057 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    GHTestLog(@"Initializes with the fetched YuMe Ad Params.");
}

#endif

@end
