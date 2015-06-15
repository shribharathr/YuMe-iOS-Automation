//
//  YuMeAppSettings.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeAppSettings.h"
#import "YuMeAppUtils.h"
#import "YuMeViewController.h"
#import "YuMeAppConstants.h"

static BOOL bIsSettingsModified = YES;

YuMeAppSettings *settings = nil;

@implementation YuMeAppSettings

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)dealloc {
    [self deInitialize];
}

- (void)initialize {
    self.adServerUrl = nil;
    self.domainId = nil;
    self.additionalParams = nil;
    self.adTimeOut = nil;
    self.videoTimeOut = nil;
    self.videoAdFormatsArr = nil;
    self.bHighBitrateVideo = NO;
    self.bAutoDetectNetwork = NO;
    self.bEnableCaching = NO;
    self.bEnableAutoPrefetch = NO;
    self.storageSize = nil;
    self.bEnableCBToggle = NO;
    self.bOverrideOrientation = NO;
    self.bEnableTTC = NO;
    self.ePlayType = YuMePlayTypeNone;
    self.eSdkUsageMode = YuMeSdkUsageModePrefetch;
    self.logLevel = nil;
    
    self.bSupportPreroll = NO;
    self.bSupportMidroll = NO;
    self.bSupportPostroll = NO;
    self.bEnableAdOrientation = YES;
    self.bSendAdViewInfo = YES;
    self.adRectPortrait = CGRectZero;
    self.adRectLandscape = CGRectZero;
    self.bEnableFSMode = YES;
    
    settings = nil;
}

- (void)deInitialize {
    self.adServerUrl = nil;
    self.domainId = nil;
    self.additionalParams = nil;
    self.adTimeOut = nil;
    self.videoTimeOut = nil;
    self.videoAdFormatsArr= nil;
    self.logLevel = nil;
    settings = nil;
}

+ (NSString *)boolToString:(BOOL)boolVal {
    return (boolVal ? @"1" : @"0");
}

+ (BOOL)stringToBool:(NSString *)strVal {
    strVal = [strVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([strVal isEqualToString:@"0"])
        return NO;
    return YES;
}

+ (NSString *)floatToString:(float)floatVal {
    return [[NSNumber numberWithFloat:floatVal] stringValue];
}

+ (YuMeAppSettings *)readSettings {
    BOOL bFirstReadAfterLaunch = NO;
    if (settings == nil) {
        settings = [[YuMeAppSettings alloc] init];
        bFirstReadAfterLaunch = YES;
    }
    
    NSDictionary *dictSettings = [NSDictionary dictionaryWithContentsOfFile:[self getConfigFilePath]];
    if (dictSettings != nil) {
        NSString *strVal = [dictSettings valueForKey:@"AdServerUrl"];
        settings.adServerUrl = (strVal ? strVal : YUME_DEFAULT_AD_SERVER_URL);
        
        strVal = [dictSettings valueForKey:@"DomainId"];
        settings.domainId = (strVal ? strVal : YUME_DEFAULT_DOMAIN);
        
        strVal = [dictSettings valueForKey:@"AdditionalParams"];
        settings.additionalParams = (strVal ? strVal : ([YuMeAppUtils isIPad] ? @"device=iPad" : @"device=iPhone"));
        
        strVal = [dictSettings valueForKey:@"AdTimeOut"];
        settings.adTimeOut = (strVal ? strVal : @"8");
        
        strVal = [dictSettings valueForKey:@"VideoTimeOut"];
        settings.videoTimeOut = (strVal ? strVal : @"8");
        
        strVal = [dictSettings valueForKey:@"UseHighBitrateVideo"];
        settings.bHighBitrateVideo = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"VideoFormatsPref"];
        settings.videoAdFormatsArr = (strVal ? strVal : @"HLS,MP4,MOV");
        
        strVal = [dictSettings valueForKey:@"AutoDetectNetwork"];
        settings.bAutoDetectNetwork = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"EnableCaching"];
        settings.bEnableCaching = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"EnableAutoPrefetch"];
        settings.bEnableAutoPrefetch = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"StorageSize"];
        settings.storageSize = (strVal ? strVal : @"5.0");
        
        strVal = [dictSettings valueForKey:@"EnableCBToggle"];
        settings.bEnableCBToggle = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"OverrideOrientation"];
        settings.bOverrideOrientation = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"EnableTTC"];
        settings.bEnableTTC = (strVal ? [self stringToBool:strVal] : YES);
        
        YuMePlayType aType = [[dictSettings valueForKey:@"PlayType"] intValue];
        settings.ePlayType = (aType ? aType : YuMePlayTypeNone);
        
        strVal = [dictSettings valueForKey:@"LogLevel"];
        settings.logLevel = (strVal ? strVal : @"4");
        
        YuMeSdkUsageMode eSdkUsageMode = [[dictSettings valueForKey:@"SdkUsageMode"] intValue];
        settings.eSdkUsageMode = eSdkUsageMode;
        
        strVal = [dictSettings valueForKey:@"SdkAdSlot"];
        NSInteger adSlt = strVal ? [strVal integerValue] : 1;
        settings.eAdType = (YuMeAdType)adSlt;
		      
        //app-specific settings
        strVal = [dictSettings valueForKey:@"SupportPreroll"];
        settings.bSupportPreroll = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"SupportMidroll"];
        settings.bSupportMidroll = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"SupportPostroll"];
        settings.bSupportPostroll = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"EnableAdOrientation"];
        settings.bEnableAdOrientation = (strVal ? [self stringToBool:strVal] : YES);
        
        strVal = [dictSettings valueForKey:@"SendAdViewInfo"];
        settings.bSendAdViewInfo = (strVal ? [self stringToBool:strVal] : YES);
        
        CGSize maxPValues = [YuMeAppUtils getMaxUsableScreenBoundsInPortrait];
        CGSize maxLValues = [YuMeAppUtils getMaxUsableScreenBoundsInLandscape];
        if(!bFirstReadAfterLaunch) {
            strVal = [dictSettings valueForKey:@"AdRectPortraitX"];
            float x = (strVal ? [strVal floatValue] : 0);
            
            strVal = [dictSettings valueForKey:@"AdRectPortraitY"];
            float y = (strVal ? [strVal floatValue] : 0);
            
            strVal = [dictSettings valueForKey:@"AdRectPortraitWidth"];
            float width = (strVal ? [strVal floatValue] : maxPValues.width);
            
            strVal = [dictSettings valueForKey:@"AdRectPortraitHeight"];
            float height = (strVal ? [strVal floatValue] : maxPValues.height);
            
            settings.adRectPortrait = CGRectMake(x, y, width, height);
            
            strVal = [dictSettings valueForKey:@"AdRectLandscapeX"];
            x = (strVal ? [strVal floatValue] : 0);
            
            strVal = [dictSettings valueForKey:@"AdRectLandscapeY"];
            y = (strVal ? [strVal floatValue] : 0);
            
            strVal = [dictSettings valueForKey:@"AdRectLandscapeWidth"];
            width = (strVal ? [strVal floatValue] : maxLValues.width);
            
            strVal = [dictSettings valueForKey:@"AdRectLandscapeHeight"];
            height = (strVal ? [strVal floatValue] : maxLValues.height);
            
            settings.adRectLandscape = CGRectMake(x, y, width, height);
        } else {
            settings.adRectPortrait = CGRectMake(0, 0, maxPValues.width, maxPValues.height);
            settings.adRectLandscape = CGRectMake(0, 0, maxLValues.width, maxLValues.height);
        }
        
        strVal = [dictSettings valueForKey:@"EnableFSMode"];
        settings.bEnableFSMode = (strVal ? [self stringToBool:strVal] : YES);
        
    } else { //Initial settings on first time app launch
        settings.adServerUrl = YUME_DEFAULT_AD_SERVER_URL;
        settings.domainId = YUME_DEFAULT_DOMAIN;
        settings.additionalParams = ([YuMeAppUtils isIPad] ? @"device=iPad" : @"device=iPhone");
        settings.adTimeOut = @"8";
        settings.videoTimeOut = @"8";
        settings.bHighBitrateVideo = YES;
        settings.videoAdFormatsArr = @"HLS,MP4,MOV";
        settings.bAutoDetectNetwork = YES;
        settings.bEnableCaching = YES;
        settings.bEnableAutoPrefetch = YES;
        settings.storageSize = @"5.0";
        settings.bEnableCBToggle = YES;
        settings.bOverrideOrientation = YES;
        settings.bEnableTTC = YES;
        settings.ePlayType = YuMePlayTypeNone;
        settings.logLevel = @"4";
        settings.eSdkUsageMode = YuMeSdkUsageModePrefetch;
        settings.eAdType = YuMeAdTypePreroll;
        
        settings.bSupportPreroll = YES;
        settings.bSupportMidroll = YES;
        settings.bSupportPostroll = YES;
        settings.bEnableAdOrientation = YES;
        settings.bSendAdViewInfo = YES;
        
        CGSize maxValues = [YuMeAppUtils getMaxUsableScreenBoundsInPortrait];
        settings.adRectPortrait = CGRectMake(0, 0, maxValues.width, maxValues.height);
        
        maxValues = [YuMeAppUtils getMaxUsableScreenBoundsInLandscape];
        settings.adRectLandscape = CGRectMake(0, 0, maxValues.width, maxValues.height);
        
        settings.bEnableFSMode = YES;
    }
    return settings;
}

+ (void)saveSettings:(YuMeAppSettings *)settings {
    NSMutableDictionary *dictSettings = [NSMutableDictionary dictionaryWithCapacity:20];
    
    [dictSettings setObject:(settings.adServerUrl ? settings.adServerUrl : @"") forKey:@"AdServerUrl"];
    [dictSettings setObject:(settings.domainId ? settings.domainId : @"") forKey:@"DomainId"];
    [dictSettings setObject:(settings.additionalParams ? settings.additionalParams : @"") forKey:@"AdditionalParams"];
    [dictSettings setObject:(settings.adTimeOut ? settings.adTimeOut : @"") forKey:@"AdTimeOut"];
    [dictSettings setObject:(settings.videoTimeOut ? settings.videoTimeOut : @"") forKey:@"VideoTimeOut"];
    [dictSettings setObject:[self boolToString:settings.bHighBitrateVideo] forKey:@"UseHighBitrateVideo"];
    [dictSettings setObject:(settings.videoAdFormatsArr ? settings.videoAdFormatsArr : @"") forKey:@"VideoFormatsPref"];
    [dictSettings setObject:[self boolToString:settings.bAutoDetectNetwork] forKey:@"AutoDetectNetwork"];
    [dictSettings setObject:[self boolToString:settings.bEnableCaching] forKey:@"EnableCaching"];
    [dictSettings setObject:[self boolToString:settings.bEnableAutoPrefetch] forKey:@"EnableAutoPrefetch"];
    [dictSettings setObject:(settings.storageSize ? settings.storageSize : @"") forKey:@"StorageSize"];
    [dictSettings setObject:[self boolToString:settings.bEnableCBToggle] forKey:@"EnableCBToggle"];
    [dictSettings setObject:[self boolToString:settings.bOverrideOrientation] forKey:@"OverrideOrientation"];
    [dictSettings setObject:[self boolToString:settings.bEnableTTC] forKey:@"EnableTTC"];
    [dictSettings setObject:[NSNumber numberWithInteger:settings.ePlayType] forKey:@"PlayType"];
    [dictSettings setObject:(settings.logLevel ? settings.logLevel : @"") forKey:@"LogLevel"];
    [dictSettings setObject:[NSNumber numberWithInteger:settings.eSdkUsageMode] forKey:@"SdkUsageMode"];
    [dictSettings setObject:[NSNumber numberWithInt:settings.eAdType] forKey:@"SdkAdSlot"];
    
    [dictSettings setObject:[self boolToString:settings.bSupportPreroll] forKey:@"SupportPreroll"];
    [dictSettings setObject:[self boolToString:settings.bSupportMidroll] forKey:@"SupportMidroll"];
    [dictSettings setObject:[self boolToString:settings.bSupportPostroll] forKey:@"SupportPostroll"];
    [dictSettings setObject:[self boolToString:settings.bEnableAdOrientation] forKey:@"EnableAdOrientation"];
    [dictSettings setObject:[self boolToString:settings.bSendAdViewInfo] forKey:@"SendAdViewInfo"];
    [dictSettings setObject:[self floatToString:settings.adRectPortrait.origin.x] forKey:@"AdRectPortraitX"];
    [dictSettings setObject:[self floatToString:settings.adRectPortrait.origin.y] forKey:@"AdRectPortraitY"];
    [dictSettings setObject:[self floatToString:settings.adRectPortrait.size.width] forKey:@"AdRectPortraitWidth"];
    [dictSettings setObject:[self floatToString:settings.adRectPortrait.size.height] forKey:@"AdRectPortraitHeight"];
    [dictSettings setObject:[self floatToString:settings.adRectLandscape.origin.x] forKey:@"AdRectLandscapeX"];
    [dictSettings setObject:[self floatToString:settings.adRectLandscape.origin.y] forKey:@"AdRectLandscapeY"];
    [dictSettings setObject:[self floatToString:settings.adRectLandscape.size.width] forKey:@"AdRectLandscapeWidth"];
    [dictSettings setObject:[self floatToString:settings.adRectLandscape.size.height] forKey:@"AdRectLandscapeHeight"];
    [dictSettings setObject:[self boolToString:settings.bEnableFSMode] forKey:@"EnableFSMode"];
    
    [dictSettings writeToFile:[self getConfigFilePath] atomically:YES];
    bIsSettingsModified = YES;
    
    YuMeInterface *yumeInterface = [YuMeViewController getYuMeInterface];
    if (yumeInterface) {
        [yumeInterface yumeSetLogLevel:[settings.logLevel intValue]];
    }
}

+ (NSString *)getConfigFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (!documentsDirectory) {
        NSLog(@"Documents directory not found.");
        return nil;
    }
    return [documentsDirectory stringByAppendingPathComponent:@"yume_config.txt"];
}

@end //@implementation YuMeAppSettings
