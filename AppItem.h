/**
 * AppItem.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <UIKit/UIKit.h>

@interface AppItem : NSObject

@property NSString* iconurl;
@property NSString* title;
@property NSString* packageName;
@property NSString* asin;
@property UIImage* icon;

@end
