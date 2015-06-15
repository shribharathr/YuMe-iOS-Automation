//
//  YuMeAppUtils.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeAppUtils.h"
#import "YuMeToast.h"
#import "YuMeAppDelegate.h"
#import "YuMeLogViewController.h"
#import "YuMeAppSettings.h"
#import "YuMeAppConstants.h"

@implementation YuMeAppUtils

+ (NSBundle *)getIPhoneBundle {
	NSString *bundlePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"Resources-iPhone"];
	return [NSBundle bundleWithPath:bundlePath];
}

+ (NSBundle *)getIPadBundle {
	NSString *bundlePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"Resources-iPad"];
	return [NSBundle bundleWithPath:bundlePath];
}

+ (NSBundle *)getNSBundle {
	return [NSBundle mainBundle];
}

+ (NSBundle *)getNSBundle2 {
#ifdef __IPHONE_4_0
	return [self getIPhoneBundle];
#else //__IPHONE_4_0
	return [self getIPadBundle];
#endif //__IPHONE_4_0
}

+ (BOOL)isIPad {
	UIDevice *device = [UIDevice currentDevice];
	NSRange range = [device.model rangeOfString:@"ipad" options:NSCaseInsensitiveSearch];
	return (range.length > 0);
}

+ (CGRect)getDeviceScreenBounds {
    //NOTE 1: "mainScreen bounds" returns same width and height values (ignoring SB Height) irrespective of orientation except > iOS 8.0 devices
    //NOTE 2: In iPad 8.0 and above, "mainScreen nativeBounds" returns same width and height values (ignoring SB Height) irrespective of orientation
    //NOTE 3: In iPhone 8.0 and above, "mainScreen bounds" returns width and height values (ignoring SB Height) based on orientation and "mainScreen nativeBounds" returns actual retina-display based size.
    //NOTE 4: Status Bar Height not taken into account in this function as in some devices, the Status Bar gets automatically hidden when changing from Portrait to Landscape
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
#ifdef __IPHONE_8_0
    if (YUME_APP_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(YUME_APP_IOS_VERSION_8)) {
        if(YUME_APP_IS_DEVICE_IPAD == 1) { //iPad 8 and above
            NSLog(@"App::Getting nativeBounds for iPads (with iOS >= 8.0): Width: %f, Height: %f", screenBounds.size.width, screenBounds.size.height);
            screenBounds = [[UIScreen mainScreen] nativeBounds];
        } else { //iPhone 8 and above
            UIInterfaceOrientation currOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            if( (UIInterfaceOrientationIsPortrait(currOrientation)) || (currOrientation == UIDeviceOrientationUnknown) || (currOrientation == UIDeviceOrientationFaceUp) ||
               (currOrientation == UIDeviceOrientationFaceDown) ) { //Portrait
                NSLog(@"App::Getting Bounds Values for iPhones (with iOS >= 8.0): Width: %f, Height: %f", screenBounds.size.width, screenBounds.size.height);
                screenBounds = CGRectMake(screenBounds.origin.x, screenBounds.origin.y, screenBounds.size.width, screenBounds.size.height);
            } else { //Landscape
                NSLog(@"App::Reversing Bounds Values for iPhones (with iOS >= 8.0): Width: %f, Height: %f", screenBounds.size.width, screenBounds.size.height);
                screenBounds = CGRectMake(screenBounds.origin.x, screenBounds.origin.y, screenBounds.size.height, screenBounds.size.width); //width and height reversed
            }
        }
    }
#endif //__IPHONE_8_0
    return screenBounds;
}

/* Gets the status bar height, if present */
+ (NSInteger)getStatusBarHeight {
    if([[UIApplication sharedApplication] isStatusBarHidden])
        return 0;
    return YUME_APP_DEVICE_STATUS_BAR_HEIGHT;
}

+ (CGSize)getMaxUsableScreenBoundsInPortrait {
    CGRect screenBounds = [YuMeAppUtils getDeviceScreenBounds];
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    
    CGSize maxPSize = CGSizeZero;
    if([[UIApplication sharedApplication] isStatusBarHidden]) {
        maxPSize = CGSizeMake(width, height);
    } else {
        maxPSize = CGSizeMake(width, (height - YUME_APP_DEVICE_STATUS_BAR_HEIGHT));
    }
    return maxPSize;
}

+ (CGSize)getMaxUsableScreenBoundsInLandscape {
    CGRect screenBounds = [YuMeAppUtils getDeviceScreenBounds];
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    
    CGSize maxLSize = CGSizeZero;
    if([[UIApplication sharedApplication] isStatusBarHidden]) {
        maxLSize = CGSizeMake(height, width);
    } else {
        maxLSize = CGSizeMake(height, (width - YUME_APP_DEVICE_STATUS_BAR_HEIGHT));
    }
    return maxLSize;
}

+ (CGRect)getMaxUsableCurrentScreenSize {
    NSInteger sbHeight = [YuMeAppUtils getStatusBarHeight];
    CGRect currScreenBounds = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation];
    return CGRectMake(0, sbHeight, currScreenBounds.size.width, (currScreenBounds.size.height - sbHeight));
}

+ (CGRect)getCurrentScreenBoundsBasedOnOrientation {
    CGRect screenBounds = [self getDeviceScreenBounds];
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);

    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if( (UIInterfaceOrientationIsPortrait(interfaceOrientation)) || (interfaceOrientation == UIDeviceOrientationUnknown) || (interfaceOrientation == UIDeviceOrientationFaceUp) ||
       (interfaceOrientation == UIDeviceOrientationFaceDown) ) {
        screenBounds.size = CGSizeMake(width, height);
    } else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(height, width);
    }
    return screenBounds;
}

+ (BOOL)isPortrait:(CGRect)rect {
	UIDeviceOrientation currOrientation = [[UIDevice currentDevice] orientation];
	switch (currOrientation) {
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			return YES;
		case UIDeviceOrientationLandscapeLeft:
		case UIDeviceOrientationLandscapeRight:
			return NO;
		default:
			return (rect.size.height >= rect.size.width);
	}
}

+ (BOOL)isViewControllerPortrait:(UIViewController *)vc {
	return UIInterfaceOrientationIsPortrait(vc.interfaceOrientation);
}

+ (void)displayToast:(UIViewController *)vc toastMsg:(NSString *)toastMsg {
    /* get the current view controller */
    if(vc) {
        YuMeToast *tview = [[YuMeToast alloc] initWithText:toastMsg];
        [vc.view addSubview:tview];
        tview = nil;
    }
}

+ (void)displayToast:(NSString *)toastMsg logToConsole:(BOOL)bLogToConsole {
    [YuMeLogViewController writeLog:toastMsg logToConsole:bLogToConsole];
    
    /* get the current view controller and add the toast as a subview */
    NSInteger colonIndex = [toastMsg rangeOfString:@": " options:NSBackwardsSearch].location;
    colonIndex = (colonIndex != NSNotFound) ? (colonIndex + 2) : 0;
    
    YuMeToast *tView = [[YuMeToast alloc] initWithText:[toastMsg substringFromIndex:colonIndex]];
    [YuMeAppUtils attachViewToTopViewController:tView];
    tView = nil;
}

+ (UIViewController *)getModalRootViewController {
    UIViewController *rootViewController = [self getTopViewController:[[[UIApplication sharedApplication] keyWindow] rootViewController]];
    return rootViewController;
}

+ (UIViewController *)getTopViewController:(UIViewController *)rootViewController {
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self getTopViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self getTopViewController:presentedViewController];
}

+ (void)attachViewToTopViewController:(UIView *)inputView {
    UIViewController *rootViewController = [YuMeAppUtils getModalRootViewController];
    if(rootViewController) {
        [rootViewController.view addSubview:inputView];
        [rootViewController.view bringSubviewToFront:inputView];
    }
}

+ (NSString *)getErrDesc:(NSError *)pError {
	NSString *errStr = [[pError userInfo] valueForKey:NSLocalizedDescriptionKey];
	return errStr;
}

+ (NSString *)getAdTypeStr:(YuMeAdType)adType {
    switch (adType) {
        case YuMeAdTypePreroll:
            return @"PREROLL";
        case YuMeAdTypeMidroll:
            return @"MIDROLL";
        case YuMeAdTypePostroll:
            return @"POSTROLL";
        case YuMeAdTypeNone:
        default:
            return @"NONE";
    }
}

+ (NSString *)getAdEventStr:(YuMeAdEvent)adEvent {
    switch (adEvent) {
        case YuMeAdEventInitSuccess:
            return @"INIT_SUCCESS";
        case YuMeAdEventInitFailed:
            return @"INIT_FAILED";
        case YuMeAdEventAdReadyToPlay:
            return @"AD_READY_TO_PLAY";
        case YuMeAdEventAdNotReady:
            return @"AD_NOT_READY";
        case YuMeAdEventAdPlaying:
            return @"AD_PLAYING";
        case YuMeAdEventAdCompleted:
            return @"AD_COMPLETED";
        case YuMeAdEventAdClicked:
            return @"AD_CLICKED";
        case YuMeAdEventAdStopped:
            return @"AD_STOPPED";
        case YuMeAdEventNone:
        default:
            return @"NONE";
    }
}

+ (NSString *)getAdStatusStr:(YuMeAdStatus)adStatus {
    switch (adStatus) {
        case YuMeAdStatusRequestFailed:
            return @"REQUEST_FAILED";
        case YuMeAdStatusRequestTimedOut:
            return @"REQUEST_TIMED_OUT";
        case YuMeAdStatusPlaybackSuccess:
            return @"PLAYBACK_SUCCESS";
        case YuMeAdStatusPlaybackTimedOut:
            return @"PLAYBACK_TIMED_OUT";
        case YuMeAdStatusPlaybackFailed:
            return @"PLAYBACK_FAILED";
        case YuMeAdStatusPlaybackInterrupted:
            return @"PLAYBACK_INTERRUPTED";
        case YuMeAdStatusCachingFailed:
            return @"CACHING_FAILED";
        case YuMeAdStatusCachedAdExpired:
            return @"CACHED_AD_EXPIRED";
        case YuMeAdStatusEmptyAdInCache:
            return @"EMPTY_AD_IN_CACHE";
        case YuMeAdStatusCachingInProgress:
            return @"CACHING_IN_PROGRESS";
        case YuMeAdStatusNone:
        default:
            return @"NONE";
    }
}

+ (NSString *)getSdkUsageModeStr:(YuMeSdkUsageMode)eSdkUsageMode {
    switch (eSdkUsageMode) {
        case YuMeSdkUsageModeStreaming:
            return @"STREAMING";
        case YuMeSdkUsageModePrefetch:
            return @"PREFETCH";
        case YuMeSdkUsageModeNone:
        default:
            return @"NONE";
    }
}

+ (NSString *)getVideoAdFormatStr:(YuMeVideoAdFormat)eVideoAdFormat {
    switch (eVideoAdFormat) {
        case YuMeVideoAdFormatHLS:
            return @"HLS";
        case YuMeVideoAdFormatMP4:
            return @"MP4";
        case YuMeVideoAdFormatMOV:
            return @"MOV";
        default:
            return @"UNKNOWN";
    }
}

+ (NSString *)getPlayTypeStr:(YuMePlayType)ePlayType {
    switch (ePlayType) {
        case YuMePlayTypeAutoPlay:
            return @"AUTO_PLAY";
        case YuMePlayTypeClickToPlay:
            return @"CLICK_TO_PLAY";
        case YuMePlayTypeNone:
        default:
            return @"NONE";
    }
}

+ (NSString *)getDownloadStatusStr:(YuMeDownloadStatus)eDownloadStatus {
    switch (eDownloadStatus) {
        case YuMeDownloadStatusDownloadsInProgress:
            return @"IN_PROGRESS";
        case YuMeDownloadStatusDownloadsNotInProgress:
            return @"NOT_IN_PROGRESS";
        case YuMeDownloadStatusDownloadsPaused:
            return @"PAUSED";
        case YuMeDownloadStatusNone:
        default:
            return @"NONE";
    }
}

@end //@implementation YuMeAppUtils
