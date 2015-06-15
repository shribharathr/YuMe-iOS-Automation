//
//  YuMeInterface.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeInterface.h"
#import "YuMeAppUtils.h"
#import "YuMeLogViewController.h"
#import "YuMeViewController.h"

@interface YuMeInterface()

/* YuMe SDK Instance */
@property (nonatomic, retain) YuMeSDKInterface *pYuMeSDK;

@end //@interface YuMeInterface

@implementation YuMeInterface

- (id)init {
    if (self = [super init]) {
        [self initialize];
        NSLog(@"Creating YuMe SDK Instance...");
        self.pYuMeSDK = [YuMeSDKInterface getYuMeSdkHandle];
    }
    return self;
}

- (void)dealloc {
    [self deInitialize];
}

- (void)initialize {
    self.pYuMeSDK = nil;
    self.bAdPlaying = NO;
    self.settings = nil;
    self.yViewController = nil;
}

- (void)deInitialize {
    self.pYuMeSDK = nil;
    self.settings = nil;
    self.yViewController = nil;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/*   INTERFACE (YuMeAppDelegate) TO BE IMPLEMENTED BY THE PUBLISHER APPLICATION FOR USE BY YUME SDK     */
//////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Listener that receives various ad events from YuMe SDK.
 * Used by the SDK to notify the application that the indicated ad event has occurred.
 * @param eAdType Ad type requested by the application that the event is related to.
 * @param eAdEvent The Ad event notified to the application.
 * @param eAdStatus The Ad status notified to the application.
 */
- (void)yumeEventListener:(YuMeAdType)eAdType adEvent:(YuMeAdEvent)eAdEvent adStatus:(YuMeAdStatus)eAdStatus {
    NSString *adEventStr = [YuMeAppUtils getAdEventStr:eAdEvent];
    NSString *adTypeStr = [YuMeAppUtils getAdTypeStr:eAdType];
    NSString *adStatusStr = [YuMeAppUtils getAdStatusStr:eAdStatus];

    NSLog(@"%@, Ad Status: %@ (%@)", adEventStr, adStatusStr, adTypeStr);
    
    NSString *dispAdStatusStr = ([adStatusStr isEqualToString:@"NONE"] ? @"" : [NSString stringWithFormat:@" (%@)", adStatusStr]);
    NSString *dispAdTypeStr = ([adTypeStr isEqualToString:@"NONE"] ? @"" : [NSString stringWithFormat:@" (%@)", adTypeStr]);
    NSString *toastText = [NSString stringWithFormat:@"%@%@%@", adEventStr, dispAdStatusStr, dispAdTypeStr];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"yumeEventListener" object:adEventStr];

    switch (eAdEvent) {
        case YuMeAdEventInitSuccess:
            [YuMeAppUtils displayToast:@"Initialization Successful." logToConsole:NO];
            break;
        case YuMeAdEventInitFailed:
            [YuMeAppUtils displayToast:@"Initialization Failed." logToConsole:NO];
            break;
        case YuMeAdEventAdReadyToPlay: {
            if(![toastText isEqualToString:@""]) {
                [YuMeAppUtils displayToast:toastText logToConsole:NO];
            }
            break;
        }
        case YuMeAdEventAdNotReady: {
            self.bAdPlaying = NO;
            if(![toastText isEqualToString:@""]) {
                [YuMeAppUtils displayToast:toastText logToConsole:NO];
            }
            break;
        }
        case YuMeAdEventAdPlaying: {
            if(![toastText isEqualToString:@""]) {
                [YuMeAppUtils displayToast:toastText logToConsole:NO];
            }
            [self.yViewController showAdScreenMenuButton];
            self.bAdPlaying = YES;
            break;
        }
        case YuMeAdEventAdCompleted: {
            if(![toastText isEqualToString:@""]) {
                [YuMeAppUtils displayToast:toastText logToConsole:NO];
            }
            self.bAdPlaying = NO;
            [self.yViewController adCompleted];
            break;
        }
        case YuMeAdEventAdClicked: {
            if(![toastText isEqualToString:@""]) {
                [YuMeAppUtils displayToast:toastText logToConsole:NO];
            }
            break;
        }
        case YuMeAdEventAdStopped: {
            if(![toastText isEqualToString:@""]) {
                [YuMeAppUtils displayToast:toastText logToConsole:NO];
            }
            self.bAdPlaying = NO;
            [self.yViewController adCompleted];
            break;
        }
        case YuMeAdEventNone:
        default:
            break;
    }
}

/**
 * Gets the AdView Info.
 * Used by the SDK to get the AdView Info from the application.
 * @return The AdView Info object.
 */
- (YuMeAdViewInfo *)yumeGetAdViewInfo {
    if(!self.settings.bSendAdViewInfo)
        return nil;
    
    CGRect adView = CGRectZero;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
        adView = self.settings.adRectPortrait;
    else
        adView = self.settings.adRectLandscape;
    
    YuMeAdViewInfo *adViewInfo = [[YuMeAdViewInfo alloc] init];
    adViewInfo.width = adView.size.width;
    adViewInfo.height = adView.size.height;
    adViewInfo.left = adView.origin.x;
    adViewInfo.top = adView.origin.y;
    
    return adViewInfo;
}

/**
 * Gets the updated QS parameters.
 * Used by SDK to get the recently updated qs params from the application.
 * For eg: App can send the latest lat and lon through this method for use by SDK.
 * @return The set of key value pairs delimited by '&'.
 */
- (NSString *)yumeGetUpdatedQSParams {
    NSString *pQSParams = @""; // @"lat=20.06575&lon=80.067585&age=35&yob1=1985&xaxis=51&yaxis=42&zaxis=33&education=B.E (ECE)&state=TamilNadu&tags=tag1,tag2&exclude_placements=2000";
    return pQSParams;
}

/** Internal functions that interfaces with YuMe SDK APIs */
/**
 * Initializes the YuMe SDK.
 * @param pAdParams The ad params object to be used for Initialization, in case the ad config parameters cannot be fetched from server.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeInit:(YuMeAdParams *)pAdParams {
    if (self.pYuMeSDK) {
        BOOL bResult = NO;
        NSError *pError = nil;
        @try {
            bResult = [self.pYuMeSDK yumeSdkInit:pAdParams appDelegate:self errorInfo:&pError];
        } @catch (NSException *exception) {
            NSLog(@"<Exception>: %@", exception.description);
            return NO;
        }
        if (!bResult) {
            if(pError)
                [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        } else {
            //[YuMeAppUtils displayToast:@"Initialization Successful." logToConsole:YES];
        }
        return bResult;
    }
    return NO;
}

/**
 * Modifies the Ad Parameters set in YuMe SDK.
 * @param pAdParams The ad params object with modified values.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeModifyParams:(YuMeAdParams *)pAdParams {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkModifyAdParams:pAdParams errorInfo:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:@"Modify Params Successful." logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Gets the Ad Parameters set in YuMe SDK.
 * @return The Ad Params object set in YuMe SDK.
 */
- (YuMeAdParams *)yumeGetAdParams {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        YuMeAdParams *adParams = [self.pYuMeSDK yumeSdkGetAdParams:&pError];
        if( (!adParams) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        return adParams;
    }
    return nil;
}

/**
 * De-Initializes the YuMe SDK.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeDeInit {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkDeInit:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:@"De-Initialization Successful." logToConsole:YES];
        return bResult;
    }
    return NO;
}

/*
 * Requests YuMe SDK to display an ad.
 * @param pAdView The ad View within which the ad should be displayed.
 * @param pAdViewController The ad View Controller within which Ad View is present.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeShowAd:(UIView *)pAdView viewController:(UIViewController *)pAdViewController {
    if (self.pYuMeSDK) {
        if([self yumeIsAdAvailable]) {
            NSError *pError = nil;
            BOOL bResult = [self.pYuMeSDK yumeSdkShowAd:pAdView viewController:pAdViewController errorInfo:&pError];
            if ( (!bResult) && (pError) )
                [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
            return bResult;
        }
    }
    return NO;
}

/**
 * Stops the playback of currently playing ad.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeStopAd {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkStopAd:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Gets the YuMe SDK Version.
 * @return The YuMe SDK Version.
 */
- (NSString *)yumeGetVersion {
    NSString *sdkVersion = [YuMeSDKInterface getYuMeSdkVersion];
    return sdkVersion;
}

/**
 * Clears the cookies created by YuMe SDK.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeClearCookies {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkClearCookies:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:@"Clear Cookies Successful." logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Enables / disables Control Bar toggle for next gen ads.
 * @param bEnableCBToggle The enable-cb-toggle flag to be set in SDK.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeSetControlBarToggle:(BOOL)bEnableCBToggle {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkSetControlBarToggle:bEnableCBToggle errorInfo:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:[@"" stringByAppendingString:(bEnableCBToggle ? @"Enable Control Bar Toggle Successful." : @"Disable Control Bar Toggle Successful.")] logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Notifies events like 'YuMeEventTypeAdViewResized' to SDK.
 * @param eEventType The event type to be notified.
 */
- (void)yumeHandleEvent:(YuMeEventType)eEventType {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkHandleEvent:eEventType errorInfo:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
    }
}

/**
 * Sets the log level in YuMe SDK.
 * @param logLevel The log level that needs to be set.
 */
- (void)yumeSetLogLevel:(YuMeLogLevel)logLevel {
    if (self.pYuMeSDK)
        [self.pYuMeSDK yumeSdkSetLogLevel:logLevel];
}

//Prefetch-specific
/**
 * Checks if an ad is available for playing in YuMe SDK.
 * @return YES, if an ad is available for playing, else NO.
 */
- (BOOL)yumeIsAdAvailable {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bAdAvailable = [self.pYuMeSDK yumeSdkIsAdAvailable:&pError];
        if( (!bAdAvailable) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        return bAdAvailable;
    }
    return NO;
}

/**
 * Prefetches an ad.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeInitAd {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkInitAd:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Enables / disables caching support.
 * @param bEnableCache The enable-caching flag to be set in SDK.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeSetCacheEnabled:(BOOL)bEnableCache {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkSetCacheEnabled:bEnableCache errorInfo:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:[@"" stringByAppendingString:(bEnableCache ? @"Enable Caching Successful." : @"Disable Caching Successful.")] logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Checks whether asset caching is enabled.
 * @return The enable-caching flag received from SDK, else NO.
 */
- (BOOL)yumeIsCacheEnabled {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bCacheEnabled = [self.pYuMeSDK yumeSdkIsCacheEnabled:&pError];
        if(pError)
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:[@"" stringByAppendingString:(bCacheEnabled ? @"Caching enabled." : @"Caching disabled.")] logToConsole:YES];
        return bCacheEnabled;
    }
    return NO;
}

/**
 * Enables / disables auto prefetch mode.
 * @param bAutoPrefetch The auto-prefetch enabled flag to be set in SDK.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeSetAutoPrefetch:(BOOL)bAutoPrefetch {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkSetAutoPrefetch:bAutoPrefetch errorInfo:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:[@"" stringByAppendingString:(bAutoPrefetch ? @"Enable Auto Prefetching Successful." : @"Disable Auto Prefetching Successful.")] logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Checks whether auto prefetch is enabled.
 * @return The auto-prefetch enabled flag received from SDK, else NO.
 */
- (BOOL)yumeIsAutoPrefetchEnabled {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bAutoPrefetchEnabled = [self.pYuMeSDK yumeSdkIsAutoPrefetchEnabled:&pError];
        if (pError)
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:[@"" stringByAppendingString:(bAutoPrefetchEnabled ? @"Auto Prefetch enabled." : @"Auto Prefetch disabled.")] logToConsole:YES];
        return bAutoPrefetchEnabled;
    }
    return NO;
}

/**
 * Clears the asset cache.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeClearCache {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkClearCache:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        else
            [YuMeAppUtils displayToast:@"Clear Cache Successful." logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Pauses the currently active downloads.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumePauseDownload {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkPauseDownload:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        //else
            //[YuMeAppUtils displayToast:@"Pause Download Successful."];
        return bResult;
    }
    return NO;
}

/**
 * Resumes the paused downloads.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeResumeDownload {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkResumeDownload:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Aborts the currently active / paused downloads.
 * @return YES, if the operation is successful, else NO.
 */
- (BOOL)yumeAbortDownload {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        BOOL bResult = [self.pYuMeSDK yumeSdkAbortDownload:&pError];
        if ( (!bResult) && (pError) )
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        return bResult;
    }
    return NO;
}

/**
 * Gets the current download status.
 * @return The download status received from the SDK, else @"NONE".
 */
- (NSString *)yumeGetDownloadStatus {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        YuMeDownloadStatus eDownloadStatus = [self.pYuMeSDK yumeSdkGetDownloadStatus:&pError];
        if (pError) {
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
        } else {
            return [YuMeAppUtils getDownloadStatusStr:eDownloadStatus];
        }
    }
    return @"NONE";
}

/**
 * Gets the download percentage completed so far, for the currently active Ad.
 * @return The downloaded percentage received from the SDK, else 0.0f.
 */
- (float)yumeGetDownloadedPercentage {
    if (self.pYuMeSDK) {
        NSError *pError = nil;
        float downloadedPercent = [self.pYuMeSDK yumeSdkGetDownloadedPercentage:&pError];
        if (pError) {
            [YuMeAppUtils displayToast:[YuMeAppUtils getErrDesc:pError] logToConsole:YES];
            return -0.1f;
        }
        return downloadedPercent;
    }
    return 0.0f;
}

//Internal functions

- (YuMeSDKInterface *)getYuMeSDKHandle {
    return self.pYuMeSDK;
}

- (void)orientationChange:(CGRect)frame {
    //if(videoController)
    //[videoController orientationChange:frame];
}

@end //@implementation YuMeInterface
