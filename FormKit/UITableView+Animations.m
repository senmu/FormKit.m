//
//  UITableView+Animations.m
//  WestJet Cares
//
//  Created by Sam Lu on 8/31/12.
//  Copyright (c) 2012 WestJet. All rights reserved.
//

#import "UITableView+Animations.h"
#import <QuartzCore/QuartzCore.h>

@implementation UITableView (Animations)

- (void)reloadData:(BOOL)animated
{
    [self reloadData];
    
    if (animated) {
        
        CATransition *animation = [CATransition animation];
        [animation setDelegate:self];
        [animation setDuration:1.0f];
        animation.startProgress = 0;
        animation.endProgress   = 1;
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        animation.type = @"pageUnCurl";
        animation.subtype=@"fromTop";
        animation.fillMode = kCAFillModeForwards;
        
        [animation setRemovedOnCompletion:NO];
        [animation setFillMode: @"extended"];
        [animation setRemovedOnCompletion: NO];
        [[self layer] addAnimation:animation forKey:@"WebPageCurl"];
        
    }
}

@end
