/**
 * AppDelegate.m
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

// -------------------------------------------------------------------------------
//	application:didFinishLaunchingWithOptions:
//  Initialize the main view and its subviews.
// -------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

// -------------------------------------------------------------------------------
//	application:applicationWillResignActives:
//  Send out notification
// -------------------------------------------------------------------------------
- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"$$applicationWillResignActive");
    [[NSNotificationCenter defaultCenter] postNotificationName: @"willResignActive"
                                                        object: nil
                                                      userInfo: nil];
}

// -------------------------------------------------------------------------------
//	application:applicationDidBecomeActive:
//  Send out notification
// -------------------------------------------------------------------------------
- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"$$applicationDidBecomeActive");
    [[NSNotificationCenter defaultCenter] postNotificationName: @"willEnterForegound"
                                                        object: nil
                                                      userInfo: nil];
}

@end
