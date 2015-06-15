//
//  YuMePresentedViewController.h
//  YuMeiOSSDK
//
//  Created by Senthil on 2/25/15.
//  Copyright (c) 2015 YuMe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YuMeVideoView.h"

@protocol YuMePresentedViewControllerDelegate <NSObject>

- (void)pvcOrientationChanged;

@end //@protocol YuMePresentedViewControllerDelegate


@interface YuMePresentedViewController : UIViewController

@property(nonatomic, assign)YuMeVideoView *videoDisplayView;

@property (nonatomic, weak)id<YuMePresentedViewControllerDelegate> delegate;

@end //@interface YuMePresentedViewController
