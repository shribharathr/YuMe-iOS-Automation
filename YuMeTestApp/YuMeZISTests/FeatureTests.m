//
//  FeatureTests.m
//

#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

#define AD_SERVER_URL               @"http://shadow01.yumenetworks.com/"
#define DOMAIN_ID                   @"1736jrhZObnN"

#define FEATURE_P_V_PARAMS          @""
#define FEATURE_P_I_PARAMS          @""
#define FEATURE_1GEN_MC_PARAMS      @""
#define FEATURE_2GEN_MC_PARAMS      @""
#define FEATURE_1GEN_MB_PARAMS      @""
#define FEATURE_2GEN_MB_PARAMS      @""
#define FEATURE_FLIP_TAP_PARAMS     @""
#define FEATURE_FLIP_SWIPE_PARAMS   @""
#define FEATURE_MRAID_PARAMS        @""
#define FEATURE_WRAPPER_PARAMS      @""
#define FEATURE_VPAID_PARAMS        @""


@interface FeatureTests : XCTAsyncTestCase

@property (nonatomic) BOOL bSDKInitialized;
@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;

@end

@implementation FeatureTests
@synthesize bSDKInitialized;
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
    bSDKInitialized = NO;
}

- (void)tearDown {
    NSLog(@"************************ Unit Test - TearDown ************************");
    NSError *pError = nil;
    
    // Run after each test method
    if (pYuMeSDK) {
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    bSDKInitialized = NO;
    [self runForInterval:1];
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    [self runForInterval:2];
}

#pragma mark -
#pragma mark Private Methods

- (void)featureEventListener:(NSArray *)userInfo {
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
 Plain Video
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=7585
 */
- (void)test_FEATURE_P_V {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }

    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_P_V_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }

    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
 
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 Plain Image
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&pre_fetch=true&xml_version=v3&placement_id=5571&advertisement_id=9524
 */
- (void)test_FEATURE_P_I {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_P_I_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:1];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 1st Gen Mobile Connect
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=4293
 */
- (void)test_FEATURE_1GEN_MC {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_1GEN_MC_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 2nd Gen Mobile Connect
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=5418
 */
- (void)test_FEATURE_2GEN_MC {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_2GEN_MC_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 1st Gen Mobile Billboard
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=4294
 */
- (void)test_FEATURE_1GEN_MB {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_1GEN_MB_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 2nd Gen Mobile Billboard
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=5417
 */
- (void)test_FEATURE_2GEN_MB {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_2GEN_MB_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 Mobile Flip – Tap
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=7183
 */
- (void)test_FEATURE_FLIP_TAP {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_FLIP_TAP_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 Mobile Flip – Swipe
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=7223
 */
- (void)test_FEATURE_FLIP_SWIPE {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_FLIP_SWIPE_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 MRAID
 http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3679FjmiiOWJ&xml_version=v3&placement_id=72498&advertisement_id=12906
 */
- (void)test_FEATURE_MRAID {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
    params.pDomainId = @"3679FjmiiOWJ";
    params.pAdditionalParams = @"placement_id=72498&advertisement_id=12906";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:(kTIME_OUT * 2)];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 Wrapper Playlist
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=5479
 */
- (void)test_FEATURE_WRAPPER {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = AD_SERVER_URL;
    params.pDomainId = DOMAIN_ID;
    params.pAdditionalParams = FEATURE_WRAPPER_PARAMS;
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

/**
 VPAID
 http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3679FjmiiOWJ&xml_version=v3&placement_id=72504&advertisement_id=12925
 */

- (void)test_FEATURE_VPAID {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    XCTAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com";
    params.pDomainId = @"3968vyRqcKgs";
    params.pAdditionalParams = @"placement_id=74100&advertisement_id=13465";
    
    XCTAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    [self runForInterval:1];
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    [self runForInterval:1];
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        XCTAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        NSLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"YuMeAdEventAdPlaying event fired.");
    
    [self runForInterval:4];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:(kTIME_OUT * 2)];
    NSLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    [self runForInterval:1];
}

@end
