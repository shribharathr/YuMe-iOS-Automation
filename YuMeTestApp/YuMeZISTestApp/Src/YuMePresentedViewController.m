//
//  YuMePresentedViewController.m
//  YuMeiOSSDK
//
//  Created by Senthil on 2/25/15.
//  Copyright (c) 2015 YuMe. All rights reserved.
//

#import "YuMePresentedViewController.h"

@interface YuMePresentedViewController ()

@end //@interface YuMePresentedViewController

@implementation YuMePresentedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(self.videoDisplayView) {
        [self.videoDisplayView orientationChanged];
    }
    if(self.delegate) {
        [self.delegate pvcOrientationChanged];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end //@implementation YuMePresentedViewController
