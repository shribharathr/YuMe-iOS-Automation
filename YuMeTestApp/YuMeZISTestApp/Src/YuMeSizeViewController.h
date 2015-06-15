//
//  YuMeSizeViewController.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YuMeSizeViewController : UIViewController <UITextFieldDelegate> {
}

//Full Screen Mode settings
@property (nonatomic, retain) IBOutlet UISwitch *swEnableFSMode;

//Portrait mode settings
@property (nonatomic, retain) IBOutlet UITextField *txtPortraitX;
@property (nonatomic, retain) IBOutlet UITextField *txtPortraitY;
@property (nonatomic, retain) IBOutlet UITextField *txtPortraitWidth;
@property (nonatomic, retain) IBOutlet UITextField *txtPortraitHeight;
@property (nonatomic, retain) IBOutlet UILabel *lblMaxPortraitWidth;
@property (nonatomic, retain) IBOutlet UILabel *lblMaxPortraitHeight;

//Landscape mode settings
@property (nonatomic, retain) IBOutlet UITextField *txtLandscapeX;
@property (nonatomic, retain) IBOutlet UITextField *txtLandscapeY;
@property (nonatomic, retain) IBOutlet UITextField *txtLandscapeWidth;
@property (nonatomic, retain) IBOutlet UITextField *txtLandscapeHeight;
@property (nonatomic, retain) IBOutlet UILabel *lblMaxLandscapeWidth;
@property (nonatomic, retain) IBOutlet UILabel *lblMaxLandscapeHeight;

@property (nonatomic, retain) IBOutlet UIScrollView *sizeScrollView;

@property (nonatomic, retain) IBOutlet UIButton *btnSave;
@property (nonatomic, retain) IBOutlet UIButton *btnCancel;

- (IBAction)saveAction:(id)sender;

- (IBAction)cancelAction:(id)sender;

- (void)updateValues;

- (CGRect)getPortraitValues;

- (CGRect)getLandscapeValues;

@end //@interface YuMeSizeViewController
