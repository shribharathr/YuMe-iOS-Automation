//
//  YuMeSizeViewController.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/14/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeSizeViewController.h"
#import "YuMeAppUtils.h"
#import "YuMeAppSettings.h"

@interface YuMeSizeViewController () {
    
}
/* The scroll view height */
@property (nonatomic) float sizeScrollHeight;

@property(nonatomic, assign) float adRectPortraitX;
@property(nonatomic, assign) float adRectPortraitY;
@property(nonatomic, assign) float adRectPortraitWidth;
@property(nonatomic, assign) float adRectPortraitHeight;
@property(nonatomic, assign) float adRectLandscapeX;
@property(nonatomic, assign) float adRectLandscapeY;
@property(nonatomic, assign) float adRectLandscapeWidth;
@property(nonatomic, assign) float adRectLandscapeHeight;

@end //@interface YuMeSizeViewController

@implementation YuMeSizeViewController

- (void)dealloc {
    [self deInitialize];
}

- (void)initialize {
    self.sizeScrollHeight = 0.0f;
    
    self.adRectPortraitX = 0.0f;
    self.adRectPortraitY = 0.0f;
    self.adRectPortraitWidth = 0.0f;
    self.adRectPortraitHeight = 0.0f;
    self.adRectLandscapeX = 0.0f;
    self.adRectLandscapeY = 0.0f;
    self.adRectLandscapeWidth = 0.0f;
    self.adRectLandscapeHeight = 0.0f;
}

- (void)deInitialize {
    self.txtPortraitX = nil;
    self.txtPortraitY = nil;
    self.txtPortraitWidth = nil;
    self.txtPortraitHeight = nil;
    self.lblMaxPortraitWidth = nil;
    self.lblMaxPortraitHeight = nil;
    self.txtLandscapeX = nil;
    self.txtLandscapeY = nil;
    self.txtLandscapeWidth = nil;
    self.txtLandscapeHeight = nil;
    self.lblMaxLandscapeWidth = nil;
    self.lblMaxLandscapeHeight = nil;
    self.sizeScrollView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.sizeScrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.sizeScrollView.contentSize = contentRect.size;
    self.sizeScrollHeight = contentRect.size.height;
    
    self.sizeScrollView.frame = self.view.frame;
    [self.view addSubview:self.sizeScrollView];
    
    //add the toolbar to the number keypad
    UIToolbar *numberToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.tintColor = [UIColor darkGrayColor];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneWithNumberPad)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [[NSArray alloc] initWithObjects:flex, barButtonItem, nil];
    [numberToolbar setItems:items];
    barButtonItem = nil;
    flex = nil;
    items = nil;
    
    self.txtPortraitX.inputAccessoryView = numberToolbar;
    self.txtPortraitY.inputAccessoryView = numberToolbar;
    self.txtPortraitWidth.inputAccessoryView = numberToolbar;
    self.txtPortraitHeight.inputAccessoryView = numberToolbar;
    self.txtLandscapeX.inputAccessoryView = numberToolbar;
    self.txtLandscapeY.inputAccessoryView = numberToolbar;
    self.txtLandscapeWidth.inputAccessoryView = numberToolbar;
    self.txtLandscapeHeight.inputAccessoryView = numberToolbar;
    numberToolbar = nil;
    
    [self updateValues];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self orientationChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    //Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self orientationChanged];
}

- (IBAction)onEnableFSModeSwitchValueChanged {
    [self setNonFSControlsEnabledStatus:!(self.swEnableFSMode.on)];
}

- (void)setNonFSControlsEnabledStatus:(BOOL)bEnable {
    //set the enabled status
    [self.txtPortraitX setEnabled:bEnable];
    [self.txtPortraitY setEnabled:bEnable];
    [self.txtPortraitWidth setEnabled:bEnable];
    [self.txtPortraitHeight setEnabled:bEnable];
    [self.txtLandscapeX setEnabled:bEnable];
    [self.txtLandscapeY setEnabled:bEnable];
    [self.txtLandscapeWidth setEnabled:bEnable];
    [self.txtLandscapeHeight setEnabled:bEnable];
    
    //set the background color
    UIColor *bgColor = (bEnable ? [UIColor whiteColor] : [UIColor grayColor]);
    [self setNonFSControlsBGColor:bgColor];
}

- (void)setNonFSControlsBGColor:(UIColor *)bgColor {
    [self.txtPortraitX setBackgroundColor:bgColor];
    [self.txtPortraitY setBackgroundColor:bgColor];
    [self.txtPortraitWidth setBackgroundColor:bgColor];
    [self.txtPortraitHeight setBackgroundColor:bgColor];
    [self.txtLandscapeX setBackgroundColor:bgColor];
    [self.txtLandscapeY setBackgroundColor:bgColor];
    [self.txtLandscapeWidth setBackgroundColor:bgColor];
    [self.txtLandscapeHeight setBackgroundColor:bgColor];
}

- (void)doneWithNumberPad {
    [self.txtPortraitX resignFirstResponder];
    [self.txtPortraitY resignFirstResponder];
    [self.txtPortraitWidth resignFirstResponder];
    [self.txtPortraitHeight resignFirstResponder];
    [self.txtLandscapeX resignFirstResponder];
    [self.txtLandscapeY resignFirstResponder];
    [self.txtLandscapeWidth resignFirstResponder];
    [self.txtLandscapeHeight resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)saveAction:(id)sender {
    YuMeAppSettings *settings = [YuMeAppSettings readSettings];
    
    CGRect r = [self getPortraitValues];
    self.adRectPortraitX = r.origin.x;
    self.adRectPortraitY = r.origin.y;
    self.adRectPortraitWidth = r.size.width;
    self.adRectPortraitHeight = r.size.height;
    
    CGSize maxValues = [YuMeAppUtils getMaxUsableScreenBoundsInPortrait];
    if (self.adRectPortraitWidth == 0)
        self.adRectPortraitWidth = maxValues.width;
    
    if (self.adRectPortraitHeight == 0)
        self.adRectPortraitHeight = maxValues.height;
    
    r = [self getLandscapeValues];
    self.adRectLandscapeX = r.origin.x;
    self.adRectLandscapeY = r.origin.y;
    self.adRectLandscapeWidth = r.size.width;
    self.adRectLandscapeHeight = r.size.height;
    
    maxValues = [YuMeAppUtils getMaxUsableScreenBoundsInLandscape];
    if (self.adRectLandscapeWidth == 0)
        self.adRectLandscapeWidth = maxValues.width;
    
    if (self.adRectLandscapeHeight == 0)
        self.adRectLandscapeHeight = maxValues.height;
    
    settings.adRectPortrait = CGRectMake(self.adRectPortraitX, self.adRectPortraitY, self.adRectPortraitWidth, self.adRectPortraitHeight);
    settings.adRectLandscape = CGRectMake(self.adRectLandscapeX, self.adRectLandscapeY, self.adRectLandscapeWidth, self.adRectLandscapeHeight);
    
    settings.bEnableFSMode = self.swEnableFSMode.on;
    
    [YuMeAppSettings saveSettings:settings];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancelAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateValues {
    YuMeAppSettings *settings = [YuMeAppSettings readSettings];
    
    self.txtPortraitX.delegate = self.txtPortraitY.delegate = self.txtPortraitWidth.delegate = self.txtPortraitHeight.delegate = self;
    self.txtLandscapeX.delegate = self.txtLandscapeY.delegate = self.txtLandscapeWidth.delegate = self.txtLandscapeHeight.delegate = self;
    
    self.txtPortraitX.text = [[NSNumber numberWithFloat:settings.adRectPortrait.origin.x] stringValue];
    self.txtPortraitY.text = [[NSNumber numberWithFloat:settings.adRectPortrait.origin.y] stringValue];
    self.txtPortraitWidth.text = [[NSNumber numberWithFloat:settings.adRectPortrait.size.width] stringValue];
    self.txtPortraitHeight.text = [[NSNumber numberWithFloat:settings.adRectPortrait.size.height] stringValue];
    
    self.txtLandscapeX.text = [[NSNumber numberWithFloat:settings.adRectLandscape.origin.x] stringValue];
    self.txtLandscapeY.text = [[NSNumber numberWithFloat:settings.adRectLandscape.origin.y] stringValue];
    self.txtLandscapeWidth.text = [[NSNumber numberWithFloat:settings.adRectLandscape.size.width] stringValue];
    self.txtLandscapeHeight.text = [[NSNumber numberWithFloat:settings.adRectLandscape.size.height] stringValue];
    
    CGSize maxValues = [YuMeAppUtils getMaxUsableScreenBoundsInPortrait];
    self.lblMaxPortraitWidth.text = [NSString stringWithFormat:@"%6.2f", maxValues.width];
    self.lblMaxPortraitHeight.text = [NSString stringWithFormat:@"%6.2f", maxValues.height];
    
    maxValues = [YuMeAppUtils getMaxUsableScreenBoundsInLandscape];
    self.lblMaxLandscapeWidth.text = [NSString stringWithFormat:@"%6.2f", maxValues.width];
    self.lblMaxLandscapeHeight.text = [NSString stringWithFormat:@"%6.2f", maxValues.height];
    
    self.swEnableFSMode.on = settings.bEnableFSMode;
    [self setNonFSControlsEnabledStatus:!(self.swEnableFSMode.on)];
}

- (CGRect)getPortraitValues {
    return CGRectMake([self.txtPortraitX.text floatValue], [self.txtPortraitY.text floatValue], [self.txtPortraitWidth.text floatValue], [self.txtPortraitHeight.text floatValue]);
}

- (CGRect)getLandscapeValues {
    return CGRectMake([self.txtLandscapeX.text floatValue], [self.txtLandscapeY.text floatValue], [self.txtLandscapeWidth.text floatValue], [self.txtLandscapeHeight.text floatValue]);
}

- (void)orientationChanged {
    CGRect mainViewRect = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation];
    self.view.frame = CGRectMake(0, 0, (mainViewRect.size.width), (mainViewRect.size.height));
    self.sizeScrollView.frame = CGRectMake(0, 0, (mainViewRect.size.width), ((mainViewRect.size.height) - 20));
    self.sizeScrollView.contentSize = CGSizeMake(mainViewRect.size.width, self.sizeScrollHeight);
    [self handleOrientation];
}

- (void)handleOrientation {
    CGRect frame = CGRectZero;
    
    frame = self.btnSave.frame;
    frame.origin.x = (self.view.frame.size.width / 2) + 20;
    self.btnSave.frame = frame;
    
    frame = self.btnCancel.frame;
    frame.origin.x = (self.view.frame.size.width / 2) - (frame.size.width) - 20;
    self.btnCancel.frame = frame;
}

@end //@implementation YuMeSizeViewController
