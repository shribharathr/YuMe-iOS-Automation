//
//  YuMeAppConstants.h
//  YuMeiOSSDK
//
//  Created by Senthil on 11/20/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#ifndef YuMeAppConstants_h
#define YuMeAppConstants_h

/* Default Ad Server Url */
#define YUME_DEFAULT_AD_SERVER_URL                  @"http://shadow01.yumenetworks.com/"

/* Default Ad Server Domain */
#define YUME_DEFAULT_DOMAIN                         @"211EsvNSRHO"

/* Constant representing iOS Version 6.0 */
#define YUME_APP_IOS_VERSION_6                      @"6.0"

/* Constant representing iOS Version 7.0 */
#define YUME_APP_IOS_VERSION_7                      @"7.0"

/* Constant representing iOS Version 8.0 */
#define YUME_APP_IOS_VERSION_8                      @"8.0"

/* Flag to indicate if Presented View Controller needs to be passed as View Controller to the SDK */
#define YUME_APP_USE_PRESENTED_VIEWCONTROLLER       0

/* Flag to enable / disable hiding of Status Bar in iOS Devices < 7.x, 0 -> SB Show, 1 -> SB Hide */
#define YUME_APP_HIDE_DEVICE_STATUS_BAR_IN_LOWER_THAN_I0S_7  1

/* Toast Duration in seconds */
#define YUME_APP_TOAST_DURATION                     1.5

/* Device Status Bar Height */
#define YUME_APP_DEVICE_STATUS_BAR_HEIGHT           20

/* Macro to check if the Device under testing is an IPad */
#define YUME_APP_IS_DEVICE_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

/* System Versioning Preprocessor Macros */
#define YUME_APP_SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define YUME_APP_SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define YUME_APP_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define YUME_APP_SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define YUME_APP_SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

/* Macro for text alignment center */
#ifdef __IPHONE_6_0
#define YUME_TEXT_ALIGNMENT_CENTER NSTextAlignmentCenter
#else //__IPHONE_6_0
#define YUME_TEXT_ALIGNMENT_CENTER UITextAlignmentCenter
#endif //__IPHONE_6_0

#endif //YuMeAppConstants_h
