//
//  YuMeVideoView.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YuMeAdViewDelegate.h"
#import <MediaPlayer/MediaPlayer.h>

@interface YuMeVideoView : UIView<YuMeAdViewDelegate> {
    
}

/* The delegate handle */
@property (nonatomic, weak) id delegate;

- (void)play:(NSURL *)url;

- (void)orientationChanged;

@end //@interface VideoView
