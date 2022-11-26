/**
 * MediaSource.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

@interface MediaSource : NSObject

@property NSString* url;
@property NSString* title;
@property NSDictionary* metadata;
@property NSString* iconUrl;
@property UIImage* icon;

@end
