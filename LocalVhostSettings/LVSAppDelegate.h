//
//  LVSAppDelegate.h
//  LocalVhostSettings
//
//  Created by Zoltán Tolnai on 2012.03.17..
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LVSAppDelegate : NSObject <NSApplicationDelegate,NSMenuDelegate>{
	NSStatusItem *statusItem;
}

@property (assign) IBOutlet NSWindow *window;

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
