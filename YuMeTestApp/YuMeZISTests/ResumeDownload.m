//
//  ResumeDownload.m
//
#import "XCTAsyncTestCase.h"
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface ResumeDownload : XCTAsyncTestCase
@end

@implementation ResumeDownload

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

- (void)rDEventListener:(NSArray *)userInfo {
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
 - Returns error message: "yumeSdkResumeDownload(): YuMe SDK is not Initialized."
 
 */
- (void)test_RD_001 {
    NSError *pError = nil;
    
    XCTAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    XCTAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    XCTAssertFalse([pYuMeSDK yumeSdkResumeDownload:&pError], @"yumeSdkResumeDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        XCTAssertEqualObjects(str, @"yumeSdkResumeDownload(): YuMe SDK is not Initialized.", @"yumeSdkResumeDownload(): YuMe SDK is not Initialized.");
        NSLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
	
 No paused asset downloads.			
 
 JS SDK
 1. Does nothing.
 
 */
- (void)test_RD_002 {
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
    [self performSelectorInBackground:@selector(rDEventListener:) withObject:userInfo];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        XCTFail(@"%@",[NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        NSLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    NSLog(@"Initialization Successful.");

    XCTAssertTrue([pYuMeSDK yumeSdkResumeDownload:&pError], @"yumeSdkResumeDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
}

/**
 SDK State: Initialized
	
 Asset downloads paused.			
 
 JS SDK
 1. Resumes the paused asset downloads.
 2. Sets the download status to IN_PROGRESS.

 Native SDK
 1. Resumes the paused asset downloads.
 */
- (void)test_RD_003 {
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
    [self performSelectorInBackground:@selector(rDEventListener:) withObject:userInfo];
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
    XCTAssertTrue([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
    
    [self runForInterval:2];
    
    pError = nil;
    XCTAssertEqual(YuMeDownloadStatusDownloadsPaused, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsPaused");
    
    pError = nil;
    XCTAssertTrue([pYuMeSDK yumeSdkResumeDownload:&pError], @"yumeSdkResumeDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        NSLog(@"Result : %@", str);
        XCTFail(@"%@",str);
    }
    
    [self runForInterval:1];

    //pError = nil;
    //XCTAssertEqual(YuMeDownloadStatusDownloadsInProgress, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsInProgress");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(rDEventListener:) withObject:userInfo1];
    [self waitForStatus:kXCTUnitWaitStatusSuccess timeout:kTIME_OUT];
    NSLog(@" YuMeAdEventAdReadyToPlay event.");
}

@end
