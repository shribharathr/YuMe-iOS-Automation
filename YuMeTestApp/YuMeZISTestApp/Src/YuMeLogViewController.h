//
//  YuMeLogViewController.h
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YuMeLogViewController : UIViewController<UITextViewDelegate> {
}

@property (nonatomic, retain) IBOutlet UITextView *txtLogView;

@property (nonatomic, retain) UIToolbar *toolbar;

- (void)displayLog;

+ (NSString *)getLogFilePath;

+ (void)createLogFile;

+ (void)writeLog:(NSString *)aString logToConsole:(BOOL)bLogToConsole;

@end //@interface YuMeLogViewController
