/*
 * AIAppleScriptPlugin.m
 * Breakaway
 * Created by Kevin Nygaard on 8/8/08.
 * Copyright 2008 Kevin Nygaard.
 *
 * This file is part of Breakaway.
 *
 * Breakaway is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Breakaway is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Breakaway.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "defines.h"
#import "AIAppleScriptPlugin.h"
#import "AIAppleScript.h"

static NSBundle *PluginBundle = nil;

@implementation AIAppleScriptPlugin

@synthesize enabled,prefView;

/******************************************************************************
 * initializeClass:
 *
 * Required
 * Someone is using the plugin's principle class. It is your responsibility to
 * hand onto the pluginBundle. Simply retain the bundle, and release it on
 * terminateClass
 * Return TRUE on good return, and FALSE on error
 *****************************************************************************/
+ (BOOL)initializeClass:(NSBundle*)pluginBundle
{
    if (!pluginBundle) return FALSE;
    PluginBundle = [pluginBundle retain];
    return YES;
}

/******************************************************************************
 * terminateClass
 *
 * Required
 * Someone is not using your class anymore. Release the bundle object, as we
 * don't need it anymore
 * Return TRUE on good return, and FALSE on error
 *****************************************************************************/
+ (void)terminateClass
{
    if (!PluginBundle) return;
    [PluginBundle release];
    PluginBundle = nil;
}

/******************************************************************************
 * name
 *
 * Required by protocol
 * The name of the plugin
 *****************************************************************************/
- (NSString*)name
{
    return @"AppleScript Plugin";
}

/******************************************************************************
 * image
 *
 * Required by protocol
 * The icon of the plugin
 *****************************************************************************/
- (NSImage*)image
{
    return [NSImage imageNamed:@"AppleScript"];
}

- (void)setEnabled:(BOOL)val
{
    [[NSUserDefaults standardUserDefaults] setBool:val forKey:@"AppleScriptPluginEnabled"];
    enabled = val;
}

/******************************************************************************
 * initWithController:
 *
 * Initializer for the plugin. Called upon instantiation.
 * Sets up global variables
 * The controller is the main Breakaway instance (AppController). You can call
 * Growl functions, and operate call CA functions
 *****************************************************************************/
- (id)initWithController:(id)controller
{
	if (!(self = [super init])) return nil;
	
    [NSBundle loadNibNamed:@"AppleScriptPlugin" owner:self];
    appController = controller;
    enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AppleScriptPluginEnabled"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(delaySave)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:[self managedObjectContext]];
    
    NSLog(@"AppleScript plugin successfully loaded");
    
	return self;
}

/******************************************************************************
 * delaySave
 *
 * Saves after 10ms delay
 *****************************************************************************/
- (void)delaySave
{
    [self performSelector:@selector(saveAction:) withObject:self afterDelay:(NSTimeInterval)0.010];
}

/******************************************************************************
 * dealloc
 *
 * Called when plugin is destroyed. Cleans up
 *****************************************************************************/
- (void)dealloc
{    
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
    
    [super dealloc];
}

/******************************************************************************
 * activate:
 *
 * Required by the protocol
 * Called during a CoreAudio interrupt. triggerMask contains the interrupt mask,
 * which is the jack status, mute status, and reason for interrupt (either mute
 * or data source change)
 *****************************************************************************/
- (void)activate:(kTriggerMask)triggerMask
{    
    // Don't need to do anything if iTunes is not running, or, we are disabled
    if (!enabled) return;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AppleScript" inManagedObjectContext:context];
    [request setEntity:entity];
    
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"enabled == true"];
    [request setPredicate:searchFilter];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    for (AIAppleScript *script in results)
        [script activate: triggerMask];
    
    [request release];
    
}

#pragma mark CoreData

/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "AppleScriptPlugin" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Breakaway"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:PluginBundle]] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"Breakaway_AppleScriptPlugin.xml"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType 
                                                  configuration:nil 
                                                            URL:url 
                                                        options:nil 
                                                          error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext) return managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
    
    return managedObjectContext;
}

/**
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
    
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

#pragma mark OLD
#if 0
// this is how we load our instances. exactly how it was done in old trigger days
-(id)initFromDictionary:(NSDictionary*)attributes
{	
	if (!(self = [super init])) return nil;
	
	//if ([attributes count] < 10) { NSLog(@"Not enough attributes to pop. Returning NULL."); return NULL; }
	
    [self setName:[attributes objectForKey:@"name"]];
	
	// Modes
    [self setnMode:[[attributes objectForKey:@"nmode"]boolValue]];
	[self sethpMode:[[attributes objectForKey:@"hpmode"]boolValue]];
	
	// Triggers
	[self setMute:[[attributes objectForKey:@"mute"]boolValue]];
	[self setUnmute:[[attributes objectForKey:@"unmute"]boolValue]];
	[self setHin:[[attributes objectForKey:@"hin"]boolValue]];
	[self setHout:[[attributes objectForKey:@"hout"]boolValue]];
	
    [self setLod:[[attributes objectForKey:@"lod"]intValue]];
	[self setScript:[attributes objectForKey:@"script"]];
	[self setEnabled:[[attributes objectForKey:@"enabled"]boolValue]];
	
	[self setFamilyCode];
	
	// if we aren't loading on demand, compile now and be done with it
	if (!lod) [self compile];
	
	// we cant use [NSImage imageNamed:@"notfoundover.png"] because it doesnt look at our plugin bundle path
	// we have to do this in order to get a full path to our bundle resources
	notFoundImage = [[NSImage alloc]initByReferencingFile:
					 [[[NSBundle bundleForClass:[self class]]
					   resourcePath]stringByAppendingPathComponent:@"notfoundover.png"]];
	
	return self;
}

- (NSColor*)scriptTextColor
{
	if ([self valid]) return [NSColor blackColor];
	else  return [NSColor redColor];
}

- (NSImage*)image
{
	if ([self valid]) return [[NSWorkspace sharedWorkspace] iconForFile:script];
	else return notFoundImage;
}

#pragma mark Script Functions

-(void)compile
{
	if([applescript source]== nil) [self setScript:nil];
	[applescript compileAndReturnError:nil];
}

- (void)activate:(int)prototype
{
	NSLog(@"::Launching Script::\n::%@::\n::%@::",[applescript source],[applescript isCompiled]?@"COMPILED":@"NOT COMPILED");
	if (![applescript isCompiled]) [applescript performSelectorOnMainThread:@selector(compileAndReturnError:) withObject:nil waitUntilDone:NO];
	[applescript performSelectorOnMainThread:@selector(executeAndReturnError:) withObject:nil waitUntilDone:NO];
}


#pragma mark KVC Accessors
//{{{ KVC Functions

-(BOOL)valid
{
	if([[NSFileManager defaultManager]fileExistsAtPath:script])
	{
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}

-(BOOL)modeSelected
{
	int tmp = (hpmode||nmode)?1:0;
	return tmp;
}

-(NSString*)name
{
	return name;
}

-(BOOL)nmode
{
	return nmode;
}

-(BOOL)hpmode
{
	return hpmode;
}

-(BOOL)mute
{
	return mute;
}

-(BOOL)unmute
{
	return unmute;
}

-(BOOL)hin
{
	return hin;
}

-(BOOL)hout
{
	return hout;
}

-(NSString*)script
{
	return script;
}

-(int)lod
{
	return lod;
}

-(BOOL)enabled
{
	return enabled;
}

- (int)familyCode
{
	return familyCode;
}

-(void)setModeSelected:(BOOL)var
{
	modeSelected = var;
}

//}}}

#pragma mark KVC sets
//{{{

-(void)setScript:(NSString*)var
{
	// If we pass a null string, just run through our stuff, as we probably just want to reset up our scripts
	if(var)
	{
		[script release];
		script = [var retain];
	}
	
    if(applescript) [applescript release];
	
	// If the script we are given is a path
	if([[NSFileManager defaultManager]fileExistsAtPath:script])
	{
		applescript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath: script] error:nil];
		[self setValid:TRUE];
		[self compile];
	}
	else
	{
		[self setEnabled:FALSE];
		[self setValid:FALSE];
	}
}

-(void)setEnabled:(BOOL)var
{	
	if([[NSFileManager defaultManager]fileExistsAtPath:script])
	{
		[self setValid:TRUE];
		enabled = var;
		[self setFamilyCode];
	}
	else
	{
		enabled = FALSE;
		[self setValid:FALSE];
		[self setFamilyCode];
	}
}

-(void)setFamilyCode
{	
	int tmpFcode = 0;
	
    if (enabled) tmpFcode = tmpFcode | BATriggerEnabledMask;
    if (nmode) tmpFcode = tmpFcode | BANormalModeMask;
    if (hpmode) tmpFcode = tmpFcode | BAHeadphonesModeMask;
    if (mute) tmpFcode = tmpFcode | BAMuteMask;
    if (unmute) tmpFcode = tmpFcode | BAUnmuteMask;
    if (hin) tmpFcode = tmpFcode | BAHeadphonesJackInMask;
    if (hout) tmpFcode = tmpFcode | BAHeadphonesJackOutMask;
    
	familyCode = tmpFcode;
}

-(void)setName:(NSString*)var
{
	[name release];
	name = [var retain];
}

-(void)setnMode:(BOOL)var
{
	nmode = var;
	[self setFamilyCode];
}

-(void)sethpMode:(BOOL)var
{
	hpmode = var;
	[self setFamilyCode];
}

-(void)setMute:(BOOL)var
{
	mute = var;
	[self setFamilyCode];
}

-(void)setUnmute:(BOOL)var
{
	unmute = var;
	[self setFamilyCode];
}

-(void)setHin:(BOOL)var
{
	hin = var;
	[self setFamilyCode];
}

-(void)setHout:(BOOL)var
{
	hout = var;
	[self setFamilyCode];
}

-(void)setLod:(int)var
{
	lod = var;
}

-(void)setValid:(BOOL)var
{
	valid = var;
}

#pragma mark End Operations
-(NSDictionary*)export
{
	//NSLog(@"%@,%i,%i,%i,%@, %i",name,mode,trigger,lod,script,enabled);
	NSDictionary* tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:
							 name, @"name",
							 [NSNumber numberWithBool:nmode], @"nmode",
							 [NSNumber numberWithBool:hpmode], @"hpmode",
							 [NSNumber numberWithBool:mute], @"mute",
							 [NSNumber numberWithBool:unmute], @"unmute",
							 [NSNumber numberWithBool:hin], @"hin",
							 [NSNumber numberWithBool:hout], @"hout",
							 [NSNumber numberWithInt:lod], @"lod",
							 script,@"script",
							 [NSNumber numberWithBool:enabled], @"enabled",
							 nil];
	return tmpDict;
}

-(void)dealloc
{
    if (applescript) [applescript release];
    if (name) [name release];
    if (script) [script release];
	[notFoundImage release];
    [super dealloc];
}
#endif
@end
