//
//  GetDownloadPercentage.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface GetDownloadPercentage : XCTAsyncTestCase
@end

@implementation GetDownloadPercentage

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


- (void)getDPEventListener:(NSArray *)userInfo {
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
 - Returns error message: "yumeSdkGetDownloadedPercentage(): YuMe SDK is not Initialized."

 */
- (void)test_GET_DP_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    XCTAssertFalse([pYuMeSDK yumeSdkGetDownloadedPercentage:&pError], @"yumeSdkGetDownloadedPercentage() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkGetDownloadedPercentage(): YuMe SDK is not Initialized.", @"yumeSdkGetDownloadedPercentage(): YuMe SDK is not Initialized.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 Fetching assets' size (HEAD request) of 1st ad is in progress.
 
 
 Native SDK
 1. Returns 0%.
 
 */
- (void)test_GET_DP_002 {
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
    [self performSelectorInBackground:@selector(getDPEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    [self runForInterval:0.5];

    pError = nil;
    float ePer = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
    NSString *percentage = [[NSNumber numberWithFloat:ePer] stringValue];
    XCTAssertEqual(percentage, @"0", @"Returns 0");
}


/**
 SDK State: Initialized
 Fetching assets' size (HEAD request) of 2nd and and so on, is in progress.
 
 
 Native SDK
 1. Returns the % of assets downloaded so far.
 
 */
- (void)test_GET_DP_003 {
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
    [self performSelectorInBackground:@selector(getDPEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    [self runForInterval:0.5];
    
    pError = nil;
    float ePer = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
    NSString *percentage = [[NSNumber numberWithFloat:ePer] stringValue];
    XCTAssertEqual(percentage, @"0", @"Returns 0.");
}

/**
 SDK State: Initialized
 Asset downloads in progress.
 
 
 Native SDK
 1. Returns the % of assets downloaded so far.

 */
- (void)test_GET_DP_004 {
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
    [self performSelectorInBackground:@selector(getDPEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    pError = nil;
    while ([pYuMeSDK yumeSdkGetDownloadedPercentage:&pError] > 1) {
        [self runForInterval:0.2];
        pError = nil;
        XCTAssertEqual(YuMeDownloadStatusDownloadsInProgress, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsInProgress");
        break;
    }
    
    pError = nil;
    float ePer = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
    //NSString *percentage = [[NSNumber numberWithFloat:ePer] stringValue];
    //GHAssertGreaterThan(ePer, 0, @"Returns the % of assets downloaded so far.");
    NSLog(@"Returns the %f of assets downloaded so far.", ePer);

}

/**
 SDK State: Initialized
 Asset downloads paused.
 
 
 Native SDK
 1. Returns the % of assets downloaded so far.
 
 */
- (void)test_GET_DP_005 {
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
    [self performSelectorInBackground:@selector(getDPEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkClearCache:&pError], @"yumeSdkClearCache() Successful.");
    
    YuMeDownloadStatus eDownloadStatus = YuMeDownloadStatusNone;
    do {
        [self runForInterval:0.2];
        pError = nil;
        eDownloadStatus = [pYuMeSDK yumeSdkGetDownloadStatus:&pError];
    } while( (eDownloadStatus == YuMeDownloadStatusDownloadsNotInProgress) || (eDownloadStatus == YuMeDownloadStatusNone) );
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
    
    [self runForInterval:2];
    
    pError = nil;
    float ePer = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
    //GHAssertGreaterThan(ePer, 0.0, @"Returns the % of assets downloaded so far.");
    NSLog(@"Returns the %f of assets downloaded so far.", ePer);
}

/**
 SDK State: Initialized
 Asset downloads completed and ad is ready for playing.
 
 
 Native SDK
 1. Returns 100%.
 
 */
- (void)test_GET_DP_006 {
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
    [self performSelectorInBackground:@selector(getDPEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(getDPEventListener:) withObject:userInfo1];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventAdReadyToPlay event.");

    pError = nil;
    float ePer = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
    NSString *percentage = [[NSNumber numberWithFloat:ePer] stringValue];
    XCTAssertEqualObjects(percentage, @"100", @"Returns 100.");
}

/**
 SDK State: Initialized
 No asset downloads in progress but asset downloads not completed earlier / assets downloads aborted.
 
 
 Native SDK
 1. Returns 0%.
 
 */
- (void)test_GET_DP_007 {
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
    [self performSelectorInBackground:@selector(getDPEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    [self runForInterval:1];
    
    BOOL bIsAdAlreadyDownloaded = FALSE;
    
    YuMeDownloadStatus eDownloadStatus = YuMeDownloadStatusNone;
    do {
        [self runForInterval:0.5];
        pError = nil;
        eDownloadStatus = [pYuMeSDK yumeSdkGetDownloadStatus:&pError];
        
        pError = nil;
        if([pYuMeSDK yumeSdkIsAdAvailable:&pError]) {
            bIsAdAlreadyDownloaded = TRUE;
            break;
        }
    } while( (eDownloadStatus == YuMeDownloadStatusDownloadsNotInProgress) || (eDownloadStatus == YuMeDownloadStatusNone));
    
    if (bIsAdAlreadyDownloaded) {
        pError = nil;
        [pYuMeSDK yumeSdkClearCache:&pError];
        [self runForInterval:1];
    }
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkAbortDownload:&pError], @"yumeSdkAbortDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
    
    [self runForInterval:2];

    pError = nil;
    float ePer = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
    NSString *percentage = [[NSNumber numberWithFloat:ePer] stringValue];
    //XCTAssertEqual(ePer, 0.0, @"Returns the % of assets downloaded so far.");
    NSLog(@"Returns the %@ of assets downloaded so far.", percentage);

}

@end
