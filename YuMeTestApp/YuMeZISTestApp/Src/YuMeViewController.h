//
//  YuMeViewController.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/13/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YuMeTypes.h"
#import "YuMeVideoView.h"
#import "YuMeInterface.h"
#import "YuMeSettingsViewController.h"
#import "YuMeLogViewController.h"
#import "YuMeAboutViewController.h"

@class YuMeInterface;
@class ShowBannerViewController;

typedef enum {
    YuMeMenuBtnTypeNone,
    YuMeMenuBtnTypeHomeScreenAPIs,
    YuMeMenuBtnTypeAdScreenAPIs
} YuMeMenuBtnType;

typedef enum {
    YuMeAppPlayStateNone,
    YuMeAppPlayStateStreamingPreroll,
    YuMeAppPlayStateStreamingMidroll,
    YuMeAppPlayStateStreamingPostroll,
    YuMeAppPlayStateContent1,
    YuMeAppPlayStateContent2
} YuMeAppPlayState;

@interface YuMeViewController : UIViewController<UIActionSheetDelegate> {
}
@property(nonatomic, retain) IBOutlet UIButton *btnInit;
@property(nonatomic, retain) IBOutlet UIButton *btnInitAd;
@property(nonatomic, retain) IBOutlet UIButton *btnShowAd;
@property(nonatomic, retain) IBOutlet UIButton *btnModifyParams;
@property(nonatomic, retain) IBOutlet UIButton *btnGetParams;
@property(nonatomic, retain) IBOutlet UIButton *btnDeInit;
@property(nonatomic, retain) IBOutlet UIButton *btnSettings;
@property(nonatomic, retain) IBOutlet UIButton *btnAbout;
@property(nonatomic, retain) IBOutlet UIButton *btnViewLog;
@property(nonatomic, retain) IBOutlet UIButton *btnHomeScreenMenu;
@property(nonatomic, retain) IBOutlet UILabel *lblDownloadStatus;
@property(nonatomic, retain) IBOutlet UILabel *lblDownloadPercentage;
@property(nonatomic, retain) IBOutlet UIButton *btnCloseDownloadStatus;

@property(nonatomic, strong) UIButton *btnAdScreenMenu;

@property(nonatomic, retain) IBOutlet UIScrollView *homeScrollView;

/* UI Button click handlers */
- (IBAction)btnInitPressed:(UIButton *)sender;

- (IBAction)btnInitAdPressed:(UIButton *)sender;

- (IBAction)btnShowAdPressed:(UIButton *)sender;

- (IBAction)btnModifyParamsPressed:(UIButton *)sender;

- (IBAction)btnGetParamsPressed:(UIButton *)sender;

- (IBAction)btnDeInitPressed:(UIButton *)sender;

- (IBAction)homeScreenMenuButtonPressed:(id)sender;

- (IBAction)closeDownloadStatusButtonPressed:(id)sender;

- (void)hideVideoView;

- (void)adCompleted;

- (void)showAdScreenMenuButton;

- (void)resizeControls;

+ (YuMeInterface *)getYuMeInterface;

@end //@interface YuMeViewController
