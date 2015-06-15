//
//  YuMeAdViewDelegate.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuMeAppSettings.h"

@protocol YuMeAdViewDelegate <NSObject>

- (void)contentCompleted;

- (BOOL)allowOrientationChange;

- (void)orientationChanged;

- (YuMeAppSettings *)getSettings;

@end //@protocol YuMeAdViewDelegate
