//
//  PauseDownload.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface PauseDownload : XCTAsyncTestCase
@end

@implementation PauseDownload

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
    [self runForInterval:1];
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}


- (void)pDEventListener:(NSArray *)userInfo {
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
 - Returns error message: "yumeSdkPauseDownload(): YuMe SDK is not Initialized."
 
 */
- (void)test_PD_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    XCTAssertFalse([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkPauseDownload(): YuMe SDK is not Initialized.", @"yumeSdkPauseDownload(): YuMe SDK is not Initialized.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 No asset downloads in progress.
 
 
 JS SDK
 1. Does nothing.

 */
- (void)test_PD_002 {
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
    [self performSelectorInBackground:@selector(pDEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    XCTAssertTrue([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
    }

}

/**
 SDK State: Initialized
 Asset downloads in progress.
 
 
 JS SDK
 1. Pauses the ongoing asset downloads.
 2. Sets the download status to PAUSED.
 
 Native SDK
 1. Pauses the ongoing asset downloads.
 
 */
- (void)test_PD_003 {
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
    [self performSelectorInBackground:@selector(pDEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");
    
    [self runForInterval:1];
    
    YuMeDownloadStatus eDownloadStatus = YuMeDownloadStatusNone;
    do {
        [self runForInterval:0.5];
        pError = nil;
        eDownloadStatus = [pYuMeSDK yumeSdkGetDownloadStatus:&pError];
    } while( eDownloadStatus == YuMeDownloadStatusDownloadsNotInProgress);
    
    XCTAssertTrue([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
    
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertEqual(YuMeDownloadStatusDownloadsPaused, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsPaused");

}

@end
