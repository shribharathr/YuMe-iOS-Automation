//
//  YuMeToast.m
//  YuMeZISTestApp
//
//  Created by Senthil on 11/17/14.
//  Copyright (c) 2014 YuMe. All rights reserved.
//

#import "YuMeToast.h"
#import "YuMeAppConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "YuMeAppUtils.h"

@implementation YuMeToast

- (id)initWithText: (NSString *)pMsg {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        self.textColor = [UIColor colorWithWhite:0 alpha:1];
        self.font = [UIFont fontWithName:@"Helvetica-Bold" size: 15];
        self.text = pMsg;
        self.textAlignment = YUME_TEXT_ALIGNMENT_CENTER;
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    }
    return self;
}

- (void)didMoveToSuperview {
    UIView *parent = self.superview;
    
    if(parent) {
        CGRect screenRect = [YuMeAppUtils getCurrentScreenBoundsBasedOnOrientation];
        CGSize maximumLabelSize = CGSizeMake(screenRect.size.width, screenRect.size.height);
        
        CGSize expectedLabelSize = [self.text sizeWithFont:self.font constrainedToSize:maximumLabelSize lineBreakMode:NSLineBreakByTruncatingTail];
        expectedLabelSize = CGSizeMake(expectedLabelSize.width + 20, expectedLabelSize.height + 10);
        
        self.frame = CGRectMake(((screenRect.size.width / 2) - (expectedLabelSize.width / 2)),
                                ((screenRect.size.height) - (expectedLabelSize.height)),
                                expectedLabelSize.width,
                                expectedLabelSize.height);
        
        CALayer *layer = self.layer;
        layer.cornerRadius = 4.0f;
       
        [self performSelectorOnMainThread:@selector(dismissToast:) withObject:nil waitUntilDone:NO];
    }
}

- (void)dismissToast:(id)sender {
    [self performSelector:@selector(dismiss:) withObject:nil afterDelay:YUME_APP_TOAST_DURATION];
}

- (void)dismiss:(id)sender {
    // Fade out the message and destroy self
    [UIView animateWithDuration:0.6 delay:0 options:UIViewAnimationOptionAllowUserInteraction
                     animations:^ {
                         self.alpha = 0;
                     } completion:^ (BOOL finished) {
                         [self removeFromSuperview];
                     }];
}

@end //@implementation YuMeToast
