/**
 * InstallViewController.m
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

// -------------------------------------------------------------------------------
// RemoteInstallApp Sample
//
// This sample showcases app install use case that might be insteresting for the
// developers at large. The target developers are those who have an app available
// on the Amazon Fire TV and a companion app on iOS devices. The Amazon App
// Install Service allows the user to check if an app is installed on the Fire TV
// as well as initiate installation of the app if it not installed.
//
// InstallViewController class is the primary controller in this app. Please refer
// to the methods of this class vis a vis the following use cases
//
// 1. Check if your app is installed on a Fire TV
//    - When the user selects a Fire TV, your application will call the API
//      getInstalledPackageVersion which the Android package name of your app.
//
// 2. Install your app on the Fire TV
//    - If the app is not installed on a Fire TV, you can invoke the installByASIN
//      API to start installation process on Fire TV. The result of calling this API
//      is that the AppStore page of your application will be launched on the Fire
//      TV. The user must continue the process using their Fire TV Remote. Please
//      refer to the UI helper showInstallationAlert.
//
// 3. Launch your app on the Fire TV
//    - This use case is not a primary use case for the app install service.
//      However, calling the same installByASIN API, we can launch the same AppStore
//      page for your application. The user can then open the already installed
//      application using their Fire TV Remote. Please refer to the UI helper
//      showInstallationAlert.
// -------------------------------------------------------------------------------

#import <AmazonFling/RemoteInstallService.h>
#import "InstallViewController.h"
#import "AppItemManager.h"
#import "IconDownloader.h"

@interface FireTV : NSObject

@property id<RemoteInstallService> device;
@property BOOL appInstalled;

@end

@implementation FireTV

@end

// -------------------------------------------------------------------------------
// View controller implementation
// -------------------------------------------------------------------------------
@interface InstallViewController ()

@property NSMutableArray* appItemsList;
@property InstallDiscoveryController* controller;
@property NSMutableArray* deviceList;
@property AppItem* selectedAppItem;
@property NSMutableArray *presentedDevices;
@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;

@end

@implementation InstallViewController

#pragma mark - View callbacks

// -------------------------------------------------------------------------------
//	viewDidLoad - called when the view is loaded, usually once in the app
//                lifecycle
// -------------------------------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Load apps database
    AppItemManager* manager = [[AppItemManager alloc] init];
    self.appItemsList = [manager getAllSources];
    
    // Install service discovery
    self.controller = [[InstallDiscoveryController alloc] init];
    [self.controller searchInstallServiceWithListener:self];
    
    // Device list
    self.deviceList = [[NSMutableArray alloc] init];

    // Subscribe to the notifications
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(suspend)
                                                 name: @"willResignActive"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(resume)
                                                 name: @"willEnterForegound"
                                               object: nil];
    // App list rendering
    self.appItemListTable.dataSource = self;
    self.appItemListTable.delegate = self;
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
}

// -------------------------------------------------------------------------------
//	dealloc
//  If this view controller is going away, we need to cancel all outstanding downloads.
// -------------------------------------------------------------------------------
- (void)dealloc {
    // terminate all pending download connections
    [self terminateAllDownloads];
}

// -------------------------------------------------------------------------------
//	didReceiveMemoryWarning - called when the device is running low on memory
// -------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    // terminate all pending download connections
    [self terminateAllDownloads];
}

#pragma mark - Remote Install LifeCycle

// -------------------------------------------------------------------------------
//	resume
// -------------------------------------------------------------------------------
- (void)resume {
    NSLog(@"$$resume");
    [self.controller resume];
}

// -------------------------------------------------------------------------------
//	suspend
// -------------------------------------------------------------------------------
- (void)suspend {
    NSLog(@"$$suspend");
    [self.deviceList removeAllObjects];
    [self.controller close];
}

#pragma mark - Install discovery callbacks

// -------------------------------------------------------------------------------
// Discovery callback - called when a new device is available on the network
// -------------------------------------------------------------------------------
-(void)installServiceDiscovered:(id<RemoteInstallService>)device {
    @synchronized(self) {
        // Add to the list of available devices
        FireTV* item = [[FireTV alloc] init];
        item.device = device;
        item.appInstalled = NO;
        [self.deviceList addObject:item];
        // Check if the app is installed on this device
        if (self.selectedAppItem != nil) {
            [[item.device getInstalledPackageVersion:self.selectedAppItem.packageName]
                continueWithBlock:^id(BFTask *task) {
                if (task.error == nil) {
                    NSString* result = (NSString*)task.result;
                    if ([result compare:RIS_PACKAGE_NOT_INSTALLED] != NSOrderedSame) {
                        item.appInstalled = YES;
                    } else {
                        item.appInstalled = NO;
                    }
                } else {
                    item.appInstalled = NO;
                }
                return nil;
            }];
        }
    }
}

// -------------------------------------------------------------------------------
// Discovery callback - called when a device disappears from the network
// -------------------------------------------------------------------------------
-(void)installServiceLost:(id<RemoteInstallService>)device {
    @synchronized(self) {
        // Remove from the list of available devices
        for (FireTV* tv in self.deviceList) {
            if ([[tv.device uniqueIdentifier] compare:[device uniqueIdentifier]] == 0) {
                [self.deviceList removeObject:tv];
                break;
            }
        }
    }
}

// -------------------------------------------------------------------------------
// Discovery callback - called when discovery fails for any reason
// -------------------------------------------------------------------------------
-(void)discoveryFailure {
    NSLog(@"Discovery failed");
}

#pragma mark - Refresh timer routine

// -------------------------------------------------------------------------------
// checkFireTVs: Method to check all available FIre TVs
// -------------------------------------------------------------------------------
- (void)checkFireTVsWithCompletionHandler:(void (^)(void))completionBlock {
    @synchronized(self) {
        __block NSUInteger count = [self.deviceList count];
        if (self.selectedAppItem == nil ||
            count == 0) {
            completionBlock();
            return;
        }
        for (FireTV* tv in self.deviceList) {
            [[tv.device getInstalledPackageVersion:self.selectedAppItem.packageName]
                continueWithBlock:^id(BFTask *task) {
                    NSString* result = (NSString*)task.result;
                    if (task.error == nil) {
                        if ([result compare:RIS_PACKAGE_NOT_INSTALLED] != NSOrderedSame) {
                            tv.appInstalled = YES;
                        } else {
                            tv.appInstalled = NO;
                        }
                    } else {
                        tv.appInstalled = NO;
                    }
                    count--;
                    if (count == 0) {
                        completionBlock();
                    }
                    return nil;
            }];
        }
    }
}

#pragma mark - UI table view data source operations

// -------------------------------------------------------------------------------
// Return the current size of the device list, return 1 so that we can display
// "Searching..."
// -------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.appItemsList.count > 0 ? self.appItemsList.count : 1;
}

// -------------------------------------------------------------------------------
// Construct the required cell. If the devices list is empty, just return "Searching"
// -------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"AppItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    if (self.appItemsList.count == 0) {
        cell.textLabel.text = @"Loading...";
    } else if (indexPath.row < self.appItemsList.count) {
        AppItem* appItem = [self.appItemsList objectAtIndex:indexPath.row];
        cell.textLabel.text = appItem.title;
        if (appItem.icon == nil) {
            if (self.appItemListTable.dragging == NO && self.appItemListTable.decelerating == NO) {
                [self startIconDownload:appItem forIndexPath:indexPath];
            }
            cell.imageView.image = [UIImage imageNamed:@"InstallOnFireTV"];
        } else {
            cell.imageView.image = appItem.icon;
        }
    }
    
    return cell;
    
}

#pragma mark - UI interaction helpers

// -------------------------------------------------------------------------------
// appItemDidSelect - Helper routine to select an app
// -------------------------------------------------------------------------------
- (void)appItemDidSelect:(AppItem*)item {
    @synchronized(self) {
        self.selectedAppItem = item;
    }
    // Show that we are working
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self checkFireTVsWithCompletionHandler:^{
        // Show the fire TVs
        dispatch_async(dispatch_get_main_queue(), ^{
            [self firetvSelectionDidStart];
            // Stop showing busy indicator
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    }];
}

// -------------------------------------------------------------------------------
// firetvSelectionDidStart - Helper routine to select an app
// -------------------------------------------------------------------------------
- (void) firetvSelectionDidStart {
    // Copy current list of devices into presented devices array. These two arrays
    // can go out of sync while the action sheet is displayed. The synchronization
    // is handled in UIActionSheetDelegate::clickedButtonAtIndex
    if (self.presentedDevices != nil) {
        [self.presentedDevices removeAllObjects];
        self.presentedDevices = nil;
    }
    @synchronized(self) {
        self.presentedDevices = [[NSMutableArray alloc]initWithArray:self.deviceList];
    }
    UIActionSheet *actionSheet =
    [[UIActionSheet alloc] initWithTitle:@"Connect to Device"
                                delegate:self
                       cancelButtonTitle:nil
                  destructiveButtonTitle:nil
                       otherButtonTitles:nil];

    for (FireTV* tv in self.presentedDevices) {
        NSString* name = [tv.device name];
        NSString* title = name.length > 20 ?
        [[name substringToIndex:20] stringByAppendingString:@"..."] :
        [name stringByPaddingToLength:23 withString:@" " startingAtIndex:0];
        NSString* pickerRow = [NSString stringWithFormat:@"%@     %@", title, tv.appInstalled ? @"✅" : @"⬇"];
        [actionSheet addButtonWithTitle:pickerRow];
    }
    if (self.presentedDevices.count == 0) {
        [actionSheet addButtonWithTitle:@"Searching..."];
    } else {
        [actionSheet addButtonWithTitle:@"Cancel"];
    }
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
    [actionSheet showInView:self.view];
}

// -------------------------------------------------------------------------------
// showInstallationAlert - Helper function to display next steps
// -------------------------------------------------------------------------------
- (void)showInstallationAlert:(NSString*)withMessage
                    andDevice:(id<RemoteInstallService>) selectedTV {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Continue on Fire TV", nil)
                                   message:NSLocalizedString(withMessage, nil)
                                  delegate:nil
                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                         otherButtonTitles:nil];
        [alert show];
    });
}

// -------------------------------------------------------------------------------
// showErrorMessage - Helper function to display error message if
// -------------------------------------------------------------------------------
- (void)showErrorMessage {
    // Show error message
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not Available", nil)
                                   message:NSLocalizedString(@"The device is currently unavailable. Please try again.", nil)
                                  delegate:nil
                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                         otherButtonTitles:nil];
        [alert show];
    });
}

// -------------------------------------------------------------------------------
//	actionSheet:actionSheet buttonIndex
// -------------------------------------------------------------------------------
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [actionSheet cancelButtonIndex]) {
        // Clear the presented devices array if the user cancels
        if (self.presentedDevices != nil) {
            [self.presentedDevices removeAllObjects];
            self.presentedDevices = nil;
        }
        return;
    }
    // Synchronizing current list of devices and the presented devices.
    // Make sure the selected device is still available
    if (self.presentedDevices != nil) {
        if (buttonIndex < (NSInteger)[self.presentedDevices count]) {
            FireTV* selectedTV = [self.presentedDevices objectAtIndex:buttonIndex];
            @synchronized(self) {
                if ([self.deviceList containsObject:selectedTV]) {
                    // Check the current status
                    if (!selectedTV.appInstalled) {
                        // The package is not installed
                        [[selectedTV.device installByASIN:self.selectedAppItem.asin]
                         continueWithBlock:^id(BFTask *task) {
                             if (task.error == nil) {
                                 [self showInstallationAlert:@"Click 'Download' on Fire TV using Fire TV Remote."
                                                   andDevice:selectedTV.device];
                             }
                             return nil;
                         }];
                    } else {
                        // The package is installed
                        [[selectedTV.device installByASIN:self.selectedAppItem.asin]
                         continueWithBlock:^id(BFTask *task) {
                             if (task.error == nil) {
                                 [self showInstallationAlert:@"Click 'Open' on Fire TV using Fire TV Remote."
                                                   andDevice:selectedTV.device];
                             }
                             return nil;
                         }];
                    }
                } else {
                    [self showErrorMessage];
                }
            }
        }
        [self.presentedDevices removeAllObjects];
        self.presentedDevices = nil;
    }
}

// -------------------------------------------------------------------------------
// The action of selecting an app. Search for this app on the network.
// -------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self appItemDidSelect:[self.appItemsList objectAtIndex:indexPath.row]];
}

#pragma mark - Table cell image support

// -------------------------------------------------------------------------------
//	startIconDownload:forIndexPath:
// -------------------------------------------------------------------------------
- (void)startIconDownload:(AppItem *)appItem forIndexPath:(NSIndexPath *)indexPath {
    IconDownloader *iconDownloader = (self.imageDownloadsInProgress)[indexPath];
    if (iconDownloader == nil)  {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.appItem = appItem;
        [iconDownloader setCompletionHandler:^{
            
            UITableViewCell *cell = [self.appItemListTable cellForRowAtIndexPath:indexPath];
            
            // Display the newly loaded image
            cell.imageView.image = appItem.icon;
            
            // Remove the IconDownloader from the in progress list.
            // This will result in it being deallocated.
            [self.imageDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        (self.imageDownloadsInProgress)[indexPath] = iconDownloader;
        [iconDownloader startDownload];
    }
}

// -------------------------------------------------------------------------------
//	loadImagesForOnscreenRows
//  This method is used in case the user scrolled into a set of cells that don't
//  have their app icons yet.
// -------------------------------------------------------------------------------
- (void)loadImagesForOnscreenRows {
    if (self.appItemsList.count > 0) {
        NSArray *visiblePaths = [self.appItemListTable indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths) {
            AppItem* appItem = (self.appItemsList)[indexPath.row];
            
            if (!appItem.icon) {
                // Avoid the app icon download if the app already has an icon
                [self startIconDownload:appItem forIndexPath:indexPath];
            }
        }
    }
}

// -------------------------------------------------------------------------------
//	terminateAllDownloads
// -------------------------------------------------------------------------------
- (void)terminateAllDownloads {
    // terminate all pending download connections
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [self.imageDownloadsInProgress removeAllObjects];
}

#pragma mark - UIScrollViewDelegate

// -------------------------------------------------------------------------------
//	scrollViewDidEndDragging:willDecelerate:
//  Load images for all onscreen rows when scrolling is finished.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadImagesForOnscreenRows];
    }
}

// -------------------------------------------------------------------------------
//	scrollViewDidEndDecelerating:scrollView
//  When scrolling stops, proceed to load the app icons that are on screen.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnscreenRows];
}

@end
