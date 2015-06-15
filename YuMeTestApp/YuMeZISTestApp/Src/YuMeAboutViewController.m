//
//  YuMeAboutViewController.m
//  YuMeZISTestApp
//
//  Created by Senthil on 01/03/13.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeAboutViewController.h"
#import "YuMeAppUtils.h"
#import "YuMeViewController.h"

@interface YuMeAboutViewController () {
    
}
/* The scroll view height */
@property (nonatomic) float aboutScrollHeight;

@end //@interface YuMeAboutViewController

@implementation YuMeAboutViewController

- (void)dealloc {
    self.aboutScrollView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.aboutScrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.aboutScrollView.contentSize = contentRect.size;
    self.aboutScrollHeight = contentRect.size.height;
 
    self.aboutScrollView.frame = self.view.frame;
    [self.view addSubview:self.aboutScrollView];
    
    YuMeInterface *yumeInterface = [YuMeViewController getYuMeInterface];
    self.labelSDKVersion.text = [[self.labelSDKVersion text] stringByAppendingString:[yumeInterface yumeGetVersion]] ;
    
    self.labelTestAppVersion.text = [[self.labelTestAppVersion text] stringByAppendingString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	
    //checks for EventKit Framework added or not (Tap to Calendar)
    BOOL bEKPresent = YES;
    Class eventClass = NSClassFromString(@"EKEvent");
    if (!eventClass) {
        bEKPresent = NO;
    }
    self.labelTTCSupport.text = [NSString stringWithFormat:@"Tap to Calendar: %@", (bEKPresent ? @"ON" : @"OFF")];
    
    [self orientationChanged];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    //Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self orientationChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self orientationChanged];
}

- (IBAction)btnOKPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)orientationChanged {
    [self handleOrientation];
}

- (void)handleOrientation {
    CGRect mainViewRect = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation];
    self.view.frame = CGRectMake(0, 0, mainViewRect.size.width, mainViewRect.size.height);
    self.aboutScrollView.frame = CGRectMake(0, 0, mainViewRect.size.width, mainViewRect.size.height - 20);
    self.aboutScrollView.contentSize = CGSizeMake(mainViewRect.size.width, self.aboutScrollHeight);
}

@end //@implementation YuMeAboutViewController
