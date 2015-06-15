//
//  YuMeAboutViewController.h
//  YuMeZISTestApp
//
//  Created by Senthil on 01/03/13.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YuMeAboutViewController : UIViewController {
}
@property (nonatomic, retain) IBOutlet UILabel *labelSDKVersion;
@property (nonatomic, retain) IBOutlet UILabel *labelTestAppVersion;
@property (nonatomic, retain) IBOutlet UILabel *labelTTCSupport;
@property (nonatomic, retain) IBOutlet UIButton *btnOK;
@property (nonatomic, retain) IBOutlet UIScrollView *aboutScrollView;

- (IBAction)btnOKPressed:(UIButton *)sender;

@end //@interface YuMeAboutViewController
