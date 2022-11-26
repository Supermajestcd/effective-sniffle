/**
 * IconDownloader.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <Foundation/Foundation.h>

@class AppItem;

@interface IconDownloader : NSObject

@property (nonatomic, strong) AppItem *appItem;
@property (nonatomic, copy) void (^completionHandler)(void);

// Interface to control downloads
- (void)startDownload;
- (void)cancelDownload;

@end
