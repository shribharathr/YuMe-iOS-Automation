//
//  StopAd.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

@interface StopAd : XCTAsyncTestCase
@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;

@end

@implementation StopAd
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

- (void)stopAdEventListener:(NSArray *)userInfo {
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
 SDK State: Not Initialized	
 
 Called when SDK is not initialized.	
 
 Native SDK
 - Returns error message: "yumeSdkStopAd(): YuMe SDK is not Initialized."
 */
- (void)test_STOP_AD_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");

    XCTAssertFalse([pYuMeSDK yumeSdkStopAd:&pError], @"StopAd Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkStopAd(): YuMe SDK is not Initialized.", @"yumeSdkStopAd(): YuMe SDK is not Initialized.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized	
 No Streaming / Prefetched Ad play is in progress.	
 
 Native SDK
 - Returns error message “yumeSdkStopAd(): No Ad Play in Progress.”
 */
- (void)test_STOP_AD_002 {
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
    [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    NSLog(@"Initialization Successful.");
    
    XCTAssertFalse([pYuMeSDK yumeSdkStopAd:&pError], @"StopAd Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkStopAd(): No Ad Play in Progress.", @"yumeSdkStopAd(): No Ad Play in Progress.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 Streaming Ad play in progress.
 
 Native SDK
 1. Performs the necessary internal cleanup.
 
 JS SDK
 1. Stops the playing ad.
 2. Performs the necessary internal cleanup.
 */
- (void)test_STOP_AD_003 {
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
    [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo];
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
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Error : %@", str.description);
    }
    NSLog(@"Result: ModifyParams Successful.");
    params = nil;
 
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);
    
    [self presentShowAd];
    
    [self prepare];
    
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@,%@",[YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying]], nil];
    [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdReadyToPlay / YuMeAdEventAdPlaying event received.");

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
}

/**
 SDK State: Initialized
 Caching: ON/OFF
 Auto-Prefetch: OFF	
 Prefetched Ad play in progress.			
 
 Native SDK
 1. Performs the necessary internal cleanup.
 
 JS SDK
 1. Stops the playing ad.
 2. Performs the necessary internal cleanup.
 */
- (void)test_STOP_AD_004 {
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
    [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    NSLog(@"Initialization Successful.");
    
    if (params.bEnableAutoPrefetch) {
        pError = nil;
        params.bEnableAutoPrefetch = NO;
        
        XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"ModifyParams Successful.");
        if (pError) {
            NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
            XCTFail(@"Error : %@", str.description);
        }
        NSLog(@"Result: ModifyParams Successful.");
        params = nil;
    }
    
    [self runForInterval:2];
    
    pError = nil;
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:[pYuMeSDK yumeSdkGetAdParams:&pError]]);

    XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Error : %@", str.description);
    }
    NSLog(@"Result: yumeSdkInitAd() Successful.");
    
    [self prepare];
    NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo2];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");

    [self presentShowAd];
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo3];
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
}

/**
SDK State: Initialized
Caching: ON/OFF
Auto-Prefetch: ON	
Prefetched Ad play in progress.			
 
Native SDK
1. Performs the necessary internal cleanup.

JS SDK
1. Stops the playing ad.
2. Performs the necessary internal cleanup.
3. Makes a new prefetch request to the server.
4. Handles the response received.
*/

- (void)test_STOP_AD_005 {
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
    [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    NSLog(@"Initialization Successful.");
    
    if (params.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        [self prepare];
        NSArray *userInfo2 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo2];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
        
        [self presentShowAd];
        
        [self prepare];
        NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
        [self performSelectorInBackground:@selector(stopAdEventListener:) withObject:userInfo3];
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
    }
}

@end
