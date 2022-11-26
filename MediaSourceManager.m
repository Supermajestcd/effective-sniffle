/**
 * MediaSourceManager.m
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <Foundation/Foundation.h>
#import "MediaSourceManager.h"

@interface MediaSourceManager ()

@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;
@property (nonatomic, strong) NSString *databasePath;

@end

@implementation MediaSourceManager

// -------------------------------------------------------------------------------
// init
// -------------------------------------------------------------------------------
- (id)init {
    self = [super init];
    if (self) {
        // Prepare the DB
        // Set the documents directory path to the documentsDirectory property.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsDirectory = [paths objectAtIndex:0];
        self.databaseFilename = @"FlingSample.json";
        [self copyDatabaseIntoDocumentsDirectory];
    }
    
    return self;
}

// -------------------------------------------------------------------------------
// copyDatabaseIntoDocumentsDirectory
// -------------------------------------------------------------------------------
- (void) copyDatabaseIntoDocumentsDirectory {
    // Check if the database file exists in the documents directory.
    self.databasePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    NSLog(@"Database path = %@", self.databasePath);
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.databasePath]) {
        // The database file does not exist in the documents directory, so copy it from the main bundle now.
        NSLog(@"The database file does not exist in the documents directory, so copy it from the main bundle now");
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:self.databasePath error:&error];
        
        // Check if any error occurred during copying and display it.
        if (error != nil) {
            NSLog(@"Error while copyItemAtPath - %@", [error localizedDescription]);
        }
    }
}

// -------------------------------------------------------------------------------
// getAllSources
// -------------------------------------------------------------------------------
- (NSMutableArray*) getAllSources {
    NSMutableArray* sources = [[NSMutableArray alloc] init];
    
    // Read into data string
    NSString* contentsOfDB;
    NSError *error;
    contentsOfDB = [NSString stringWithContentsOfFile:self.databasePath encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) {
        NSLog(@"Error while stringWithContentsOfFile - %@", [error localizedDescription]);
    }
    
    if (contentsOfDB != nil) {
        NSData *jsonData = [contentsOfDB dataUsingEncoding:NSUTF8StringEncoding];
        NSArray* sourcesInDB = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if (sourcesInDB != nil) {
            for (NSDictionary* properties in sourcesInDB) {
                // String was correctly formatted, extract the fields
                NSString* title = [properties objectForKey: @"title"];
                NSString* url = [properties objectForKey: @"url"];
                NSDictionary* metadata = [properties objectForKey: @"metadata"];
                NSString* iconUrl = [properties objectForKey: @"iconUrl"];
                if (title != nil && url != nil && metadata != nil) {
                    MediaSource* source = [[MediaSource alloc] init];
                    source.title = title;
                    source.url = url;
                    source.metadata = metadata;
                    source.iconUrl = iconUrl;
                    [sources addObject:source];
                } else {
                    NSLog(@"Error while parsing record - mandatory field missing");
                }
            }
            
            NSLog(@"Found %lu records in DB", (unsigned long)[sources count]);
        } else {
            NSLog(@"Error while parsing DB");
        }
    }

    return sources;
}

@end