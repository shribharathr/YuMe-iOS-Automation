//
//  YuMeAppUtils.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuMeTypes.h"
#import "YuMeAppConstants.h"


@interface YuMeAppUtils : NSObject {

}

/* static functions */
+ (NSBundle *)getIPhoneBundle;

+ (NSBundle *)getIPadBundle;

+ (NSBundle *)getNSBundle;

+ (BOOL)isIPad;

+ (NSInteger)getStatusBarHeight;

+ (CGSize)getMaxUsableScreenBoundsInPortrait;

+ (CGSize)getMaxUsableScreenBoundsInLandscape;

+ (CGRect)getMaxUsableCurrentScreenSize;

+ (BOOL)isPortrait:(CGRect)rect;

+ (BOOL)isViewControllerPortrait:(UIViewController *)vc;

+ (void)displayToast:(UIViewController *)vc toastMsg:(NSString *)toastMsg;

+ (void)displayToast:(NSString *)toastMsg logToConsole:(BOOL)bLogToConsole;

+ (void)attachViewToTopViewController:(UIView *)inputView;

+ (NSString *)getErrDesc:(NSError *)pError;

+ (CGRect)getCurrentScreenBoundsBasedOnOrientation;

+ (NSString *)getAdTypeStr:(YuMeAdType)adType;

+ (NSString *)getAdEventStr:(YuMeAdEvent)adEvent;

+ (NSString *)getAdStatusStr:(YuMeAdStatus)adStatus;

+ (NSString *)getSdkUsageModeStr:(YuMeSdkUsageMode)eSdkUsageMode;

+ (NSString *)getVideoAdFormatStr:(YuMeVideoAdFormat)eVideoAdFormat;

+ (NSString *)getPlayTypeStr:(YuMePlayType)ePlayType;

+ (NSString *)getDownloadStatusStr:(YuMeDownloadStatus)eDownloadStatus;

@end //@interface YuMeAppUtils
