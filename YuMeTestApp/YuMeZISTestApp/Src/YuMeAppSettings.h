//
//  YuMeAppSettings.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuMeTypes.h"

@interface YuMeAppSettings : NSObject {

}
@property (nonatomic, retain) NSString *adServerUrl;
@property (nonatomic, retain) NSString *domainId;
@property (nonatomic, retain) NSString *additionalParams;
@property (nonatomic, retain) NSString *adTimeOut;
@property (nonatomic, retain) NSString *videoTimeOut;
@property (nonatomic) BOOL bHighBitrateVideo;
@property (nonatomic, retain) NSString *videoAdFormatsArr;
@property (nonatomic) BOOL bAutoDetectNetwork;
@property (nonatomic) BOOL bEnableCaching;
@property (nonatomic) BOOL bEnableAutoPrefetch;
@property (nonatomic, retain) NSString *storageSize;
@property (nonatomic) BOOL bEnableCBToggle;
@property (nonatomic) BOOL bOverrideOrientation;
@property (nonatomic) BOOL bEnableTTC;
@property (nonatomic, assign) YuMePlayType ePlayType;
@property (nonatomic, retain) NSString *logLevel;
@property (nonatomic, assign) YuMeSdkUsageMode eSdkUsageMode;
@property (nonatomic, assign) YuMeAdType eAdType;

//app-only settings
@property (nonatomic) BOOL bSupportPreroll;
@property (nonatomic) BOOL bSupportMidroll;
@property (nonatomic) BOOL bSupportPostroll;
@property (nonatomic) BOOL bEnableAdOrientation;
@property (nonatomic) BOOL bSendAdViewInfo;
@property (nonatomic) CGRect adRectPortrait;
@property (nonatomic) CGRect adRectLandscape;
@property (nonatomic) BOOL bEnableFSMode;

+ (NSString *)boolToString:(BOOL)boolVal;

+ (BOOL)stringToBool:(NSString *)strVal;

+ (NSString *)floatToString:(float)floatVal;

+ (YuMeAppSettings *)readSettings;

+ (void)saveSettings:(YuMeAppSettings *)settings;

@end //@interface YuMeAppSettings
