//
//  HandleEvent.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#import "YuMePresentedViewController.h"
#define IsIOS8 (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1)

@interface HandleEvent : XCTAsyncTestCase
@property (nonatomic, strong) UIViewController *adDisplayViewController;
@property (nonatomic, strong) YuMePresentedViewController *presentedAdViewController;
@property (nonatomic, strong) UIView *adView;

@end

@implementation HandleEvent

@synthesize adDisplayViewController;
@synthesize presentedAdViewController;
@synthesize adView;

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
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)handleEventEventListener:(NSArray *)userInfo {
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


- (CGRect)currentScreenBoundsDependOnOrientation {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    if(IsIOS8) {
        return screenBounds;
    }
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(width, height);
    } else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(height, width);
    }
    return screenBounds;
}


- (void)presentShowAd {
    presentedAdViewController = [[YuMePresentedViewController alloc] init];
    adDisplayViewController = [YuMeUnitTestUtils topMostController];
    [adDisplayViewController presentViewController:presentedAdViewController animated:NO completion:^() {
        NSLog(@"Presented Roll View Controller in Application: %@", presentedAdViewController);
        NSError *pError = nil;
        
        CGRect screenBounds = [self currentScreenBoundsDependOnOrientation];
        adView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width - 10, screenBounds.size.height -10)];
        [adDisplayViewController.view addSubview:adView];
        
        XCTAssertTrue([pYuMeSDK yumeSdkShowAd:adView viewController:presentedAdViewController errorInfo:&pError], @"yumeSdkShowAd successful.");
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
        
        [adView removeFromSuperview];
        adView = nil;
        adDisplayViewController = nil;
        presentedAdViewController = nil;
    }
}

/**
 SDK State:Not Initialized
 Called when SDK is not initialized.
 
 
 Native SDK
 - Returns error message: "yumeSdkHandleEvent(): YuMe SDK is not Initialized."

 */
- (void)test_HE_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    XCTAssertFalse([pYuMeSDK yumeSdkHandleEvent:YuMeEventTypeNone errorInfo:&pError], @"SdkHandleEvent Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkHandleEvent(): YuMe SDK is not Initialized.", @"yumeSdkHandleEvent(): YuMe SDK is not Initialized.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 No Streaming / Prefetched Ad play is in progress.
 
 
 Native SDK
 - Returns error message: "yumeSdkHandleEvent(): No Ad Play in Progress."

 */
- (void)test_HE_002 {
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
    [self performSelectorInBackground:@selector(handleEventEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    NSLog(@"Initialization Successful.");
    
    XCTAssertFalse([pYuMeSDK yumeSdkHandleEvent:YuMeEventTypeAdViewResized errorInfo:&pError], @"SdkHandleEvent Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkHandleEvent(): No Ad Play in Progress.", @"yumeSdkHandleEvent(): No Ad Play in Progress.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 Streaming / Prefetched Ad play is in progress & Event Type received is invalid (NONE).
 
 
 Native SDK
 - Returns error message: "yumeSdkHandleEvent(): Invalid Event."

 */
- (void)test_HE_003 {
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
    [self performSelectorInBackground:@selector(handleEventEventListener:) withObject:userInfo];
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
        [self performSelectorInBackground:@selector(handleEventEventListener:) withObject:userInfo2];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
    }
    
    [self presentShowAd];
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(handleEventEventListener:) withObject:userInfo3];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdPlaying event.");
    
    XCTAssertFalse([pYuMeSDK yumeSdkHandleEvent:YuMeEventTypeNone errorInfo:&pError], @"SdkHandleEvent Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkHandleEvent(): Invalid Event.", @"yumeSdkHandleEvent(): Invalid Event.");
        NSLog(@"Result : %@", str);
    }
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkStopAd:&pError], @"yumeSdkStopAd() Successful.");

    [self runForInterval:2];
    
    [self dismissShowAd];
}

/**
 SDK State: Initialized
 Streaming / Prefetched Ad play is in progress and a valid Event Type received (AD_VIEW_RESIZED).
 
 
 Native SDK
 1. Resizes the internal Ad Views.
 
 JS SDK
 1. Resizes the internal Ad Views.

 */
- (void)test_HE_004 {
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
    [self performSelectorInBackground:@selector(handleEventEventListener:) withObject:userInfo];
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
        [self performSelectorInBackground:@selector(handleEventEventListener:) withObject:userInfo2];
        [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
        NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");
        
    }
    
    [self presentShowAd];
    
    [self prepare];
    NSArray *userInfo3 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdPlaying], nil];
    [self performSelectorInBackground:@selector(handleEventEventListener:) withObject:userInfo3];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdPlaying event.");
    
    [self runForInterval:2];
    
    if (adView) {
        CGRect frame = CGRectZero;
        
        frame = self.adView.frame;
        frame.origin.x += 20;
        frame.origin.y += 20;
        frame.size.width -= 100;
        frame.size.height -= 100;

        self.adView.frame = frame;
    }
    
    XCTAssertTrue([pYuMeSDK yumeSdkHandleEvent:YuMeEventTypeAdViewResized errorInfo:&pError], @"SdkHandleEvent Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTFail(@"Result : %@", str);
    }
    NSLog(@"SdkHandleEvent Successful.");

    [self runForInterval:2];
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkStopAd:&pError], @"yumeSdkStopAd() Successful.");
    NSLog(@"yumeSdkStopAd Successful.");

    [self runForInterval:1];
    
    [self dismissShowAd];
}

@end
