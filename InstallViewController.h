/**
 * InstallViewController.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <UIKit/UIKit.h>
#import <AmazonFling/InstallDiscoveryController.h>

@interface InstallViewController : UIViewController<InstallDiscoveryListener, UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *appItemListTable;

@end

