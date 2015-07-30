//
//  IsAdAvailability.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

@interface IsAdAvailability : XCTAsyncTestCase
@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;

@end

@implementation IsAdAvailability
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
        [self runForInterval:1];
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)isAdAvailEventListener:(NSArray *)userInfo {
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
 - Returns error message: "yumeSdkIsAdAvailable(): YuMe SDK is not Initialized."
 
 */
- (void)test_IS_AD_AVAIL_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    XCTAssertFalse([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkIsAdAvailable(): YuMe SDK is not Initialized.", @"yumeSdkIsAdAvailable(): YuMe SDK is not Initialized.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 SDK Mode: STREAMING
 Called when SDK is initialized.
 
 
 Native SDK
 1. Returns the Ad Availability Status set by the JS SDK.
 
 */
- (void)test_IS_AD_AVAIL_002 {
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
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    NSLog(@"Initialization Successful.");
    
    if (params.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
        XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() Successful.");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        
        [self runForInterval:2];
    }
    
    XCTAssertTrue([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Result : %@", str);
    }
    
}

/**
 SDK State: Initialized
 SDK Mode: PREFETCH
 
 Called when SDK is initialized.
 
 NOTE:
 1. The JS SDK should set this value in Native SDK to "true" in the following conditions:
 a. Ad is Prefetched & Caching disabled.
 b. Ad is Prefetched & Caching enabled but caching not possible.
 c. When assets caching of an ad is completed successfully (100% playlist).
 d. When assets caching of atleast one ad is completed successfully (Ad Coverage Playlist).
 e. When asset downloads are aborted.
 
 2. The JS SDK should set this value to "false" in the following conditions:
 a. Prefetched Ad play completes successfully (or) fails (or) times-out.
 b. Prefetched Ad play is stopped.
 c. Prefetched ad expires.
 d. A new prefetch request is made when a prefetched ad already exists (due to cases like Modify Params, Clear Cache etc.,).
 e. When asset downloads are paused.
 f. When a prefetched ad play starts.
 
 
 Native SDK
 1. Returns the Ad Availability Status set by the JS SDK.
 
 2. If no ad available,
 - Returns error message: "yumeSdkIsAdAvailable(): No Prefetched Ad Present."
 
 JS SDK
 - Hits Generic Empty Tracker / Unfilled Tracker / Filled Tracker as appropriate.
 
 NOTE: JS SDK should ensure that any tracker is hit only once, even if the application calls this API 'n' number of times (within a loop).
 
 */
- (void)test_IS_AD_AVAIL_003 {
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
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    NSLog(@"Initialization Successful.");
    
    // a. Ad is Prefetched & Caching disabled.
    
    NSLog(@"a. Ad is Prefetched & Caching disabled.");
    
    pError = nil;
    params.bEnableCaching = FALSE;
    params.pAdditionalParams = @"d=f";
    params.bEnableAutoPrefetch = FALSE;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay event receivied.");
    
    XCTAssertTrue([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): TRUE");
    
    // b. Ad is Prefetched & Caching enabled but caching not possible.
    
    NSLog(@"b. Ad is Prefetched & Caching enabled but caching not possible.");
    
    pError = nil;
    params.bEnableCaching = TRUE;
    params.storageSize = 0.0f;
    params.pAdditionalParams = @"c=d";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo3];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    
    XCTAssertTrue([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): TRUE");
    
    //c. When assets caching of an ad is completed successfully (100% playlist).
    NSLog(@"c. When assets caching of an ad is completed successfully (100 percent playlist).");
    pError = nil;
    params.bEnableCaching = TRUE;
    params.storageSize = 10.0f;
    params.pAdditionalParams = @"d=h";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self prepare];
    NSArray *userInfo4 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo4];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    
    XCTAssertTrue([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): TRUE");
    
    // e. When asset downloads are aborted.
    NSLog(@"e. When asset downloads are aborted.");
    
    pError = nil;
    params.pAdditionalParams = @"a=c";
    params.bEnableCaching = TRUE;
    params.storageSize = 10.0f;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    pError = nil;
    while ([pYuMeSDK yumeSdkGetDownloadedPercentage:&pError] > 1) {
        XCTAssertTrue([pYuMeSDK yumeSdkAbortDownload:&pError], @"yumeSdkAbortDownload() Successful.");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        break;
    }
    
    XCTAssertTrue([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): TRUE");
    
    NSLog(@"2. The JS SDK should set this value to FALSE in the following conditions:");
    
    //a. Prefetched Ad play completes successfully (or) fails (or) times-out.
    NSLog(@"a. Prefetched Ad play completes successfully / fails / times-out.");
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self prepare];
    NSArray *userInfo5 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo5];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    
    [self presentShowAd];
    
    [self prepare];
    NSArray *userInfo6 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo6];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdPlaying event.");
    
    [self runForInterval:4];
    
    [self prepare];
    NSArray *userInfo7 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo7];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdCompleted event.");
    
    [self dismissShowAd];
    
    XCTAssertFalse([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.", @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.");
        NSLog(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): FALSE");
    
    //b. Prefetched Ad play is stopped.
    NSLog(@"b. Prefetched Ad play is stopped.");
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self prepare];
    NSArray *userInfo8 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo8];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    [self presentShowAd];
    
    [self prepare];
    NSArray *userInfo9 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo9];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdPlaying event.");
    [self runForInterval:4];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkStopAd:&pError], @"StopAd Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"yumeSdkStopAd() Successful.");
    
    [self dismissShowAd];
    
    [self runForInterval:2];
    
    XCTAssertFalse([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.", @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.");
        NSLog(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): FALSE");
    
    
    //c. Prefetched ad expires.
    NSLog(@"c. Prefetched ad expires.");
    
    pError = nil;
    
    params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com"; //@"http://qa-web-001.sjc1.yumenetworks.com/yvp/hari_test/bharath/";
    params.pDomainId = @"3679UjYRBTPg";
    params.pAdditionalParams = @"placement_id=72531&advertisement_id=12946";
    params.bEnableCaching = TRUE;
    params.storageSize = 10.0f;
    params.bEnableAutoPrefetch = FALSE;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self prepare];
    NSArray *userInfo10 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo10];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    
    [self runForInterval:110];
    
    [self prepare];
    NSArray *userInfo11 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo11];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdNotReady event.");
    
    XCTAssertFalse([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.", @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.");
        NSLog(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): FALSE");

    //d. A new prefetch request is made when a prefetched ad already exists (due to cases like Modify Params, Clear Cache etc.,).
    NSLog(@"d. A new prefetch request is made when a prefetched ad already exists due to cases like Modify Params, Clear Cache etc.,.");
    
    pError = nil;
    params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com"; //@"http://qa-web-001.sjc1.yumenetworks.com/yvp/hari_test/bharath/";
    params.pDomainId = @"3679UjYRBTPg";
    params.pAdditionalParams = @"placement_id=72531&advertisement_id=12946";
    params.bEnableCaching = TRUE;
    params.storageSize = 10.0f;
    params.bEnableAutoPrefetch = FALSE;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self prepare];
    NSArray *userInfo12 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo12];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"yumeSdkClearCache called.");
    
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"yumeSdkInitAd() called.");
    
    [self runForInterval:1];
    
    pError = nil;
    XCTAssertFalse([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.", @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.");
        NSLog(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): FALSE");
    
    //e. When asset downloads are paused.
    NSLog(@"e. When asset downloads are paused.");
    
    YuMeDownloadStatus eDownloadStatus = YuMeDownloadStatusNone;
    do {
        [self runForInterval:0.5];
        pError = nil;
        eDownloadStatus = [pYuMeSDK yumeSdkGetDownloadStatus:&pError];
    } while( eDownloadStatus == YuMeDownloadStatusDownloadsNotInProgress);
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"yumeSdkPauseDownload() Successful.");
    
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertFalse([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.", @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.");
        NSLog(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): FALSE");
    
    //f. When a prefetched ad play starts.
    NSLog(@"f. When a prefetched ad play starts.");
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkResumeDownload:&pError], @"yumeSdkResumeDownload() Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    [self prepare];
    NSArray *userInfo13 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo13];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    
    [self presentShowAd];
    
    [self prepare];
    NSArray *userInfo14 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(isAdAvailEventListener:) withObject:userInfo14];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdPlaying event.");
    
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertFalse([pYuMeSDK yumeSdkIsAdAvailable:&pError], @"yumeSdkIsAdAvailable() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.", @"yumeSdkIsAdAvailable(): No Prefetched Ad Present.");
        NSLog(@"Result : %@", str);
    }
    NSLog(@"yumeSdkIsAdAvailable(): FALSE");
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkStopAd:&pError], @"StopAd Successful.");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"yumeSdkStopAd() Successful.");
    [self dismissShowAd];
}

@end
