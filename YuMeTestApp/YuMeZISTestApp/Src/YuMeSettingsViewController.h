//
//  YuMeSettingsViewController.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YuMeSizeViewController.h"
#import "YuMeTypes.h"

@interface YuMeSettingsViewController : UIViewController<UITextFieldDelegate> {
}
//Setting for YuMe SDK
@property (nonatomic, retain) IBOutlet UITextField *txtAdServerUrl;
@property (nonatomic, retain) IBOutlet UITextField *txtDomainId;
@property (nonatomic, retain) IBOutlet UITextField *txtAdditionalParams;
@property (nonatomic, retain) IBOutlet UITextField *txtAdTimeout;
@property (nonatomic, retain) IBOutlet UITextField *txtVideoTimeout;
@property (nonatomic, retain) IBOutlet UISwitch *swHighBitrateVideo;
@property (nonatomic, retain) IBOutlet UITextField *txtVideoAdFormatsPriority;
@property (nonatomic, retain) IBOutlet UISwitch *swAutoNetworkDetect;
@property (nonatomic, retain) IBOutlet UISwitch *swEnableCaching;
@property (nonatomic, retain) IBOutlet UISwitch *swEnableAutoPrefetch;
@property (nonatomic, retain) IBOutlet UITextField *txtStorageSize;
@property (nonatomic, retain) IBOutlet UISwitch *swEnableCBToggle;
@property (nonatomic, retain) IBOutlet UISwitch *swOverrideOrientation;
@property (nonatomic, retain) IBOutlet UISwitch *swTapToCalendar;
@property (nonatomic, retain) IBOutlet UISegmentedControl *scPlayType;
@property (nonatomic, retain) IBOutlet UITextField *txtLogLevel;
@property (nonatomic, retain) IBOutlet UISegmentedControl *scSdkUsageMode;
@property (nonatomic, retain) IBOutlet UITextField *txtAdSlot;

//app-specific settings
@property (nonatomic, retain) IBOutlet UIScrollView *settingsScrollView;
@property (nonatomic, retain) IBOutlet UISwitch *swPreroll;
@property (nonatomic, retain) IBOutlet UISwitch *swMidroll;
@property (nonatomic, retain) IBOutlet UISwitch *swPostroll;
@property (nonatomic, retain) IBOutlet UISwitch *swEnableOrientation;
@property (nonatomic, retain) IBOutlet UISwitch *swSendAdViewInfo;
//app-specific settings - titles
@property (nonatomic, retain) IBOutlet UILabel *labelSDKSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelSDKTimeoutSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelSDKFormatsAndSizeSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelSDKNetworkSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelSDKPrefetchSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelSDKMiscSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelAppSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelAppAdSlotSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelAppAdScreenOrientationSettings;
@property (nonatomic, retain) IBOutlet UILabel *labelAppMiscSettings;

@property (nonatomic, retain) IBOutlet UIButton *btnSave;
@property (nonatomic, retain) IBOutlet UIButton *btnCancel;

- (void)refreshSDKParams:(YuMeAdParams *)adParams;

- (IBAction)saveAction:(id)sender;

- (IBAction)cancelAction:(id)sender;

@end //@interface YuMeSettingsViewController
