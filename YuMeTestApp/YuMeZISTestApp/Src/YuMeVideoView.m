//
//  YuMeVideoView.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeVideoView.h"
#import "YuMeLogViewController.h"
#import "YuMeAppConstants.h"

@interface YuMeVideoView()

/* The movie player */
@property (nonatomic, strong) MPMoviePlayerController *thePlayer;

/* The timer used for timing out struck Videos. */
@property (nonatomic, strong) NSTimer *videoTimer;

@end //@interface YuMeVideoView

@implementation YuMeVideoView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.thePlayer = nil;
        self.videoTimer = nil;
        self.delegate = nil;
    }
    return self;
}

- (void)dealloc {
    self.thePlayer = nil;
    self.videoTimer = nil;
    self.delegate = nil;
}

- (void)play:(NSURL *)url {
    if(self.thePlayer == nil) {
        self.thePlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
        self.thePlayer.scalingMode = MPMovieScalingModeAspectFit;
        self.thePlayer.view.frame = self.bounds;
        self.thePlayer.fullscreen = NO;
        self.thePlayer.view.autoresizingMask = UIViewAutoresizingNone;
        [self addSubview:self.thePlayer.view];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myMovieFinishedCallback:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification object:self.thePlayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myLoadStateDidChangeNotification:)
                                                     name:MPMoviePlayerLoadStateDidChangeNotification object:self.thePlayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myMediaTypesAvailableNotification:)
                                                     name:MPMovieMediaTypesAvailableNotification object:self.thePlayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myMovieExitFullScreen:)
                                                     name:MPMoviePlayerWillExitFullscreenNotification object:self.thePlayer];
    } else {
        self.thePlayer.contentURL = url;
    }
    [self.thePlayer play];
}

- (void)myMovieFinishedCallback:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification object:self.thePlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerLoadStateDidChangeNotification object:self.thePlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMovieMediaTypesAvailableNotification object:self.thePlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:self.thePlayer];
    
    //[YuMeLogViewController writeLog:@"Content Completed"];
    self.thePlayer.controlStyle = MPMovieControlStyleNone;
    self.thePlayer.fullscreen = NO;
    [self.thePlayer.view removeFromSuperview];
    self.thePlayer = nil;
    [self.delegate contentCompleted];
}

- (void)myLoadStateDidChangeNotification:(NSNotification *)aNotification {
    //[self writeLog:@"Content load state notification"];
}

- (void)myMediaTypesAvailableNotification:(NSNotification *)aNotification {
    //	[self writeLog:@"Content media type available notification"];
}

- (void)myMovieExitFullScreen:(NSNotification *)aNotification {
    [self.thePlayer stop];
    [self.thePlayer.view removeFromSuperview];
}

//YuMeAdViewDelegate methods implementation
- (void)contentCompleted {
    // do nothing
}

- (BOOL)allowOrientationChange {
    return YES;
}

- (void)orientationChanged {
    if (self.thePlayer) { //content is playing
        //thePlayer.view.frame = self.bounds;
        YuMeAppSettings *settings = [YuMeAppSettings readSettings];
        //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if (UIDeviceOrientationIsPortrait(orientation)) {
            self.thePlayer.view.frame = settings.adRectPortrait;
        } else {
            self.thePlayer.view.frame = settings.adRectLandscape;
        }
    } else { //ad is playing using presented view controller
#if YUME_APP_USE_PRESENTED_VIEWCONTROLLER
        YuMeAppSettings *settings = [YuMeAppSettings readSettings];
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIDeviceOrientationIsPortrait(orientation)) {
            self.frame = settings.adRectPortrait;
        } else {
            self.frame = settings.adRectLandscape;
        }
#endif //YUME_APP_USE_PRESENTED_VIEWCONTROLLER
    }
}

- (YuMeAppSettings *)getSettings {
    return nil;
}

@end //@implementation VideoView
