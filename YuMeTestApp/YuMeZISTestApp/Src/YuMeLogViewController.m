//
//  YuMeLogViewController.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeLogViewController.h"
#import "YuMeAppUtils.h"
#import "YuMeAppConstants.h"

@interface YuMeLogViewController ()

@end //@interface YuMeLogViewController

NSFileHandle *logFile = nil;

@implementation YuMeLogViewController

- (void)dealloc {
    [self deInitialize];
}

- (void)initialize {
    self.txtLogView = nil;
    self.toolbar = nil;
}

- (void)deInitialize {
	self.txtLogView = nil;
    self.toolbar = nil;
}

//Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addToolBar];
	self.view.frame = [[UIScreen mainScreen] applicationFrame];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleTopMargin;
	self.txtLogView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.txtLogView.delegate = self;
    self.title = @"ZIS Test App Logs";
    
    [self displayLog];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)addToolBar {
    CGRect mainViewRect = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation] ;
    //right side of nav bar
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, mainViewRect.size.width, 44)];
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:3];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                     target:self
                                     action:@selector(onDoneButtonPressed:)];
    doneButton.style = UIBarButtonItemStylePlain;
    if(YUME_APP_SYSTEM_VERSION_LESS_THAN(YUME_APP_IOS_VERSION_7)) {
        doneButton.style = UIBarButtonItemStyleBordered;
    }
    [buttons addObject:doneButton];
    doneButton = nil;
   
    [self.toolbar setItems:buttons animated:NO];
    self.toolbar.barStyle = UIToolbarPositionTop;
    buttons = nil;
    
    [self.view addSubview:self.toolbar];
}

- (IBAction)onDoneButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)displayLog {
	NSString *logFile = [YuMeLogViewController getLogFilePath];
	if (logFile) {
		NSString *strContent = [NSString stringWithContentsOfFile:logFile encoding:NSUTF8StringEncoding error:nil];
		self.txtLogView.text = strContent;
	}
}

+ (NSString *)getLogFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	if (!documentsDirectory) {
		NSLog(@"Documents directory not found.");
		return nil;
	}
	return [documentsDirectory stringByAppendingPathComponent:@"yume_log.txt"];
}

+ (void)createLogFile {
	if (logFile) {
		logFile = nil;
	}
	NSString *filePath = [YuMeLogViewController getLogFilePath];
	if (filePath) {
		if ([[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]) {
			logFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
		}
	}
}

+ (void)writeLog:(NSString *)logMsg logToConsole:(BOOL)bLogToConsole {
    if(bLogToConsole) {
        NSLog(@"%@", logMsg);
    }
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
	NSDate *dt = [NSDate date];
	NSString *dateStr = [NSString stringWithFormat:@"%@: ", [dateFormatter stringFromDate:dt]];
	[logFile writeData:[dateStr dataUsingEncoding:NSUTF8StringEncoding]];
	dateFormatter = nil;
	
	[logFile writeData:[logMsg dataUsingEncoding:NSUTF8StringEncoding]];
	NSData *logData = [NSData dataWithBytes:"\n" length:1];
	[logFile writeData:logData];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    return YES;
}

- (void)orientationChanged {
    [self handleOrientation];
}

- (void)handleOrientation {
    CGRect mainViewRect = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation];
    self.toolbar.frame = CGRectMake(0, 0, mainViewRect.size.width, 44);
    self.view.frame = CGRectMake(0, 0, mainViewRect.size.width, mainViewRect.size.height);
}

@end //@implementation YuMeLogViewController
