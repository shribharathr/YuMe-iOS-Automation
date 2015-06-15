//
//  YuMeMPlayerController.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol YuMeMPlayerDelegate <NSObject>

@optional
- (void)isLoaded:(BOOL)flag;

- (void)isPlaying:(BOOL)flag;

- (void)isCompleted:(BOOL)flag;

- (void)videoDuration:(NSInteger)duration;

- (void)playBackError;

@end //@protocol YuMeMPlayerDelegate


@interface YuMeMPlayerController : MPMoviePlayerController {
}

@property(nonatomic, weak)id<YuMeMPlayerDelegate> mPlayerDelegate;

- (id)initPlayerContoller:(NSString *)videoURL bIsLocalVideo:(BOOL)bIsLocalVideo frameSize:(CGSize)size delegate:(id <YuMeMPlayerDelegate>)mPlayerDelegate1;

- (void)orientationChange:(CGRect)frame;

- (void)removeNotification;

@end //@interface YuMeMPlayerController
