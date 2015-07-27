//
//  ErrorVAST.m
//
#import <GHUnit/GHUnit.h>
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"

@interface ErrorVAST : GHAsyncTestCase

@property (nonatomic) BOOL bSDKInitialized;
@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;

@end

@implementation ErrorVAST
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

    // Run at end of all tests in the class
    NSLog(@"######################## RUN END - TeatDownClass #######################################");
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

- (void)errorEventListener:(NSArray *)userInfo {
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

#pragma mark -
#pragma mark TestCases

/**
 Wrapper vast contains no xml nodes	
 
 start to play ad	
 1st Party Error Tracker should be hit with reason = 1	
 
 http://172.18.4.131/vast-unit-testing/error/dynamic_preroll_playlist-case1-2.vast2xml

 */

/*
- (void)test_VAST_EC_001 {
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
        [self performSelectorInBackground:@selector(errorEventListener:) withObject:userInfo];
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
    params.eSdkUsageMode = YuMeSdkUsageModeStreaming;
    params.bEnableAutoPrefetch = NO;
    params.pAdServerUrl = @"http://download.yumenetworks.com/yume/demo/bharath/vast-unit-testing/error/1/";
    params.pDomainId = @"211EsvNSRHO";
    
    GHAssertTrue([pYuMeSDK yumeSdkModifyAdParams:params errorInfo:&pError], @"yumeSdkModifyAdParams() fails");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:adParams]);
    GHRunForInterval(1);
    
    
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    
    GHAssertTrue([pYuMeSDK yumeSdkShowAd:adDisplayViewController.view viewController:adDisplayViewController errorInfo:&pError], @"yumeSdkShowAd() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHTestLog(@"Result : %@", str);
        GHFail(@"Fail: %@", str);
    }
    
    presentedAdViewController = nil;
    adDisplayViewController = nil;
    
    [self prepare];
    userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [NSString stringWithFormat:@"%@, %@", [YuMeAppUtils getAdEventStr:YuMeAdEventAdNotReady], [YuMeAppUtils getAdEventStr:YuMeAdEventAdCompleted]], nil];
    [self performSelectorInBackground:@selector(errorEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"YuMeAdEventAdNotReady / YuMeAdEventAdCompleted event fired.");
    
}
 */

@end
