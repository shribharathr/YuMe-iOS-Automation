//
//  ResumeDownload.m
//
#import <GHUnit/GHUnit.h>
#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"

@interface ResumeDownload : GHAsyncTestCase
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
        GHRunForInterval(1);
        [pYuMeSDK yumeSdkDeInit:&pError];
    }
    
    if (pYuMeInterface) {
        pYuMeInterface = nil;
    }
    
    GHRunForInterval(1);

    NSLog(@"************************ Unit Test - TearDown ************************");
}

- (void)rDEventListener:(NSArray *)userInfo {
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
 - Returns error message: "yumeSdkResumeDownload(): YuMe SDK is not Initialized."
 
 */
- (void)test_RD_001 {
    NSError *pError = nil;
    
    GHAssertNotNil(pYuMeInterface, @"pYuMeInterface object not found");
    GHAssertNotNil(pYuMeSDK, @"pYuMeSDK object not found");
    
    GHAssertFalse([pYuMeSDK yumeSdkResumeDownload:&pError], @"yumeSdkResumeDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHAssertEqualStrings(str, @"yumeSdkResumeDownload(): YuMe SDK is not Initialized.", @"yumeSdkResumeDownload(): YuMe SDK is not Initialized.");
        GHTestLog(@"Result : %@", str);
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
    [self performSelectorInBackground:@selector(rDEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");

    GHAssertTrue([pYuMeSDK yumeSdkResumeDownload:&pError], @"yumeSdkResumeDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHTestLog(@"Result : %@", str);
        GHFail(str);
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
    [self performSelectorInBackground:@selector(rDEventListener:) withObject:userInfo];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@"Notifies YuMeAdEventInitSuccess event.");
    
    if (pError) {
        GHFail([NSString stringWithFormat:@" %s <Error>: %@", __FUNCTION__ , [[YuMeUnitTestUtils getErrDesc:pError] description]]);
        GHTestLog(@"Error: %@", [[YuMeUnitTestUtils getErrDesc:pError] description]);
    }
    GHTestLog(@"Initialization Successful.");
    
    GHRunForInterval(1);
    
    BOOL bIsAdAlreadyDownloaded = FALSE;
    
    YuMeDownloadStatus eDownloadStatus = YuMeDownloadStatusNone;
    do {
        GHRunForInterval(0.5);
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
        GHRunForInterval(1);
    }
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkPauseDownload:&pError], @"yumeSdkPauseDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHTestLog(@"Result : %@", str);
        GHFail(str);
    }
    
    GHRunForInterval(2);
    
    pError = nil;
    GHAssertEquals(YuMeDownloadStatusDownloadsPaused, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsPaused");
    
    pError = nil;
    GHAssertTrue([pYuMeSDK yumeSdkResumeDownload:&pError], @"yumeSdkResumeDownload() Successful.");
    if (pError) {
        NSString *str = [YuMeUnitTestUtils getErrDesc:pError];
        GHTestLog(@"Result : %@", str);
        GHFail(str);
    }
    
    GHRunForInterval(1);

    //pError = nil;
    //GHAssertEquals(YuMeDownloadStatusDownloadsInProgress, [pYuMeSDK yumeSdkGetDownloadStatus:&pError], @"YuMeDownloadStatusDownloadsInProgress");
    
    [self prepare];
    NSArray *userInfo1 = [NSArray arrayWithObjects: NSStringFromSelector(_cmd), [YuMeAppUtils getAdEventStr:YuMeAdEventAdReadyToPlay], nil];
    [self performSelectorInBackground:@selector(rDEventListener:) withObject:userInfo1];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:kTIME_OUT];
    GHTestLog(@" YuMeAdEventAdReadyToPlay event.");
}

@end
