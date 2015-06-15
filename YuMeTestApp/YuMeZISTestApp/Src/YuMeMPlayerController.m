//
//  YuMeMPlayerController.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "YuMeMPlayerController.h"

@implementation YuMeMPlayerController

- (id)initPlayerContoller:(NSString *)videoURL bIsLocalVideo:(BOOL)bIsLocalVideo frameSize:(CGSize)size delegate:(id <YuMeMPlayerDelegate>)mPlayerDelegate1 {
    [self initialize];
    
    NSURL *url = nil;
    if (bIsLocalVideo != YES)  {
        url = [NSURL URLWithString:videoURL];
    } else {
        url = [NSURL fileURLWithPath:videoURL];
    }
    
    self = [super initWithContentURL:url];
    if (self) {
        self.mPlayerDelegate = mPlayerDelegate1;
        self.view.frame = CGRectMake(0, 0, size.width, size.height);
        self.controlStyle = MPMovieControlStyleNone;
        self.scalingMode = MPMovieScalingModeAspectFit;
        self.view.autoresizingMask = UIViewAutoresizingNone;
        self.shouldAutoplay = YES;
        
        [self prepareToPlay];

        // Mediaplayer notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDurationAvailableCallback:)
                                                     name:MPMovieDurationAvailableNotification object:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myMovieFinishedCallback:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification object:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myLoadStateDidChangeNotification:)
                                                     name:MPMoviePlayerLoadStateDidChangeNotification object:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myMediaTypesAvailableNotification:)
                                                     name:MPMovieMediaTypesAvailableNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mpMovieFinishReason:)
                                                     name:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey object:self];
     }
    return self;
}

- (void)dealloc {
    [self deInitialize];
}

- (void)initialize {
    self.mPlayerDelegate = nil;
}

- (void)deInitialize {
    self.mPlayerDelegate = nil;
}

- (void)movieDurationAvailableCallback:(NSNotification *)aNotification {
    [self.mPlayerDelegate videoDuration:self.duration];
    [self.mPlayerDelegate isLoaded:YES];
}

// handle Orientation
- (void)orientationChange:(CGRect)frame {
    [self.view setFrame:frame];
}

- (void)myMovieFinishedCallback:(NSNotification *)aNotification {
	//yume_sdk_log(LOG_LEVEL_INFO, @"Ad finished callback received");
	MPMovieMediaTypeMask mask = self.movieMediaTypes;
    if (mask == MPMovieMediaTypeMaskNone) {
        return;
    } else {
        if (mask & MPMovieMediaTypeMaskAudio) {
        }
        if (mask & MPMovieMediaTypeMaskVideo) {
            
        }
    }
	// Make sure that tracker is not hit when play ends prematurely
	if (self.currentPlaybackTime >= self.duration) {
        [self.mPlayerDelegate isCompleted:YES];
	} else {
	}
}

- (void)myLoadStateDidChangeNotification:(NSNotification *)aNotification {
	switch (self.loadState) {
		case MPMovieLoadStatePlayable:
            [self.mPlayerDelegate videoDuration:self.duration];
            [self.mPlayerDelegate isLoaded:YES];
			break;
		case MPMovieLoadStatePlaythroughOK:
            [self.mPlayerDelegate isPlaying:YES];
			break;
		case MPMovieLoadStateStalled:
            [self.mPlayerDelegate playBackError];
			break;
		case MPMovieLoadStateUnknown:
			break;
		default:
			break;
	}
}

- (void)myMediaTypesAvailableNotification:(NSNotification *)aNotification {
}

- (void)mpMovieFinishReason:(NSNotification *)aNotification {
    int reason = [[[aNotification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackEnded) {
        //movie finished playing
        [self.mPlayerDelegate isCompleted:YES];
    } else if (reason == MPMovieFinishReasonUserExited) {
        //user hit the done button
    } else if (reason == MPMovieFinishReasonPlaybackError) {
        //error
        [self.mPlayerDelegate playBackError];
    }
}

- (void)removeNotification {
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end //implementation YuMeMPlayerController
