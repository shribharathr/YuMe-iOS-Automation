//
//  IsCacheEnabled.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface IsCacheEnabled : XCTAsyncTestCase
@end

@implementation IsCacheEnabled

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

- (void)isCacheEventListener:(NSArray *)userInfo {
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

/**
 SDK State:Not Initialized
 Called when SDK is not  initialized.
 
 Native SDK
 - Returns error message: "yumeSdkIsCacheEnabled(): YuMe SDK is not Initialized."
 */
- (void)test_IS_CE_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    XCTAssertFalse([pYuMeSDK yumeSdkIsCacheEnabled:&pError], @"yumeSdkIsCacheEnabled() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkIsCacheEnabled(): YuMe SDK is not Initialized.", @"yumeSdkIsCacheEnabled(): YuMe SDK is not Initialized.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 Called when SDK is initialized.
 
 
 Native SDK
 1. Returns true, if caching enabled.
 2. Returns false, if caching disabled.

 */
- (void)test_IS_CE_002 {
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
    [self performSelectorInBackground:@selector(isCacheEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    
    NSLog(@"Initialization Successful.");
    
    pError = nil;
    YuMeAdParams *adParams = [pYuMeSDK yumeSdkGetAdParams:&pError];
    BOOL bEnableCaching = adParams.bEnableCaching;
    
    XCTAssertEqual(bEnableCaching, [pYuMeSDK yumeSdkIsCacheEnabled:&pError], @"yumeSdkIsCacheEnabled() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
}


@end
