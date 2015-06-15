//
//  YuMeUnitTestUtils.h
//  YuMeZISTestApp
//
//  Created by Bharath Ramakrishnan on 4/1/15.
//  Copyright (c) 2015 YuMe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuMeAppSettings.h"
#import "YuMeInterface.h"
#import "YuMeSDKInterface.h"
#import "YuMeMPlayerController.h"

#define kTIME_OUT 60
#define JSS_RESOURCE_PATH_DIR @"yume/jss_resources"
#define YUME_UNITTEST_ASSETS_PATH @"/yume/unittest/";

#define EMPTY_INVALID_URL               @"http://172.18.8.198/~senthil/utest/iempty_200"
#define EMPTY_VALID_URL                 @"http://172.18.8.198/~senthil/utest/vempty_200"
#define FILLED_URL                      @"http://172.18.8.198/~senthil/utest/v_200"
#define FILLED_404_URL                  @"http://172.18.8.198/~senthil/utest/v_404/"
#define FILLED_INVALID_URL              @"http://172.18.8.198/~senthil/utest/ifilled_200"
#define FILLED_MISSING_ASSETS_URL       @"http://172.18.8.198/~senthil/utest/m_200"
#define FILLED_CREATIVERETRYATTEMPTS    @"http://172.18.8.198/~senthil/utest/v_404attempt"
#define FILLED_CREATIVERETRYINTERVAL    @"http://172.18.8.198/~senthil/utest/v_404retry"
#define FILLED_EXPIRATIONTIME           @"http://172.18.8.198/~senthil/utest/v_200expiry"
#define FILLED_PFCALLBACKINTERVAL       @"http://172.18.8.198/~senthil/utest/vempty_200callback"

static YuMeInterface *pYuMeInterface;
static YuMeMPlayerController *pYuMeMPlayerController;
static YuMeSDKInterface *pYuMeSDK;

typedef void(^completionHandler)(BOOL);

@interface YuMeUnitTestUtils : NSObject

+ (UIViewController *)topMostController;
+ (YuMeAppSettings *)getApplicationAdSettings;
+ (YuMeInterface *)getYuMeInterface;
+ (YuMeAdParams *)getApplicationYuMeAdParams;
+ (NSString *)getStringYuMeAdParms:(YuMeAdParams *)adParams;
+ (NSString *)getErrDesc:(NSError *)pError;
+ (void)deleteFile:(NSString *)fileName;
+ (void)getYuMeEventListenerEvent:(NSString *)adEvent completion:(completionHandler)completionBlock;
+ (void)receiveYuMeEventListener:(NSNotification *)notification;
+ (void)createConsoleLogFile:(NSString *)fileName;
+ (void)deleteConsoleLogFile:(NSString *)fileName;
+ (NSString *)readConsoleLogFile:(NSString *)fileName;
+ (NSString *)getConsoleLogFilePath:(NSString *)fileName;

@end
