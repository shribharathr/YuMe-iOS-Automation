//
//  FeatureTests.m
//
#import <GHUnit/GHUnit.h>
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

@interface FeatureTests : GHAsyncTestCase

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
    pYuMeInterface = [YuMeUnitTestUtils getYuMeInterface];
    pYuMeSDK = [pYuMeInterface getYuMeSDKHandle];
    bSDKInitialized = NO;
}

- (void)tearDownClass {
    // Run at end of all tests in the class
    NSLog(@"######################## RUN END - TeatDownClass #######################################");
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
}

- (void)setUp {
    // Run before each test method
    NSLog(@"************************ Unit Test - SetUp ************************");
}

- (void)tearDown {
    NSLog(@"************************ Unit Test - TearDown ************************");
}

#pragma mark -
#pragma mark Private Methods

- (void)featureEventListener:(NSArray *)userInfo {
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
 Plain Video
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=7585
 */
- (void)test_FEATURE_P_V {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }

    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7585";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }

    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
 
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 Plain Image
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&pre_fetch=true&xml_version=v3&placement_id=5571&advertisement_id=9524
 */
- (void)test_FEATURE_P_I {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=9524";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(1);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 1st Gen Mobile Connect
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=4293
 */
- (void)test_FEATURE_1GEN_MC {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=4293";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 2nd Gen Mobile Connect
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=5418
 */
- (void)test_FEATURE_2GEN_MC {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=5418";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 1st Gen Mobile Billboard
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=4294
 */
- (void)test_FEATURE_1GEN_MB {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=4294";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 2nd Gen Mobile Billboard
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=5417
 */
- (void)test_FEATURE_2GEN_MB {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=5417";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 Mobile Flip – Tap
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=7183
 */
- (void)test_FEATURE_FLIP_TAP {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7183";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 Mobile Flip – Swipe
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=7223
 */
- (void)test_FEATURE_FLIP_SWIPE {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=7223";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 MRAID
 http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3679FjmiiOWJ&xml_version=v3&placement_id=72498&advertisement_id=12906
 */
- (void)test_FEATURE_MRAID {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
    params.pDomainId = @"3679FjmiiOWJ";
    params.pAdditionalParams = @"placement_id=72498&advertisement_id=12906";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:(kTIME_OUT * 2)];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 Wrapper Playlist
 http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=211EsvNSRHO&xml_version=v3&placement_id=5571&advertisement_id=5479
 */
- (void)test_FEATURE_WRAPPER {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
    params.pDomainId = @"211EsvNSRHO";
    params.pAdditionalParams = @"placement_id=5571&advertisement_id=5479";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

/**
 VPAID
 http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3679FjmiiOWJ&xml_version=v3&placement_id=72504&advertisement_id=12925
 */

- (void)test_FEATURE_VPAID {
    NSError *pError = nil;
    NSArray *userInfo = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    if (bSDKInitialized == false) {
        
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
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventInitSuccess event fired.");
        
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"Initialization Successful.");
        bSDKInitialized = YES;
    }
    
    pError = nil;
    params.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com";
    params.pDomainId = @"3968vyRqcKgs";
    params.pAdditionalParams = @"placement_id=74100&advertisement_id=13465";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHRunForInterval(1);
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    if(adParams.eSdkUsageMode == YuMeSdkUsageModePrefetch) {
        pError = nil;
        GHAssertTrue([pYuMeSDK yumeSdkInitAd:&pError], @"yumeSdkInitAd() fails");
        if (pError) {
            GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
            GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
        }
        GHTestLog(@"yumeSdkInitAd Successful.");
        
        [self prepare];
        userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
        [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
        GHTestLog(@"YuMeAdEventAdReadyToPlay event fired.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdPlaying event fired.");
    
    GHRunForInterval(4);
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted], nil];
    [self performSelectorInBackground:@selector(featureEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:(kTIME_OUT * 2)];
    GHTestLog(@"YuMeAdEventAdCompleted event fired.");
    
    [self dismissShowAd];
    GHRunForInterval(1);
}

@end
