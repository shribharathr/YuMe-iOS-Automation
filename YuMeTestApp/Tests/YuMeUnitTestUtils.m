//
//  YuMeUnitTestUtils.m
//  YuMeZISTestApp
//
//  Created by Bharath Ramakrishnan on 4/1/15.
//  Copyright (c) 2015 YuMe. All rights reserved.
//

#import "YuMeUnitTestUtils.h"
#import "YuMeAppUtils.h"
#include <stdio.h>

BOOL bIsEventReceived = NO;
BOOL bIsEventMatch = NO;
NSCondition *waitForEventCondition;
NSString *waitForEventName;
NSString *responeEventName;
FILE *debugLogFile;
int stdout_dupfd;
int stderrSave;

@implementation YuMeUnitTestUtils

/*
 * Get the top most viewcontriller from appliation.
 */
+ (UIViewController *)topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

/*
 * Get the Test App Ad Settings object
 */
+ (YuMeAppSettings *)getApplicationAdSettings {
    YuMeAppSettings *pAppSettings = [[YuMeAppSettings alloc] init];
    return pAppSettings;
}

/*
 * Get the YuMeInterface object
 */
+ (YuMeInterface *)getYuMeInterface {
    UIStoryboard *sb = nil;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        sb = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:[NSBundle mainBundle]];
    } else {
        sb = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:[NSBundle mainBundle]];
    }
    
    YuMeViewController *pViewController = (YuMeViewController *)[sb instantiateViewControllerWithIdentifier:@"YuMeViewController"];
    [pViewController.view setNeedsDisplay];
    return [YuMeViewController getYuMeInterface];
}

/*
 * Get the Application YuMe Ad Params object
 */
+ (YuMeAdParams *)getApplicationYuMeAdParams {
    YuMeAppSettings *settings = [YuMeAppSettings readSettings];
    if (settings == nil) {
        return nil;
    }
    
    YuMeAdParams *params = [[YuMeAdParams alloc] init];
    params.pAdServerUrl = settings.adServerUrl;
    params.pDomainId = settings.domainId;
    params.pAdditionalParams = settings.additionalParams;
    params.adTimeout = [settings.adTimeOut intValue];
    params.videoTimeout = [settings.videoTimeOut intValue];
    params.bSupportHighBitRate = settings.bHighBitrateVideo;
    params.bSupportAutoNetworkDetect = settings.bAutoDetectNetwork;
    params.bEnableCBToggle = settings.bEnableCBToggle;
    params.ePlayType = settings.ePlayType;
    params.bOverrideOrientation = settings.bOverrideOrientation;
    params.bEnableTTC = settings.bEnableTTC;
    
    NSString *adTypes = settings.videoAdFormatsArr;
    NSArray *videoAdArray = [adTypes componentsSeparatedByString:@","];
    NSMutableArray *videoAdPriorityArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < videoAdArray.count; i++) {
        NSString *mimeType = [videoAdArray objectAtIndex:i];
        if([mimeType caseInsensitiveCompare:@"HLS"] == NSOrderedSame) {
            [videoAdPriorityArray addObject:[NSString stringWithFormat:@"%ld", (long)YuMeVideoAdFormatHLS]];
        } else if ([mimeType caseInsensitiveCompare:@"MP4"] == NSOrderedSame) {
            [videoAdPriorityArray addObject:[NSString stringWithFormat:@"%ld", (long)YuMeVideoAdFormatMP4]];
        } else if ([mimeType caseInsensitiveCompare:@"MOV"] == NSOrderedSame) {
            [videoAdPriorityArray addObject:[NSString stringWithFormat:@"%ld", (long)YuMeVideoAdFormatMOV]];
        }
    }
    params.pVideoAdFormatsPriorityList = videoAdPriorityArray;
    params.eSdkUsageMode = settings.eSdkUsageMode;
    params.eAdType = settings.eAdType;
    params.bEnableCaching = settings.bEnableCaching;
    params.bEnableAutoPrefetch = settings.bEnableAutoPrefetch;
    params.storageSize = [settings.storageSize floatValue];
    
    settings = nil;
    
    return params;
}

+ (NSString *)getStringYuMeAdParms:(YuMeAdParams *)adParams {
    NSString *paramText = nil;
    @try {
        paramText = [NSString stringWithFormat:@"adServerUrl: %@ \ndomainId: %@ \nadditionalParams: %@ \nadTimeout: %ld \nvideoTimeout: %ld \npVideoAdFormatsPriorityList: [%@] \nbSupportHighBitRate: %@ \nbSupportAutoNetworkDetect: %@ \nbEnableCaching: %@ \nbEnableAutoPrefetch: %@ \nstorageSize: %f \nbEnableCBToggle: %@ \nbOverrideOrientation: %@ \nbEnableTTC: %@ \nePlayType: %@ \neSdkUsageMode: %@ \neAdType: %@", adParams.pAdServerUrl, adParams.pDomainId, adParams.pAdditionalParams, (long)adParams.adTimeout, (long)adParams.videoTimeout, adParams.pVideoAdFormatsPriorityList, ((adParams.bSupportHighBitRate) ? @"YES" : @"NO"), ((adParams.bSupportAutoNetworkDetect) ? @"YES" : @"NO"), ((adParams.bEnableCaching) ? @"YES" : @"NO"), ((adParams.bEnableAutoPrefetch) ? @"YES" : @"NO"), (adParams.storageSize), ((adParams.bEnableCBToggle) ? @"YES" : @"NO"), ((adParams.bOverrideOrientation) ? @"YES" : @"NO"), ((adParams.bEnableTTC) ? @"YES" : @"NO"), [YuMeAppUtils getPlayTypeStr:(adParams.ePlayType)], [YuMeAppUtils getSdkUsageModeStr:adParams.eSdkUsageMode], [YuMeAppUtils getAdTypeStr:adParams.eAdType]];
    } @catch (NSException *exception) {
        // do nothing
    }
    return paramText;
}

/*
 * Get the NSError userInfo Object.
 */
+ (NSString *)getErrDesc:(NSError *)pError {
    NSString *errStr = [[pError userInfo] valueForKey:NSLocalizedDescriptionKey];
    return errStr;
}

+ (void)deleteFile:(NSString *)fileName {
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:JSS_RESOURCE_PATH_DIR];
    path = [path stringByAppendingPathComponent:fileName];
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            NSLog(@"Delete file error: %@", error);
        }
    }
}

+ (void)getYuMeEventListenerEvent:(NSString *)adEvent completion:(completionHandler)completionBlock {
    if (!adEvent) {
        return;
    }
    
    NSLog(@"** Waiting for Ad Status [ %@ ] Event Start **", adEvent);
    waitForEventName = adEvent;
    waitForEventCondition = [[NSCondition alloc] init];
    [waitForEventCondition lock];

    [YuMeUnitTestUtils startReceiverstatus];
    
    while (!bIsEventReceived) {
        [waitForEventCondition wait];
    }
    [waitForEventCondition unlock];
    
    //waitForEventCondition = nil;
    NSLog(@"** Waiting for Ad Status [ %@ ] Event End **", adEvent);
    completionBlock(bIsEventMatch);
}

+ (void)startReceiverstatus {
    bIsEventReceived = NO;

    // Add Receive observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveYuMeEventListener:) name:@"yumeEventListener" object:nil];
}

+ (void)receiveYuMeEventListener:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [waitForEventCondition lock];
    bIsEventReceived = YES;
    if ([[notification name] isEqualToString:@"yumeEventListener"]) {
        NSLog(@" ** [ %@ ] notification received from SDK **", notification.object);
        responeEventName = (NSString *)notification.object;
        
        NSArray *eventArray = [waitForEventName componentsSeparatedByString: @","];
        for (int i = 0; i < [eventArray count]; i++) {
            NSString *eventName = [eventArray objectAtIndex:i];
            if ([eventName isEqualToString:notification.object]) {
                bIsEventMatch = YES;
                break;
            } else {
                bIsEventMatch = NO;   // Error response
            }
        }
        
        [waitForEventCondition signal];
        [waitForEventCondition unlock];
    }
}

+ (void)createConsoleLogFile:(NSString *)fileName {
    
    NSString *testfileName = [fileName stringByReplacingOccurrencesOfString:@"test_" withString:@""];
    [YuMeUnitTestUtils deleteConsoleLogFile:testfileName];
    NSString *logFilePath = [YuMeUnitTestUtils getConsoleLogFilePath:testfileName];
    
    // Save stderr so it can be restored.
    stderrSave = dup(STDERR_FILENO);
    
    // Send stderr to our file
    debugLogFile = freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a", stderr);
}

+ (NSString *)readConsoleLogFile:(NSString *)fileName {
    NSString *testfileName = [fileName stringByReplacingOccurrencesOfString:@"test_" withString:@""];
    NSString *content = [NSString stringWithContentsOfFile:[YuMeUnitTestUtils getConsoleLogFilePath:testfileName]
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    
    // Flush before restoring stderr
    fflush(stderr);
    
    // Now restore stderr, so new output goes to console.
    dup2(stderrSave, STDERR_FILENO);
    close(stderrSave);
    
    return content;
}

+ (void)deleteConsoleLogFile:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [YuMeUnitTestUtils getConsoleLogFilePath:fileName];
    NSError *error;
    if ([fileManager fileExistsAtPath:filePath]){
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"Could not delete file : %@",[error localizedDescription]);
        }
    }
}

/*
 * Get the console log file path
 */
+ (NSString *)getConsoleLogFilePath:(NSString *)fileName {
    NSString *cachesFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [cachesFolder stringByAppendingPathComponent:fileName];
    return filePath;
}

@end
