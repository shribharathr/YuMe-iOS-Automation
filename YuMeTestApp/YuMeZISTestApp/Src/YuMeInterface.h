//
//  YuMeInterface.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuMeSDKInterface.h"
#import "YuMeTypes.h"
#import "YuMeAppSettings.h"
#import "YuMeViewController.h"

@protocol YuMeInterfaceDelegate

- (void)addToolBar;

- (void)adCompleted;

@end //@protocol YuMeInterfaceDelegate

@class YuMeViewController; //Forward Declaration

@interface YuMeInterface : NSObject <YuMeAppDelegate> {
    
    /* YuMe SDK Instance */
    //YuMeSDKInterface *pYuMeSDK;
}

/* Flag indicating if ad is playing or not */
@property (nonatomic, assign)BOOL bAdPlaying;

/* app settings object */
@property (nonatomic, retain)YuMeAppSettings *settings;

/* YuMeViewController instance */
@property (nonatomic, assign)YuMeViewController *yViewController;

/** Internal functions that interfaces with YuMe SDK APIs */
- (BOOL)yumeInit:(YuMeAdParams *)pAdParams;

- (BOOL)yumeModifyParams:(YuMeAdParams *)pAdParams;

- (YuMeAdParams *)yumeGetAdParams;

- (BOOL)yumeDeInit;

- (BOOL)yumeShowAd:(UIView *)pAdView viewController:(UIViewController *)pAdViewController;

- (BOOL)yumeStopAd;

- (NSString *)yumeGetVersion;

- (BOOL)yumeClearCookies;

- (BOOL)yumeSetControlBarToggle:(BOOL)bEnableCBToggle;

- (void)yumeHandleEvent:(YuMeEventType)eEventType;

- (void) yumeSetLogLevel:(YuMeLogLevel)logLevel;

//Prefetch-specific
- (BOOL)yumeIsAdAvailable;

- (BOOL)yumeInitAd;

- (BOOL)yumeSetCacheEnabled:(BOOL)bEnableCache;

- (BOOL)yumeIsCacheEnabled;

- (BOOL)yumeSetAutoPrefetch:(BOOL)bAutoPrefetch;

- (BOOL)yumeIsAutoPrefetchEnabled;

- (BOOL)yumeClearCache;

- (BOOL)yumePauseDownload;

- (BOOL)yumeResumeDownload;

- (BOOL)yumeAbortDownload;

- (NSString *)yumeGetDownloadStatus;

- (float)yumeGetDownloadedPercentage;

//Internal functions
- (YuMeSDKInterface *)getYuMeSDKHandle;

- (void)orientationChange:(CGRect)frame;

@end //@interface YuMeInterface
