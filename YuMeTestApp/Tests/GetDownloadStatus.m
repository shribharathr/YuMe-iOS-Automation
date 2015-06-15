//
//  GetDownloadStatus.m
//
#import <GHUnit/GHUnit.h>
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface GetDownloadStatus : GHAsyncTestCase
@end

@implementation GetDownloadStatus

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
        GHRunForInterval(1);
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)getDownloadEventListener:(NSArray *)userInfo {
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

/**
 SDK State:Not Initialized
 Called when SDK is not  initialized.
 
 Native SDK
 - Returns error message: "yumeSdkGetDownloadStatus(): YuMe SDK is not Initialized."

 */
- (void)test_GET_DS_001 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    GHAssertFalse([pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"yumeSdkGetDownloadStatus() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkGetDownloadStatus(): YuMe SDK is not Initialized.", @"yumeSdkGetDownloadStatus(): YuMe SDK is not Initialized.");
        GHTestLog(@"Result : %@", str);
    }
}

/**
 SDK State: Initialized
 No asset downloads in progress / aborted.
 
 
 Native SDK
 1. Returns the download status as NOT_IN_PROGRESS.
 
 */
- (void)test_GET_DS_002 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
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
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(getDownloadEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    float ePer = 0.0f;
    do {
        GHRunForInterval(0.2);
        pError = nil;
        ePer = [pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
    } while(ePer < 0.1);

    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkAbortDownload:&pError], @"yumeSdkAbortDownload() Successful.");
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }

    pError = nil;
    GHAssertEquals(YuMeDownloadStatusDownloadsNotInProgress, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsNotInProgress");
}

/**
 SDK State: Initialized
 Asset downloads in progress.
 
 
 Native SDK
 1. Returns the download status as IN_PROGRESS.

 */
- (void)test_GET_DS_003 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
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
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(getDownloadEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    pError = nil;
    while ([pYuMeSDK yumeSdkGetDownloadedPercentage:&pError] > 1) {
        GHRunForInterval(0.2);
        pError = nil;
        GHAssertEquals(YuMeDownloadStatusDownloadsInProgress, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsInProgress");
        break;
    }
}

/**
 SDK State: Initialized
 Asset downloads paused.
 
 Native SDK
 1. Returns the download status as PAUSED.
 
 */
- (void)test_GET_DS_004 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    YuMeAdParams *params = [YuMeUnitTestUtils getApplicationYuMeAdParams];
    GHAssertNotNil(params, @"params object not found");
    
    GHTestLog(@"Test AdParams: \n%@", [YuMeUnitTestUtils getStringYuMeAdParms:params]);
    
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
    NSArray *userInfo = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventInitSuccess], nil];
    [self performSelectorInBackground:@selector(getDownloadEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    YuMeDownloadStatus eDownloadStatus = YuMeDownloadStatusNone;
    do {
        GHRunForInterval(0.5);
        pError = nil;
        eDownloadStatus = [pYuMeSDK yumeSdkGetDownloadStatus:&pError];
    } while( (eDownloadStatus == YuMeDownloadStatusDownloadsNotInProgress) || (eDownloadStatus == YuMeDownloadStatusNone) );
    
    GHAssertTrue([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHTestLog(@"Result : %@", str);
        GHFail(str);
    }
    
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertEquals(YuMeDownloadStatusDownloadsPaused, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsPaused");
}

@end
