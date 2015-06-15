//
//  YuMeSettingsViewController.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeSettingsViewController.h"
#import "YuMeAppSettings.h"
#import "YuMeViewController.h"
#import "YuMeAppUtils.h"
#import "YuMeAppConstants.h"

@interface YuMeSettingsViewController ()<UIActionSheetDelegate> {
    
}
/* The scroll view height */
@property (nonatomic) float settingsScrollHeight;

@end //@interface YuMeSettingsViewController

@implementation YuMeSettingsViewController

- (void)dealloc {
    [self deInitialize];
}

- (void)initialize {
    self.txtAdServerUrl = nil;
    self.txtDomainId = nil;
    self.txtAdditionalParams = nil;
    self.txtAdTimeout = nil;
    self.txtVideoTimeout = nil;
    self.swHighBitrateVideo = nil;
    self.txtVideoAdFormatsPriority = nil;
    self.swAutoNetworkDetect = nil;
    self.swEnableCaching = nil;
    self.swEnableAutoPrefetch = nil;
    self.txtStorageSize = nil;
    self.swEnableCBToggle = nil;
    self.swOverrideOrientation = nil;
    self.swTapToCalendar = nil;
    self.scPlayType = nil;
    self.txtLogLevel = nil;
    self.scSdkUsageMode = nil;
    self.txtAdSlot = nil;
    
    //app-specific settings
    self.settingsScrollView = nil;
    self.swPreroll = nil;
    self.swMidroll = nil;
    self.swPostroll = nil;
    self.swEnableOrientation = nil;
    self.swSendAdViewInfo = nil;
    self.labelSDKSettings = nil;
    self.labelSDKTimeoutSettings = nil;
    self.labelSDKFormatsAndSizeSettings = nil;
    self.labelSDKNetworkSettings = nil;
    self.labelSDKPrefetchSettings = nil;
    self.labelSDKMiscSettings = nil;
    self.labelAppSettings = nil;
    self.labelAppAdSlotSettings = nil;
    self.labelAppAdScreenOrientationSettings = nil;
    self.labelAppMiscSettings = nil;
    self.btnSave = nil;
    self.btnCancel = nil;
    
    self.settingsScrollHeight = 0.0f;
}

- (void)deInitialize {
	[self initialize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.settingsScrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.settingsScrollView.contentSize = contentRect.size;
    self.settingsScrollHeight = contentRect.size.height;
    
    self.settingsScrollView.frame = self.view.frame;
    [self.view addSubview:self.settingsScrollView];
    
    [self.scPlayType addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];

    [self setTextFieldsDelegate];
    
    UIToolbar *numberToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.tintColor = [UIColor darkGrayColor];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneWithNumberPad)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [[NSArray alloc] initWithObjects:flex, barButtonItem, nil];
    [numberToolbar setItems:items];
    barButtonItem = nil;
    flex = nil;
    items = nil;
    
    self.txtAdTimeout.inputAccessoryView = numberToolbar;
    self.txtVideoTimeout.inputAccessoryView = numberToolbar;
    self.txtStorageSize.inputAccessoryView = numberToolbar;
    self.txtLogLevel.inputAccessoryView = numberToolbar;
    numberToolbar = nil;
    
    //Update value from AdParams Data.
    YuMeAdParams *adParams = nil;
    YuMeInterface *pYuMeInterface = [YuMeViewController getYuMeInterface];
    if(pYuMeInterface) {
        adParams = [pYuMeInterface yumeGetAdParams];
    }
    [self refreshSDKParams:adParams];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self orientationChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self orientationChanged];
}

- (void)setTextFieldsDelegate {
    self.txtAdServerUrl.delegate = self;
	self.txtDomainId.delegate = self;
	self.txtAdditionalParams.delegate = self;
	self.txtAdTimeout.delegate = self;
	self.txtVideoTimeout.delegate = self;
    self.txtVideoAdFormatsPriority.delegate = self;
    self.txtStorageSize.delegate = self;
    self.txtLogLevel.delegate = self;
    self.txtAdSlot.delegate = self;
}

- (void)refreshSDKParams:(YuMeAdParams *)adParams {
    [self setTextFieldsDelegate];
    
    YuMeAppSettings *settings = [YuMeAppSettings readSettings];

    self.txtAdServerUrl.text = (adParams.pAdServerUrl == nil) ?  settings.adServerUrl : adParams.pAdServerUrl;
    self.txtDomainId.text = (adParams.pDomainId == nil) ? settings.domainId : adParams.pDomainId;
    self.txtAdditionalParams.text = (adParams.pAdditionalParams == nil) ? settings.additionalParams : adParams.pAdditionalParams;
    self.txtAdTimeout.text = (adParams == nil) ? settings.adTimeOut : [NSString stringWithFormat:@"%ld", (long)adParams.adTimeout];
    self.txtVideoTimeout.text = (adParams == nil) ? settings.videoTimeOut : [NSString stringWithFormat:@"%ld", (long)adParams.videoTimeout];
    self.swHighBitrateVideo.on = (adParams == nil) ? settings.bHighBitrateVideo : adParams.bSupportHighBitRate;
    NSString *pList = @"";
    NSMutableArray *a = [[NSMutableArray alloc] init];
    if (adParams != nil) {
        NSMutableArray *priorityList = adParams.pVideoAdFormatsPriorityList;
        for (NSUInteger i = 0; i < priorityList.count; i++) {
            NSString *mimeType = [priorityList objectAtIndex:i];
            if ([mimeType isEqualToString:@"0"]) {
                [a addObject:@"HLS"];
            } else if ([mimeType isEqualToString:@"1"]) {
                [a addObject:@"MP4"];
            } else if ([mimeType isEqualToString:@"2"]) {
                [a addObject:@"MOV"];
            }
        }
        pList = [a componentsJoinedByString:@","];
        a = nil;
    }
    self.txtVideoAdFormatsPriority.text = (adParams == nil) ? settings.videoAdFormatsArr : pList;
    self.swAutoNetworkDetect.on = (adParams == nil) ? settings.bAutoDetectNetwork : adParams.bSupportAutoNetworkDetect;
    self.swEnableCaching.on = (adParams == nil) ? settings.bEnableCaching : adParams.bEnableCaching;
    self.swEnableAutoPrefetch.on = (adParams == nil) ? settings.bEnableAutoPrefetch : adParams.bEnableAutoPrefetch;
    self.txtStorageSize.text = (adParams == nil) ? settings.storageSize : [NSString stringWithFormat:@"%2f", adParams.storageSize];
    self.swEnableCBToggle.on = (adParams == nil) ? settings.bEnableCBToggle : adParams.bEnableCBToggle;
    self.swOverrideOrientation.on = (adParams == nil) ? settings.bOverrideOrientation : adParams.bOverrideOrientation;
    self.swTapToCalendar.on = (adParams == nil) ? settings.bEnableTTC : adParams.bEnableTTC;
    self.scPlayType.selectedSegmentIndex = (adParams == nil) ? settings.ePlayType : adParams.ePlayType;
    self.txtLogLevel.text = settings.logLevel;
    self.scSdkUsageMode.selectedSegmentIndex = (adParams == nil) ? settings.eSdkUsageMode : adParams.eSdkUsageMode;
    YuMeAdType adType = (adParams == nil) ? settings.eAdType : adParams.eAdType;
    if (adType == YuMeAdTypePreroll) {
        self.txtAdSlot.text = @"Preroll";
    } else if (adType == YuMeAdTypeMidroll) {
        self.txtAdSlot.text = @"Midroll";
    } else if (adType == YuMeAdTypePostroll) {
        self.txtAdSlot.text = @"Postroll";
    } else {
        self.txtAdSlot.text = @"Preroll";
    }
    
    //app-specific settings
    self.swPreroll.on = settings.bSupportPreroll;
    self.swMidroll.on = settings.bSupportMidroll;
    self.swPostroll.on = settings.bSupportPostroll;
    self.swEnableOrientation.on = settings.bEnableAdOrientation;
    self.swSendAdViewInfo.on = settings.bSendAdViewInfo;
}

- (IBAction)cancelAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveAction:(id)sender {
	YuMeAppSettings *settings = [YuMeAppSettings readSettings];
	
	settings.adServerUrl = self.txtAdServerUrl.text;
	settings.domainId = self.txtDomainId.text;
	settings.additionalParams = self.txtAdditionalParams.text;
	settings.adTimeOut = self.txtAdTimeout.text;
	settings.videoTimeOut = self.txtVideoTimeout.text;
    settings.bHighBitrateVideo = self.swHighBitrateVideo.on;
    settings.videoAdFormatsArr = self.txtVideoAdFormatsPriority.text;
    settings.bAutoDetectNetwork = self.swAutoNetworkDetect.on;
    settings.bEnableCaching = self.swEnableCaching.on;
    settings.bEnableAutoPrefetch = self.swEnableAutoPrefetch.on;
    settings.storageSize = self.txtStorageSize.text;
    settings.bEnableCBToggle = self.swEnableCBToggle.on;
    settings.bOverrideOrientation = self.swOverrideOrientation.on;
    settings.bEnableTTC = self.swTapToCalendar.on;
    NSInteger index = self.scPlayType.selectedSegmentIndex;
    settings.ePlayType = (YuMePlayType)index;
    settings.logLevel = self.txtLogLevel.text;
    index = self.scSdkUsageMode.selectedSegmentIndex;
    settings.eSdkUsageMode = (YuMeSdkUsageMode)index;
    if ([self.txtAdSlot.text isEqualToString:@"Preroll"]) {
        settings.eAdType = YuMeAdTypePreroll;
    } else if ([self.txtAdSlot.text isEqualToString:@"Midroll"]) {
        settings.eAdType = YuMeAdTypeMidroll;
    } else if ([self.txtAdSlot.text isEqualToString:@"Postroll"]) {
        settings.eAdType = YuMeAdTypePostroll;
    }

    //app-specific settings
    settings.bSupportPreroll = self.swPreroll.on;
    settings.bSupportMidroll = self.swMidroll.on;
    settings.bSupportPostroll = self.swPostroll.on;
    settings.bEnableAdOrientation = self.swEnableOrientation.on;
    settings.bSendAdViewInfo = self.swSendAdViewInfo.on;

    [YuMeAppSettings saveSettings:settings];

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma UiSegmented Click Action
#pragma mark -

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender {
#if 0
    for (int i = 0; i < [sender.subviews count]; i++) {
        if ([[sender.subviews objectAtIndex:i] respondsToSelector:@selector(isSelected)] && [[sender.subviews objectAtIndex:i]isSelected]) {
            [[sender.subviews objectAtIndex:i] setTintColor:[UIColor blackColor]];
        }
        if ([[sender.subviews objectAtIndex:i] respondsToSelector:@selector(isSelected)] && ![[sender.subviews objectAtIndex:i] isSelected]) {
            [[sender.subviews objectAtIndex:i] setTintColor:[UIColor whiteColor]];
        }
    }
#endif //0
}

#pragma ActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.txtAdSlot.text = [actionSheet buttonTitleAtIndex:buttonIndex];
    if([self.txtAdSlot.text caseInsensitiveCompare:@"cancel"] == NSOrderedSame) {
       self.txtAdSlot.text = @"Preroll";
    }
}

#pragma Alertview Delegate
#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.txtAdSlot.text =  [alertView buttonTitleAtIndex:buttonIndex];
    if([self.txtAdSlot.text caseInsensitiveCompare:@"cancel"] == NSOrderedSame) {
        self.txtAdSlot.text = @"Preroll";
    }
}

#pragma TextField Delegate
#pragma mark -
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.txtAdSlot) {
        [textField resignFirstResponder];

        if((YUME_APP_IS_DEVICE_IPAD == 1 && (YUME_APP_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(YUME_APP_IOS_VERSION_8)))) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Select an ad slot"
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Preroll",
                                      @"Midroll",
                                      @"Postroll", nil];
            [alertView show];
            alertView = nil;
        } else {
            UIActionSheet *actionSheetView = [[UIActionSheet alloc] initWithTitle:@"Select an ad slot"
                                                                     delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Cancel"
                                                            otherButtonTitles:@"Preroll",
                                          @"Midroll",
                                          @"Postroll",
                                          nil];
            actionSheetView.actionSheetStyle = UIActionSheetStyleBlackOpaque;
            [actionSheetView showInView:self.view];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

- (void)doneWithNumberPad {
    [self.txtAdTimeout resignFirstResponder];
    [self.txtVideoTimeout resignFirstResponder];
    [self.txtLogLevel resignFirstResponder];
}

- (void)orientationChanged {
    CGRect mainViewRect = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation];
    self.view.frame = CGRectMake(0, 0, mainViewRect.size.width, mainViewRect.size.height);
    self.settingsScrollView.frame = CGRectMake(0, 0, mainViewRect.size.width, mainViewRect.size.height - 20);
    self.settingsScrollView.contentSize = CGSizeMake(mainViewRect.size.width, self.settingsScrollHeight);
    
    [self handleOrientation];
}

- (void)handleOrientation {
    CGRect frame = CGRectZero;
    
    float viewFrameW = self.view.frame.size.width;
    
    frame = self.txtAdServerUrl.frame;
    frame.size.width = viewFrameW;
    self.txtAdServerUrl.frame = frame;
    
    frame = self.txtDomainId.frame;
    frame.size.width = viewFrameW;
    self.txtDomainId.frame = frame;
    
    frame = self.txtAdditionalParams.frame;
    frame.size.width = viewFrameW;
    self.txtAdditionalParams.frame = frame;
    
    frame = self.txtVideoAdFormatsPriority.frame;
    frame.size.width = viewFrameW;
    self.txtVideoAdFormatsPriority.frame = frame;
    
    frame = self.btnSave.frame;
    frame.origin.x = (viewFrameW / 2) + 20;
    self.btnSave.frame = frame;
    
    frame = self.btnCancel.frame;
    frame.origin.x = (viewFrameW / 2) - (frame.size.width) - 20;
    self.btnCancel.frame = frame;
    
    frame = self.labelSDKSettings.frame;
    frame.size.width = viewFrameW;
    self.labelSDKSettings.frame = frame;
    
    frame = self.labelSDKTimeoutSettings.frame;
    frame.size.width = viewFrameW;
    self.labelSDKTimeoutSettings.frame = frame;
    
    frame = self.labelSDKFormatsAndSizeSettings.frame;
    frame.size.width = viewFrameW;
    self.labelSDKFormatsAndSizeSettings.frame = frame;
    
    frame = self.labelSDKNetworkSettings.frame;
    frame.size.width = viewFrameW;
    self.labelSDKNetworkSettings.frame = frame;
    
    frame = self.labelSDKPrefetchSettings.frame;
    frame.size.width = viewFrameW;
    self.labelSDKPrefetchSettings.frame = frame;
    
    frame = self.labelSDKMiscSettings.frame;
    frame.size.width = viewFrameW;
    self.labelSDKMiscSettings.frame = frame;
    
    frame = self.labelAppSettings.frame;
    frame.size.width = viewFrameW;
    self.labelAppSettings.frame = frame;
    
    frame = self.labelAppAdSlotSettings.frame;
    frame.size.width = viewFrameW;
    self.labelAppAdSlotSettings.frame = frame;
    
    frame = self.labelAppAdScreenOrientationSettings.frame;
    frame.size.width = viewFrameW;
    self.labelAppAdScreenOrientationSettings.frame = frame;
    
    frame = self.labelAppMiscSettings.frame;
    frame.size.width = viewFrameW;
    self.labelAppMiscSettings.frame = frame;
}

@end //@implementation YuMeSettingsViewController
