//
//  YuMeViewController.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/13/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeAppUtils.h"
#import "YuMeViewController.h"
#import "YuMeToast.h"
#import "YuMeAppDelegate.h"
#import "YuMeAppConstants.h"
#import "YuMePresentedViewController.h"

@interface YuMeViewController() <YuMePresentedViewControllerDelegate>  {
}
@property(nonatomic, retain) YuMeAppSettings *settings;
@property(nonatomic, retain) YuMePresentedViewController *presentedAdViewController;

@property(nonatomic, assign) YuMeMenuBtnType currPressedMenuBtnType;
@property(nonatomic, assign) BOOL bAdPlayingInStreamingMode;

@property(nonatomic, retain) YuMeVideoView *videoDisplayView; //Just a placeholder to store currently active VideoView
@property(nonatomic, retain) YuMeVideoView *contentView; //VideoView that displays only Content
@property(nonatomic, retain) YuMeVideoView *adAndContentView; //VideoView that displays both Ad and Content
@property(nonatomic, retain) UIView *adMaskView; //The ad mask view to be used when using smaller views - in FS views, it serves no purpose

/** no of contents to be played */
@property(nonatomic, assign) NSInteger contentCountTotal;

/** no of contents played */
@property(nonatomic, assign) NSInteger contentCountPlayed;

/* Flag to indicate if Ad and Content needs to be played in separate view or not  */
@property(nonatomic, assign) BOOL bUseSeparateViewForContent;

/* The current play state */
@property(nonatomic, assign) YuMeAppPlayState ePlayState;

/* The Timer for getting the Get Downloaded Percentage */
@property(nonatomic, assign) NSTimer *getDldPercentTimer;

/* The scroll view height */
@property (nonatomic) float homeScrollHeight;

/* Flag to indicate if ad view is resized to a smaller view during ad play */
@property(nonatomic, assign) BOOL bAdViewResizedSmaller;

@end //@interface YuMeViewController

@implementation YuMeViewController

/* The YuMeInterface instance */
static YuMeInterface *pYuMeInterface = nil;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [YuMeLogViewController createLogFile];
    
    self.contentCountPlayed = 0;
    self.contentCountTotal = 2;
    self.ePlayState = YuMeAppPlayStateNone;
    
    self.adAndContentView = [[YuMeVideoView alloc] initWithFrame:CGRectZero];
    self.adAndContentView.backgroundColor = [UIColor blackColor];
    self.adAndContentView.delegate = self;
    
    self.contentView = [[YuMeVideoView alloc] initWithFrame:CGRectZero];
    self.contentView.backgroundColor = [UIColor blackColor];
    self.contentView.delegate = self;
    
    self.adMaskView = [[UIView alloc] initWithFrame:CGRectZero];
    self.adMaskView.backgroundColor = [UIColor blackColor];
    
    self.presentedAdViewController = nil;
    self.bUseSeparateViewForContent = YES;
    self.bAdViewResizedSmaller = NO;
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    
    //hide the status bar in less than 7.0 devices
    [[UIApplication sharedApplication] setStatusBarHidden:(YUME_APP_HIDE_DEVICE_STATUS_BAR_IN_LOWER_THAN_I0S_7 ? YES : NO)];
    
    pYuMeInterface = [[YuMeInterface alloc] init];
    pYuMeInterface.yViewController = self;
    
    CGRect homeScreenBtnFrame = self.btnHomeScreenMenu.frame;
    self.btnHomeScreenMenu.frame = CGRectMake(homeScreenBtnFrame.origin.x, homeScreenBtnFrame.origin.y, 50, 50);
    
    //get the device screen size info
    //[self logDeviceScreenSizeInfo]; //just for testing
    
    //hide the download status related UI elements
    [self setDldPercentUIElementsVisibility:NO];
    
    self.bAdPlayingInStreamingMode = NO;
    
    //add the necessary observers
    [self addAppObservers];
    
    [self performSelectorOnMainThread:@selector(getAppSettings) withObject:nil waitUntilDone:NO];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    //Release any retained subviews of the main view.
    //remove the necessary observers
    [self removeAppObservers];
}

- (NSUInteger)supportedInterfaceOrientations {
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown; //supported orientations
}

/*
- (NSUInteger) supportedInterfaceOrientations {
#if YUME_ARMV6_COMPATIBILITY_ENABLED
    return UIInterfaceOrientationPortrait | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight | UIInterfaceOrientationPortraitUpsideDown; //supported orientations
#else //YUME_ARMV6_COMPATIBILITY_ENABLED
    //NSLog(@"In Root View Controller : supportedInterfaceOrientations");
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown; //supported orientations
#endif //YUME_ARMV6_COMPATIBILITY_ENABLED
}
*/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.homeScrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.homeScrollView.contentSize = contentRect.size;
    self.homeScrollHeight = contentRect.size.height;
    
    self.homeScrollView.frame = self.view.frame;
    [self.view addSubview:self.homeScrollView];
}

- (BOOL)shouldAutorotate {
    if (self.settings == nil) {
        [self resizeControls];
        return YES;
    }
    if (self.settings.bEnableAdOrientation) {
        [self resizeControls];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)shouldAutomaticallyForwardRotationMethods {
    return YES; //Default YES
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return YES; //Default YES
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (self.settings.bEnableAdOrientation) {
        [self resizeControls];
        return YES;
    } else {
        return NO;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self resizeControls];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //get the device screen size info
    //[self logDeviceScreenSizeInfo]; //just for testing
    
    [self resizeControls];
    
    CGRect mainViewRect = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation];
    self.homeScrollView.frame = CGRectMake(0, 0, mainViewRect.size.width, mainViewRect.size.height - 20);
    self.homeScrollView.contentSize = CGSizeMake(mainViewRect.size.width, self.homeScrollHeight);
    
    if (!pYuMeInterface.bAdPlaying) {
		[self.videoDisplayView orientationChanged];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deInitialize {
    self.adAndContentView = nil;
    self.contentView = nil;
    self.adMaskView = nil;
    self.presentedAdViewController = nil;
    [self stopDldPercenTimer];
}

- (void) dealloc {
    [self deInitialize];
}

#pragma App Internal functions
#pragma mark -

+ (YuMeInterface *) getYuMeInterface {
    return pYuMeInterface;
}

- (void)getAppSettings {
    if (self.settings == nil) {
        self.settings = [YuMeAppSettings readSettings];
        pYuMeInterface.settings = self.settings;
    }
}

- (IBAction)btnInitPressed:(UIButton *)sender {
    if(pYuMeInterface) {
        YuMeAdParams *params = [[YuMeAdParams alloc] init];
        params.pAdServerUrl = self.settings.adServerUrl;
  		params.pDomainId = self.settings.domainId;
		params.pAdditionalParams = self.settings.additionalParams;
		params.adTimeout = [self.settings.adTimeOut intValue];
		params.videoTimeout = [self.settings.videoTimeOut intValue];
        params.bSupportHighBitRate = self.settings.bHighBitrateVideo;
        
        NSString *adTypes = self.settings.videoAdFormatsArr;
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
        
        params.bSupportAutoNetworkDetect = self.settings.bAutoDetectNetwork;
        params.bEnableCaching = self.settings.bEnableCaching;
        params.bEnableAutoPrefetch = self.settings.bEnableAutoPrefetch;
        params.storageSize = [self.settings.storageSize floatValue];
        params.bEnableCBToggle = self.settings.bEnableCBToggle;
        params.bOverrideOrientation = self.settings.bOverrideOrientation;
        params.bEnableTTC = self.settings.bEnableTTC;
        params.ePlayType = self.settings.ePlayType;
        params.eSdkUsageMode = self.settings.eSdkUsageMode;
        params.eAdType = self.settings.eAdType;
        
#if 0
        //1st Gen BB
        params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"7avKjEjJe";
        params.pAdditionalParams = @"placement_id=71804&advertisement_id=7855";
        
        //1st Gen BB
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"211EsvNSRHO";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=4294";
        
        //2nd Gen BB
        params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"7avKjEjJe";
        params.pAdditionalParams = @"placement_id=71804&advertisement_id=8908";
        
        //Tap (I->V) (Forced Orientation)
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"211EsvNSRHO";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=7183";
        
        //Plain Video Ad
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1723yvALmFqE";
        params.pAdditionalParams = @"placement_id=71687&advertisement_id=10784";
        
        //1st Gen MC
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9323";
        
        //2nd Gen MC
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9326";
        
        //Tap (I->V)
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9327";
        
        //Tap (V->I)
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9522";
        
        //Tap (V->V)
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9520";
        
        //Swipe (I->V)
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9328";
        
        //Swipe (V->I)
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9519";
        
        //Swipe (V->V)
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9518";
        
        //Swipe (V->V) with Post Survey
        params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"7LypsvFpV";
        params.pAdditionalParams = @"placement_id=32430&advertisement_id=9867";
        
        //MRAID - Innovid
        params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"3679FjmiiOWJ";
        params.pAdditionalParams = @"placement_id=72497&advertisement_id=12906";
        
        //VPaid
        params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"3679FjmiiOWJ";
        params.pAdditionalParams = @"placement_id=72504&advertisement_id=12925";
        
        //MRAID - Telemetry
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"placement_id=71239&advertisement_id=10351";
        
        //Plain Image
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/plain-image/";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"";
        
        //Plain Image - 404
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/plain-image/404";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"";
        
        //Plain Image - Timeout
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/plain-image/timed-out";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"";
        
        //Plain Video
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/plain-video/";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"";
        
        //Plain Video - 404 (Didn't get error but timed out)
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/plain-video/404";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"";
        
        //Plain Video - Timeout
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/plain-video/timed-out";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"";
        
        //MRAID Telemetry - Inline
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/mraid-telemetry-inline";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"";
        
        //Ad Coverage
        //params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/ad_coverage";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"";
        
        //Preroll: Swipe (V->V) - With Pre and Post Surveys
        //Midroll: MRAID Telemetry - With Pre and Post Surveys
        //Postroll: VPAID - With Pre and Post Surveys
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/survey-pre-post";
        params.pDomainId = @"1639lzSeTNzO";
        params.pAdditionalParams = @"";
        
        //MRAID - 300 - Interstitial
        params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"3679FjmiiOWJ";
        params.pAdditionalParams = @"placement_id=72497&advertisement_id=12908";
        
        //VPaid - Ad 1
        //params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.5.6/";
        params.pDomainId = @"3679FjmiiOWJ";
        params.pAdditionalParams = @"placement_id=72504&advertisement_id=12925";
        
        //VPaid - Ad 2
        params.pAdServerUrl = @"http://dev01.yumenetworks.com/";
        params.pDomainId = @"3562LpBpgmDy";
        params.pAdditionalParams = @"placement_id=71992&advertisement_id=12519";
        
        //Gameloft
        params.pAdServerUrl = @"http://172.18.8.72/~senthil/zis/gameloft/";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"";
        
        //Gameloft
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"211EsvNSRHO";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=5479";
        
        //Plain-Image - No redirect
        params.pAdServerUrl = @"http://172.18.8.176/~bharath/utest/rvideo/";
        params.pDomainId = @"211EsvNSRHO";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=5479";
        
        //Plain-Image - Redirect
        //params.pAdServerUrl = @"http://172.18.8.68/2015/01jan/12jan_zis_html5/prefetch/unit_test/r_image/";
        //params.pAdServerUrl = @"http://172.18.8.72/~senthil/zis/pi-redirect/";
        params.pAdServerUrl = @"http://172.18.8.176/~bharath/utest/redirectImage/";
        params.pDomainId = @"211EsvNSRHO";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=5479";
        
        //IP Targeted ad
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"211WsxocCDr";
        params.pAdditionalParams = @"client_ip=141.241.128.11";
        
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        //params.pAdServerUrl = @"http://172.18.8.72/~senthil/15.1.3.6/roll/ad_coverage";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"";
        
        //Plain Image with Survey
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"211EsvNSRHO";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=9524";
        
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9522";
        
        //Forced Orientation
        //http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=1463xHTGXBBE&device=iPhone&placement_id=5571&advertisement_id=5417&version=v2
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=5417";
        
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"211EsvNSRHO";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=5418";
        
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=10947&advertisement_id=9326";
        
        //Forced Orientation - Tap
        //http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=1463xHTGXBBE&device=iPhone&placement_id=5571&advertisement_id=7183&version=v2
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=5571&advertisement_id=7183";
        
        //3rd Party Wrapper Ad
        //http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=1463xHTGXBBE&device=iPhone&version=v2&placement_id=70196&advertisement_id=9226
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1463xHTGXBBE";
        params.pAdditionalParams = @"placement_id=70196&advertisement_id=9226";
        
        //2nd Gen Mobile Connect- Bottom CB overlap issue
        //http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=1736DAhIYgKh&version=v2&placement_id=71744&advertisement_id=10828&pre_fetch=true
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1736DAhIYgKh";
        params.pAdditionalParams = @"placement_id=71744&advertisement_id=10828";
        
        //2nd Gen Mobile Connect- Ads By YuMe and Skip top-aligned
        //http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=1736DAhIYgKh&version=v2&placement_id=71737&advertisement_id=10818&pre_fetch=true
        params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1736DAhIYgKh";
        params.pAdditionalParams = @"placement_id=71737&advertisement_id=10818";
#endif //0
        
        //Swipe (V->V) with Post Survey
        /*params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"7LypsvFpV";
        params.pAdditionalParams = @"placement_id=32430&advertisement_id=9867";*/
        
        //2nd Gen BB
        /*params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"7avKjEjJe";
        params.pAdditionalParams = @"placement_id=71804&advertisement_id=8908";*/
        
        /*params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"1736DAhIYgKh";
        params.pAdditionalParams = @"";*/
        
        /* MRaid Ad with Survey */
        /*params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"3679FjmiiOWJ";
        params.pAdditionalParams = @"placement_id=72498&advertisement_id=12906";*/
        
        //Plain Image Ad with Survey
        /*params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"3677ztNLACRx";
        params.pAdditionalParams = @"placement_id=72507&advertisement_id=12923";*/
        
        //Swipe (V->V) with Post Survey
        /*params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"7LypsvFpV";
        params.pAdditionalParams = @"placement_id=32430&advertisement_id=9867";*/
        
        /*params.pAdServerUrl = @"http://qa-web-001.sjc1.yumenetworks.com/";
        params.pDomainId = @"3679UjYRBTPg";
        params.pAdditionalParams = @"placement_id=72531&advertisement_id=12945";*/
        
        //Gameloft
        //http://shadow01.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=1736DAhIYgKh&version=v2&placement_id=71739&advertisement_id=10824
        /*params.pAdServerUrl = @"http://shadow01.yumenetworks.com/";
        params.pDomainId = @"1736DAhIYgKh";
        params.pAdditionalParams = @"placement_id=71739&advertisement_id=10824";*/
        
        /*params.pAdServerUrl = @"http://shadow01.yumenetworks.com";
        params.pDomainId = @"1723yvALmFqE";
        params.pAdditionalParams = @"placement_id=71687&advertisement_id=10784";*/
        
        /*
         //Survey Playlists
         http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3679UjYRBTPg&xml_version=v3&placement_id=72531&advertisement_id=12945
         http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3679UjYRBTPg&xml_version=v3&placement_id=72531&advertisement_id=12944
         http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3679UjYRBTPg&xml_version=v3&placement_id=72531&advertisement_id=12943
         http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3679UjYRBTPg&xml_version=v3&placement_id=72531&advertisement_id=12946
        */
        
        /*
         1	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11943	//Inline -resize
         2	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11958	//Inline -Video
         3	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11953	//Interstetial – Web
         4	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11959	//Inline _small video
         5	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11954	//Inline -Click to web
         6	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11960	//Inline – square
         7	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11952	//Interstetial ad
         8	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11962	//Expand
         9	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11965	//all property
         10	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11970	//Telementry
         11	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11971	//Innovid -Inter
         12	http://qa-web-001.sjc1.yumenetworks.com/dynamic_preroll_playlist.vast2xml?domain=3517oBwjhqCx&xml_version=v3&placement_id=71425&advertisement_id=11972	//Innovid -Inline
         */
        
        /*if (params.bAutoPlayStreamingAds == false && params.eSdkUsageMode == YuMeSdkUsageModeStreaming) {
         pYuMeInterface.bUseOwnVideoPlayer = YES;
         }*/
        BOOL bResult = [pYuMeInterface yumeInit:params];
        //[pYuMeInterface orientationChange:self.view.frame];
        if (bResult) {
            YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
            [pYuMeInterface yumeSetLogLevel:[appSettings.logLevel intValue]];
            //Update the Auto Play Streaming tag
            [YuMeAppSettings saveSettings:appSettings];
        }
        params = nil;
    }
}

- (IBAction)btnInitAdPressed:(UIButton *)sender {
    [pYuMeInterface yumeInitAd];
}

- (IBAction)btnShowAdPressed:(UIButton *)sender {
    YuMeAdParams *adParams = nil;
    if(pYuMeInterface) {
        adParams = [pYuMeInterface yumeGetAdParams];
    }
    if ( (adParams) && (adParams.eSdkUsageMode == YuMeSdkUsageModeStreaming) ) {
        [self startStreamingAdPlay];
    } else { //Prefetch Mode
        [self showAd:YES];
    }
}

- (IBAction)btnModifyParamsPressed:(UIButton *)sender {
    if(pYuMeInterface) {
        YuMeAdParams *params = [self getAdParamsFromSettings];
        BOOL bResult = [pYuMeInterface yumeModifyParams:params];
        if (bResult) {
            //Update the Auto Play Streaming tag
            YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
            [YuMeAppSettings saveSettings:appSettings];
            [self performSelectorOnMainThread:@selector(getAppSettings) withObject:nil waitUntilDone:NO];
        }
        params = nil;
    }
}

- (IBAction)btnGetParamsPressed:(UIButton *)sender {
    if(pYuMeInterface) {
        YuMeAdParams *adParams = [pYuMeInterface yumeGetAdParams];
        if (!adParams)
            return;
        
        NSString *paramText = nil;
        @try {
            paramText = [NSString stringWithFormat:@"adServerUrl: %@ \ndomainId: %@ \nadditionalParams: %@ \nadTimeout: %ld \nvideoTimeout: %ld \npVideoAdFormatsPriorityList: [%@] \nbSupportHighBitRate: %@ \nbSupportAutoNetworkDetect: %@ \nbEnableCaching: %@ \nbEnableAutoPrefetch: %@ \nstorageSize: %f \nbEnableCBToggle: %@ \nbOverrideOrientation: %@ \nbEnableTTC: %@ \nePlayType: %@ \neSdkUsageMode: %@ \neAdType: %@", adParams.pAdServerUrl, adParams.pDomainId, adParams.pAdditionalParams, (long)adParams.adTimeout, (long)adParams.videoTimeout, [self getVideoFormatsPriorityListAsString:adParams.pVideoAdFormatsPriorityList], ((adParams.bSupportHighBitRate) ? @"YES" : @"NO"), ((adParams.bSupportAutoNetworkDetect) ? @"YES" : @"NO"), ((adParams.bEnableCaching) ? @"YES" : @"NO"), ((adParams.bEnableAutoPrefetch) ? @"YES" : @"NO"), (adParams.storageSize), ((adParams.bEnableCBToggle) ? @"YES" : @"NO"), ((adParams.bOverrideOrientation) ? @"YES" : @"NO"), ((adParams.bEnableTTC) ? @"YES" : @"NO"), [YuMeAppUtils getPlayTypeStr:(adParams.ePlayType)], [YuMeAppUtils getSdkUsageModeStr:adParams.eSdkUsageMode], [YuMeAppUtils getAdTypeStr:adParams.eAdType]];
        } @catch (NSException *exception) {
            // do nothing
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"YuMe Ad Params" message:paramText delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        //((UILabel *)[[alertView subviews] objectAtIndex:1]).textAlignment = UITextAlignmentLeft; //not working
        [alertView show];
        alertView = nil;
    }
}

- (IBAction)btnDeInitPressed:(UIButton *)sender {
    if(pYuMeInterface)
        [pYuMeInterface yumeDeInit];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (YuMeAdParams *)getAdParamsFromSettings {
    YuMeAdParams *params = [[YuMeAdParams alloc] init];
    params.pAdServerUrl = self.settings.adServerUrl;
    params.pDomainId = self.settings.domainId;
    params.pAdditionalParams = self.settings.additionalParams;
    params.adTimeout = [self.settings.adTimeOut intValue];
    params.videoTimeout = [self.settings.videoTimeOut intValue];
    params.bSupportHighBitRate = self.settings.bHighBitrateVideo;
    NSString *adTypes = self.settings.videoAdFormatsArr;
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
    params.bSupportAutoNetworkDetect = self.settings.bAutoDetectNetwork;
    params.bEnableCaching = self.settings.bEnableCaching;
    params.bEnableAutoPrefetch = self.settings.bEnableAutoPrefetch;
    params.storageSize = [self.settings.storageSize floatValue];
    params.bEnableCBToggle = self.settings.bEnableCBToggle;
    params.bOverrideOrientation = self.settings.bOverrideOrientation;
    params.bEnableTTC = self.settings.bEnableTTC;
    params.ePlayType = self.settings.ePlayType;
    params.eSdkUsageMode = self.settings.eSdkUsageMode;
    params.eAdType = self.settings.eAdType;
    
    return params;
}

/**
 * Gets the supported video formats in String format.
 */
- (NSString *) getVideoFormatsPriorityListAsString:(NSMutableArray *)pVideoAdFormatsPriorityList {
    if( (pVideoAdFormatsPriorityList == nil) || ([pVideoAdFormatsPriorityList count] == 0) ) {
        return (@"NONE.");
    } else {
        NSUInteger arrSize = [pVideoAdFormatsPriorityList count];
        NSString *videoFormats = @"";
        for (NSUInteger i = 0; i < arrSize; i++) {
            NSInteger videoFormatVal = [[pVideoAdFormatsPriorityList objectAtIndex:i] intValue];
            
            videoFormats = [videoFormats stringByAppendingString:[YuMeAppUtils getVideoAdFormatStr:(YuMeVideoAdFormat)videoFormatVal]];
            if(i < (arrSize - 1)) {
                videoFormats = [videoFormats stringByAppendingString:@", "];
            }
        }
        return videoFormats;
    }
}

- (void)presentAdViewController {
    [self presentViewController:self.presentedAdViewController animated:NO completion:^() {
        NSLog(@"Presented Roll View Controller in Application: %@", self.presentedAdViewController);
    }];
}

- (void)resizeControls {
    CGRect mainViewRect = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation];
    if (self.adMaskView) {
        self.adMaskView.frame = CGRectMake(0, 0, mainViewRect.size.width, mainViewRect.size.height);
    }
    if (self.videoDisplayView) {
        if(self.settings.bEnableFSMode) {//FS Mode Enabled
            self.videoDisplayView.frame = [YuMeAppUtils getMaxUsableCurrentScreenSize];
        } else { //Non FS Mode - get the settings from Size Screen
            //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
            if (UIDeviceOrientationIsPortrait(orientation)) {
                self.videoDisplayView.frame = self.settings.adRectPortrait;
            } else {
                self.videoDisplayView.frame = self.settings.adRectLandscape;
            }
        }
    }
    if (self.btnAdScreenMenu) {
        self.btnAdScreenMenu.frame = CGRectMake(0, (mainViewRect.size.height / 2) - (self.btnAdScreenMenu.frame.size.height / 2), 50, 50);
    }
}

#pragma Ad and Content View
#pragma mark -
- (void)setAdView {
    if (self.bUseSeparateViewForContent) {
        self.videoDisplayView = self.contentView;
    } else {
        self.videoDisplayView = self.adAndContentView;
    }
    [self resizeControls];
}

- (void)showAdScreenMenuButton {
    if(self.btnAdScreenMenu == nil) {
        UIImage *buttonImage = [UIImage imageNamed:@"info.png"];
        self.btnAdScreenMenu = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.btnAdScreenMenu setImage:buttonImage forState:UIControlStateNormal];
        self.btnAdScreenMenu.frame = CGRectMake(0, 0, 50, 50);
        [self.btnAdScreenMenu addTarget:self action:@selector(adScreenMenuButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [YuMeAppUtils attachViewToTopViewController:(self.btnAdScreenMenu)];
    }
    [self resizeControls];
}

- (void)addMaskView {
    if (self.adMaskView == nil) {
        self.adMaskView = [[UIView alloc] initWithFrame:CGRectZero];
        self.adMaskView.backgroundColor = [UIColor blackColor];
    }
    [self.view addSubview:self.adMaskView];
}

- (void)showAdVideoView {
    [self addMaskView];
    [self.view addSubview:self.videoDisplayView];
    [self resizeControls];
}

- (void)showContentVideoView {
    if (self.bUseSeparateViewForContent) {
        self.videoDisplayView = self.contentView;
    } else {
        self.videoDisplayView = self.adAndContentView;
    }
    [self addMaskView];
    [self.view addSubview:self.videoDisplayView];
    [self resizeControls];
}

- (void)hideVideoView {
	if(self.videoDisplayView) {
        if (self.btnAdScreenMenu != nil) {
            [self.btnAdScreenMenu removeFromSuperview];
            //[_btnAdScreenMenu performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO]; //Bharath
           self.btnAdScreenMenu = nil;
        }
        if (self.adMaskView != nil) {
            [self.adMaskView removeFromSuperview];
        }
		[self.videoDisplayView removeFromSuperview];
	}
#if YUME_APP_USE_PRESENTED_VIEWCONTROLLER
    if(self.presentedAdViewController) {
        [self dismissViewControllerAnimated:YES completion:^() {
            NSLog(@"Dismissed Presented Roll View Controller in Application: %@", self.presentedAdViewController);
            self.presentedAdViewController = nil;
        }];
    }
#endif //YUME_APP_USE_PRESENTED_VIEWCONTROLLER
}

- (void)resizeAdView {
    if(self.videoDisplayView) {
        YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
        //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if (UIDeviceOrientationIsPortrait(orientation)) {
            //if(CGRectEqualToRect(self.videoDisplayView.frame, appSettings.adRectPortrait)) {
            if(!self.bAdViewResizedSmaller) {
                CGRect adView1 = appSettings.adRectPortrait;
                adView1.origin.x += 20;
                adView1.origin.y += 20;
                adView1.size.width -= 100;
                adView1.size.height -= 100;
                self.videoDisplayView.frame = adView1;
                self.bAdViewResizedSmaller = YES;
            } else {
                if(self.settings.bEnableFSMode) {//FS Mode Enabled
                    self.videoDisplayView.frame = [YuMeAppUtils getMaxUsableCurrentScreenSize];
                } else { //Non FS Mode - get the settings from Size Screen
                    self.videoDisplayView.frame = appSettings.adRectPortrait;
                }
                self.bAdViewResizedSmaller = NO;
            }
        } else {
            //if(CGRectEqualToRect(self.videoDisplayView.frame, appSettings.adRectLandscape)) {
            if(!self.bAdViewResizedSmaller) {
                CGRect adView1 = self.settings.adRectLandscape;
                adView1.origin.x += 20;
                adView1.origin.y += 20;
                adView1.size.width -= 100;
                adView1.size.height -= 100;
                self.videoDisplayView.frame = adView1;
                self.bAdViewResizedSmaller = YES;
            } else {
                if(self.settings.bEnableFSMode) {//FS Mode Enabled
                    self.videoDisplayView.frame = [YuMeAppUtils getMaxUsableCurrentScreenSize];
                } else { //Non FS Mode - get the settings from Size Screen
                    self.videoDisplayView.frame = appSettings.adRectLandscape;
                }
                self.bAdViewResizedSmaller = NO;
            }
        }
    }
}

////////////////////////////////////// MENU BUTTONS HANDLING CODE - BEGIN //////////////////////////////////////

- (IBAction)homeScreenMenuButtonPressed:(id)sender {
    self.currPressedMenuBtnType = YuMeMenuBtnTypeHomeScreenAPIs;
    
    if( (YUME_APP_IS_DEVICE_IPAD == 1) && (YUME_APP_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(YUME_APP_IOS_VERSION_8)) ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"YuMe SDK APIs"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"PauseDownload",
                                  @"ResumeDownload",
                                  @"AbortDownload",
                                  @"GetDownloadPercentage",
                                  @"ClearCache",
                                  @"ClearCookies",
                                  @"GetDownloadStatus",
                                  @"SetCacheEnabled",
                                  @"ResetCacheEnabled",
                                  @"IsCacheEnabled",
                                  @"SetAutoPrefetch",
                                  @"ResetAutoPrefetch",
                                  @"IsAutoPrefetchEnabled",
                                  @"SetControlBarToggle",
                                  @"ResetControlBarToggle",
                                  @"StopAd",
                                  @"HandleEvent(Resize)",
                                  nil];
        [alertView show];
        alertView = nil;
    } else {
        UIActionSheet *actionSheetView = [[UIActionSheet alloc] initWithTitle:@"YuMe SDK APIs"
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:@"Cancel"
                                                            otherButtonTitles:@"PauseDownload",
                                          @"ResumeDownload",
                                          @"AbortDownload",
                                          @"GetDownloadPercentage",
                                          @"ClearCache",
                                          @"ClearCookies",
                                          @"GetDownloadStatus",
                                          @"SetCacheEnabled",
                                          @"ResetCacheEnabled",
                                          @"IsCacheEnabled",
                                          @"SetAutoPrefetch",
                                          @"ResetAutoPrefetch",
                                          @"IsAutoPrefetchEnabled",
                                          @"SetControlBarToggle",
                                          @"ResetControlBarToggle",
                                          @"StopAd",
                                          @"HandleEvent(Resize)",
                                          nil];
        actionSheetView.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        [actionSheetView showInView:self.view];
        actionSheetView = nil;
    }
}

- (void)adScreenMenuButtonPressed:(id)sender {
    self.currPressedMenuBtnType = YuMeMenuBtnTypeAdScreenAPIs;
    
    if( (YUME_APP_IS_DEVICE_IPAD == 1) && (YUME_APP_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(YUME_APP_IOS_VERSION_8)) ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"YuMe SDK APIs"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"StopAd",
                                  @"InitAd",
                                  @"ShowAd",
                                  @"ClearCache",
                                  @"HandleEvent(Resize)",
                                  @"PauseDownload",
                                  @"DeInit",
                                  nil];
        [alertView show];
        alertView = nil;
    } else {
        UIActionSheet *actionSheetView = [[UIActionSheet alloc] initWithTitle:@"YuMe SDK APIs"
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:@"Cancel"
                                                            otherButtonTitles:@"StopAd",
                                          @"InitAd",
                                          @"ShowAd",
                                          @"ClearCache",
                                          @"HandleEvent(Resize)",
                                          @"PauseDownload",
                                          @"DeInit",
                                          nil];
        actionSheetView.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        [actionSheetView showInView:[[UIApplication sharedApplication].delegate window]];
        actionSheetView = nil;
    }
}

- (void)handleMenuButtonClick:(NSInteger)clickedButtonIndex {
    switch (self.currPressedMenuBtnType) {
        case YuMeMenuBtnTypeHomeScreenAPIs :
            [self handleHomeScreenAPIsMenuButtonClick:clickedButtonIndex];
            break;
        case YuMeMenuBtnTypeAdScreenAPIs:
            [self handleAdScreenAPIsMenuButtonClick:clickedButtonIndex];
            break;
        case YuMeMenuBtnTypeNone:
        default:
            break;
    }
}

- (void)handleHomeScreenAPIsMenuButtonClick:(NSInteger)clickedButtonIndex {
    switch (clickedButtonIndex) {
        case 1: {
            [pYuMeInterface yumePauseDownload];
            break;
        }
        case 2: {
            [pYuMeInterface yumeResumeDownload];
            break;
        }
        case 3: {
            [pYuMeInterface yumeAbortDownload];
            break;
        }
        case 4: {
            //[pYuMeInterface yumeGetDownloadedPercentage];
            [self showDownloadedPercentageInfo];
            break;
        }
        case 5: {
            [pYuMeInterface yumeClearCache];
            break;
        }
        case 6: {
            [pYuMeInterface yumeClearCookies];
            break;
        }
        case 7: {
            NSString *downloadStateString = [NSString stringWithFormat:@"Current Download state: %@", [pYuMeInterface yumeGetDownloadStatus]];
            if(![downloadStateString isEqualToString:@"NONE"])
                [YuMeAppUtils displayToast:downloadStateString logToConsole:YES];
            break;
        }
        case 8: {
            [pYuMeInterface yumeSetCacheEnabled:YES];
            YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
            appSettings.bEnableCaching = YES;
            [YuMeAppSettings saveSettings:appSettings];
            break;
        }
        case 9: {
            [pYuMeInterface yumeSetCacheEnabled:NO];
            YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
            appSettings.bEnableCaching = NO;
            [YuMeAppSettings saveSettings:appSettings];
            break;
        }
        case 10: {
            [pYuMeInterface yumeIsCacheEnabled];
            break;
        }
        case 11: {
            [pYuMeInterface yumeSetAutoPrefetch:YES];
            YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
            appSettings.bEnableAutoPrefetch = YES;
            [YuMeAppSettings saveSettings:appSettings];
            break;
        }
        case 12: {
            [pYuMeInterface yumeSetAutoPrefetch:NO];
            YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
            appSettings.bEnableAutoPrefetch = NO;
            [YuMeAppSettings saveSettings:appSettings];
            break;
        }
        case 13: {
            [pYuMeInterface yumeIsAutoPrefetchEnabled];
            break;
        }
        case 14: {
            [pYuMeInterface yumeSetControlBarToggle:YES];
            YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
            appSettings.bEnableCBToggle = YES;
            [YuMeAppSettings saveSettings:appSettings];
            break;
        }
        case 15: {
            [pYuMeInterface yumeSetControlBarToggle:NO];
            YuMeAppSettings *appSettings = [YuMeAppSettings readSettings];
            appSettings.bEnableCBToggle = NO;
            [YuMeAppSettings saveSettings:appSettings];
            break;
        }
        case 16: {
            [pYuMeInterface yumeStopAd];
            pYuMeInterface.bAdPlaying = NO;
            [self adCompleted];
            break;
        }
        case 17: {
            [pYuMeInterface yumeHandleEvent:YuMeEventTypeAdViewResized];
            break;
        }
        default:
            break;
    }
}

- (void)handleAdScreenAPIsMenuButtonClick:(NSInteger)clickedButtonIndex {
    switch (clickedButtonIndex) {
        case 1: {
            [pYuMeInterface yumeStopAd];
            /* Call adCompleted after some delay to allow YuMe SDK to clean-up its views */
            //[self performSelector:@selector(adCompleted) withObject:nil afterDelay:0.2];
            break;
        }
        case 2: {
            [pYuMeInterface yumeInitAd];
            break;
        }
        case 3: {
            [pYuMeInterface yumeShowAd:(self.videoDisplayView) viewController:self];
            break;
        }
        case 4: {
            [pYuMeInterface yumeClearCache];
            break;
        }
        case 5: {
            [self resizeAdView];
            [pYuMeInterface yumeHandleEvent:YuMeEventTypeAdViewResized];
            break;
        }
        case 6: {
            [pYuMeInterface yumePauseDownload];
            break;
        }
        case 7: {
            [pYuMeInterface yumeDeInit];
            pYuMeInterface.bAdPlaying = NO;
            [self adCompleted];
            break;
        }
        default:
            break;
    }
}

#pragma Alertview Delegate
#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self handleMenuButtonClick:buttonIndex];
}

#pragma ActionSheet Delegate
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self handleMenuButtonClick:buttonIndex];
}

////////////////////////////////////// MENU BUTTONS HANDLING CODE - END //////////////////////////////////////

- (void)startStreamingAdPlay {
    self.contentCountPlayed = 0;
    self.ePlayState = YuMeAppPlayStateNone;
    self.bAdPlayingInStreamingMode = NO;
    
    if (self.settings.bSupportPreroll) {
        [self makeStreamingAdRequest:YuMeAdTypePreroll];
    } else {
        [self playContent];
    }
}

- (void)makeStreamingAdRequestAfterDelay:(NSString *)adTypeStr {
    YuMeAdType eAdType = YuMeAdTypeNone;
    if([adTypeStr isEqualToString:@"Preroll"]) {
        eAdType = YuMeAdTypePreroll;
    } else if([adTypeStr isEqualToString:@"Midroll"]) {
        eAdType = YuMeAdTypeMidroll;
    } else if([adTypeStr isEqualToString:@"Postroll"]) {
        eAdType = YuMeAdTypePostroll;
    }
    [self makeStreamingAdRequest:eAdType];
}

- (void)makeStreamingAdRequest:(YuMeAdType)eAdType {
    NSString *adTypeStr = [YuMeAppUtils getAdTypeStr:eAdType];
    [YuMeLogViewController writeLog:[NSString stringWithFormat:@"Requesting a Streaming %@ Ad...", adTypeStr] logToConsole:YES];
    if (![self showAd:NO]) {
        [YuMeLogViewController writeLog:[NSString stringWithFormat:@"%@ Ad request failed.", adTypeStr] logToConsole:YES];
        return;
    }
    switch(eAdType) {
        case YuMeAdTypePreroll:
            self.ePlayState = YuMeAppPlayStateStreamingPreroll;
            break;
        case YuMeAdTypeMidroll:
            self.ePlayState = YuMeAppPlayStateStreamingMidroll;
            break;
        case YuMeAdTypePostroll:
            self.ePlayState = YuMeAppPlayStateStreamingPostroll;
            break;
        default:
            break;
    }
}

- (BOOL)showAd:(BOOL)bIsPrefetchReq {
    [self setAdView];
	[self showAdVideoView];
    
#if YUME_APP_USE_PRESENTED_VIEWCONTROLLER
    self.presentedAdViewController = [[YuMePresentedViewController alloc] init];
    self.presentedAdViewController.videoDisplayView = self.videoDisplayView;
    self.presentedAdViewController.delegate = self;
    [self.presentedAdViewController.view addSubview:self.videoDisplayView];
    [self presentViewController:self.presentedAdViewController animated:NO completion:^() {
        NSLog(@"Presented Roll View Controller in Application: %@", self.presentedAdViewController);
    }];
#endif //YUME_APP_USE_PRESENTED_VIEWCONTROLLER
    
    BOOL bResult = NO;
#if YUME_APP_USE_PRESENTED_VIEWCONTROLLER
    bResult = [pYuMeInterface yumeShowAd:self.videoDisplayView viewController:self.presentedAdViewController];
#else //YUME_APP_USE_PRESENTED_VIEWCONTROLLER
    bResult = [pYuMeInterface yumeShowAd:self.videoDisplayView viewController:self];
#endif //YUME_APP_USE_PRESENTED_VIEWCONTROLLER
    
    if (!bResult) {
        if (!pYuMeInterface.bAdPlaying) {
            [self hideVideoView];
            if(!bIsPrefetchReq) {
                [self playContent];
            }
        }
    } else {
        if(!bIsPrefetchReq) {
            [self setAdPlayingInStreamingModeFlag];
        }
    }
	return bResult;
}

- (void)adCompleted {
    self.bAdViewResizedSmaller = NO;
    
    [self hideVideoView];
    
    if(self.ePlayState == YuMeAppPlayStateStreamingPostroll) {
        [self modifyAdTypeInSdk:YuMeAdTypePreroll];
    }
    self.ePlayState = YuMeAppPlayStateNone;
    
    if (self.bAdPlayingInStreamingMode) {
        [self performSelectorOnMainThread:@selector(playContent) withObject:nil waitUntilDone:NO];
        //[self performSelector:@selector(playContent) withObject:nil afterDelay:1.0];
    }
}

- (void) setAdPlayingInStreamingModeFlag {
    BOOL bAutoPlayStreamingAds = YES;
    YuMeSdkUsageMode eUsageMode = YuMeSdkUsageModeNone;
    YuMeAdParams *adParams = [pYuMeInterface yumeGetAdParams];
    if(adParams) {
        eUsageMode = adParams.eSdkUsageMode;
    }
    if( (bAutoPlayStreamingAds) && (eUsageMode == YuMeSdkUsageModeStreaming) ) {
        self.bAdPlayingInStreamingMode = YES;
    }
}

- (void)modifyAdTypeInSdk:(YuMeAdType)eAdType {
    if(eAdType == YuMeAdTypeNone)
        return;
    YuMeAdParams *params = [pYuMeInterface yumeGetAdParams];
    params.eAdType = eAdType;
    [pYuMeInterface yumeModifyParams:params];
}

- (void)playContent {
    /* check if all the contents are played out */
    if(self.contentCountPlayed == self.contentCountTotal)
        return;
    
    if( (self.ePlayState == YuMeAppPlayStateContent1) || (self.ePlayState == YuMeAppPlayStateContent2) ) {
        [YuMeLogViewController writeLog:@"Content Play already in Progress." logToConsole:YES];
        return;
    }
    
    NSURL *contentUrl = nil;
    /* play content 1 after preroll ad and content 2 after the midroll ads */
    if(self.contentCountPlayed == 0) {
        [YuMeLogViewController writeLog:@"Playing Content 1..." logToConsole:YES];
        contentUrl = [self localContentURL:@"one" type:@"m4v"];
        self.ePlayState = YuMeAppPlayStateContent1;
    } else {
        [YuMeLogViewController writeLog:@"Playing Content 2..." logToConsole:YES];
        contentUrl = [self localContentURL:@"two" type:@"m4v"];
        self.ePlayState = YuMeAppPlayStateContent2;
    }
    [self showContentVideoView];
    [self.videoDisplayView play:contentUrl];
}

- (void)contentCompleted {
    switch (self.ePlayState) {
        case YuMeAppPlayStateContent1:
            [YuMeLogViewController writeLog:@"Completed Content 1" logToConsole:YES];
            break;
        case YuMeAppPlayStateContent2:
            [YuMeLogViewController writeLog:@"Completed Content 2" logToConsole:YES];
            break;
        default:
            break;
    }
    self.ePlayState = YuMeAppPlayStateNone;
    
    /* increment the played content count */
    self.contentCountPlayed++;
    
	[self hideVideoView];
    
    /* based on the played content count, request for midroll or postroll ad */
    if( (self.contentCountPlayed > 0) && (self.contentCountPlayed < self.contentCountTotal) ) {
        if (self.settings.bSupportMidroll) {
            [self modifyAdTypeInSdk:YuMeAdTypeMidroll];
            [self performSelector:@selector(makeStreamingAdRequestAfterDelay:) withObject:@"Midroll" afterDelay:0.2];
        } else {
            [self playContent];
		}
    } else if (self.contentCountPlayed == self.contentCountTotal) {
        if (self.settings.bSupportPostroll) {
            [self modifyAdTypeInSdk:YuMeAdTypePostroll];
            [self performSelector:@selector(makeStreamingAdRequestAfterDelay:) withObject:@"Postroll" afterDelay:0.2];
        } else {
           [self modifyAdTypeInSdk:YuMeAdTypePreroll];
        }
    }
}

- (NSURL *)localContentURL:(NSString *)name type:(NSString *)type {
	NSBundle *bundle = [NSBundle mainBundle];
	if (bundle) {
		NSString *moviePath = [bundle pathForResource:name ofType:type];
		if (moviePath) {
			return [NSURL fileURLWithPath:moviePath];
		}
	}
    return nil;
}

#if 0
- (void) logDeviceScreenSizeInfo {
    UIInterfaceOrientation currOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    NSLog(@"statusBarOrientation: %d", currOrientation);
    
    CGRect mainScreenRect = [[UIScreen mainScreen] bounds];
    NSLog(@"bounds: %@", NSStringFromCGSize(mainScreenRect.size));
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    NSLog(@"applicationFrame: %@", NSStringFromCGSize(appFrame.size));
    
    BOOL bIsSBHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    NSLog(@"isStatusBarHidden: %@", (bIsSBHidden ? @"YES" : @"NO"));
    
#ifdef __IPHONE_8_0
    //if we take native bounds for iPhone with iOS >= 8.0, we get the 640x960 instead of 320x480
    if(YUME_APP_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(YUME_APP_IOS_VERSION_8)) {
        //if(YUME_SYSTEM_VERSION_EQUAL_TO(YUME_IOS_VERSION_8)) {
        NSLog(@"Getting Native Bounds for iOS >= 8.0 devices...");
        CGRect mainScreenNativeRect = [[UIScreen mainScreen] nativeBounds];
        NSLog(@"nativeBounds: %@", NSStringFromCGSize(mainScreenNativeRect.size));
        
    }
#endif //__IPHONE_8_0
}
#endif /* 0 */

#pragma -
#pragma Get Download Percentage Methods
- (void)showDownloadedPercentageInfo {
    [self setDldPercentUIElementsVisibility:YES];
    [self startDldPercenTimer];
}

- (void)startDldPercenTimer {
    if(self.getDldPercentTimer == nil) {
        NSLog(@"Starting Get Downloaded Percentage timer...");
        self.getDldPercentTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                       target:self
                                                     selector:@selector(onDldPercentageTimerExpired)
                                                     userInfo:nil
                                                      repeats:YES];
    }
}

- (void)stopDldPercenTimer {
    if (self.getDldPercentTimer) {
        NSLog(@"Stopping Get Downloaded Percentage timer...");
        if ([self.getDldPercentTimer isValid])
            [self.getDldPercentTimer invalidate];
        self.getDldPercentTimer = nil;
    }
}

- (void)onDldPercentageTimerExpired {
    NSLog(@"onDldPercentageTimerExpired...");
    //get the download status
    NSString *dldStatus = [pYuMeInterface yumeGetDownloadStatus];
    self.lblDownloadStatus.text = @"Download Status: ";
    self.lblDownloadStatus.text = [[self.lblDownloadStatus text] stringByAppendingString:dldStatus];
    
    if([dldStatus caseInsensitiveCompare:@"NONE"] == NSOrderedSame) {
        [self stopDldPercenTimer];
        [self setDldPercentUIElementsVisibility:NO];
        return;
    }
    
    //stop the timer if downloads is not in progress
    if([dldStatus caseInsensitiveCompare:@"IN_PROGRESS"] != NSOrderedSame) {
        [self stopDldPercenTimer];
    }
    //get the downloaded percentage
    self.lblDownloadPercentage.text = @"Downloaded Percent: ";
    self.lblDownloadPercentage.text = [[self.lblDownloadPercentage text] stringByAppendingString:[NSString stringWithFormat:@"%.2f", [pYuMeInterface yumeGetDownloadedPercentage]]];
}

- (IBAction)closeDownloadStatusButtonPressed:(id)sender {
    [self stopDldPercenTimer];
    [self setDldPercentUIElementsVisibility:NO];
}

- (void)setDldPercentUIElementsVisibility:(BOOL)bVisibility {
    self.lblDownloadStatus.hidden = !bVisibility;
    self.lblDownloadPercentage.hidden = !bVisibility;
    self.btnCloseDownloadStatus.hidden = !bVisibility;
    
    if(!bVisibility) {
        self.lblDownloadStatus.text = @"Download Status: ";
        self.lblDownloadPercentage.text = @"Downloaded Percent: ";
    }
}

//YuMePresentedViewControllerDelegate delegates
#pragma -
#pragma YuMePresentedViewControllerDelegate Methods
- (void)pvcOrientationChanged {
    [self resizeControls];
}

#pragma mark -
#pragma mark Observers for events like Orientation Change, App State Change etc.,

- (void)addAppObservers {
    //add the app state change observers
    [self addAppStateChangeAppObservers];
}

- (void)removeAppObservers {
    //remove the app state change observers
    [self removeAppStateChangeAppObservers];
}

- (void)addAppStateChangeAppObservers {
    NSLog(@"App::Adding App State Change Observers...");
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appStateChanged) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appStateChanged) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)removeAppStateChangeAppObservers {
    NSLog(@"App::Removing App State Change Observers...");
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appStateChanged {
    if( (self.ePlayState != YuMeAppPlayStateContent1) && (self.ePlayState != YuMeAppPlayStateContent2) ) {
        return;
    }
    NSURL *contentUrl = nil;
    if(self.ePlayState == YuMeAppPlayStateContent1) {
        [YuMeLogViewController writeLog:@"Resuming Content 1..." logToConsole:YES];
        contentUrl = [self localContentURL:@"one" type:@"m4v"];
    } else {
        [YuMeLogViewController writeLog:@"Resuming Content 2..." logToConsole:YES];
        contentUrl = [self localContentURL:@"two" type:@"m4v"];
    }
    //[self showContentVideoView];
    [self.videoDisplayView play:contentUrl];
}


@end //@implementation YuMeViewController
