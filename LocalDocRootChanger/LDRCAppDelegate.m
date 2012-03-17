// Copyright (C) 2012 Zoltan Tolnai
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
// to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of
// the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

#import "LDRCAppDelegate.h"

@implementation LDRCAppDelegate

@synthesize window = _window;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize statusMenu = _statusMenu;

- (NSMenu *) statusMenu{
	if( ! _statusMenu) {
		_statusMenu = [[NSMenu alloc] initWithTitle:@""];
	}
	return _statusMenu;
}



- (IBAction)quit:(id)sender{
    [[NSApplication sharedApplication] terminate:self];
}

- (void)menuWillOpen:(NSMenu *)menu {
	[statusItem setImage:[NSImage imageNamed:@"icon-w.png"]];
	[self.statusMenu removeAllItems];
	NSString *dir = [@"~/Dropbox/Munka/" stringByExpandingTildeInPath];
	NSFileManager *fm = [NSFileManager defaultManager];

	NSString *currentSymlink = @"";
	if([fm isReadableFileAtPath:[@"~/Sites/htdocs" stringByExpandingTildeInPath]]) {
		currentSymlink = [[@"~/Sites/htdocs" stringByResolvingSymlinksInPath] lastPathComponent];
	}

	BOOL isDir;
	int i = 0;
	NSArray *dirContents = [fm contentsOfDirectoryAtPath:dir error:nil];
	for (NSString *f in dirContents) {
		NSString *keyeq = @"";
		if (i<10) {
			keyeq = [NSString stringWithFormat:@"%d",i];
		}

		NSString *file = [[dir stringByAppendingString:@"/"] stringByAppendingString:f];
		if ([fm fileExistsAtPath:file isDirectory:&isDir] && isDir) {
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:f action:@selector(changeVhost:) keyEquivalent:keyeq];
			if([f isEqualToString:currentSymlink]) {
				menuItem.state = YES;
			}
			[self.statusMenu insertItem:menuItem atIndex: i-1];
		}
		i++;
	}
	[self.statusMenu insertItem:[NSMenuItem separatorItem] atIndex:i-1];
	NSMenuItem *quitMenu = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"q"];
	[self.statusMenu insertItem:quitMenu atIndex:i];
}

- (void)menuDidClose:(NSMenu *)menu{
    [statusItem setImage:[NSImage imageNamed:@"icon.png"]];
}

- (void)changeVhost:(NSMenuItem *)sender{
	NSFileManager *fm = [NSFileManager defaultManager];
//	NSError *error = [[NSError alloc] init];

	[fm removeItemAtPath: [@"~/Sites/htdocs" stringByExpandingTildeInPath] error: nil];
	NSString *dir = [@"~/Dropbox/Munka/" stringByExpandingTildeInPath];
	[fm createSymbolicLinkAtPath:[@"~/Sites/htdocs" stringByExpandingTildeInPath] withDestinationPath:[[dir stringByAppendingString:@"/"] stringByAppendingString:sender.title] error:nil];
//	NSLog(@"%@",[error localizedDescription]);
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	[self.statusMenu setDelegate:self];
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setMenu:self.statusMenu];
	[statusItem setHighlightMode:YES];
	[statusItem setImage:[NSImage imageNamed:@"icon.png"]];

}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "tony.LocalDocRootChanger" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"tony.LocalDocRootChanger"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel) {
        return __managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LocalDocRootChanger" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;

    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];

    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![[properties objectForKey:NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];

            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];

            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }

    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"LocalDocRootChanger.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __persistentStoreCoordinator = coordinator;

    return __persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];

    return __managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.

    if (!__managedObjectContext) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];

        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
