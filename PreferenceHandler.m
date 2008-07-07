/*
 * PreferenceHandler.m
 * Breakaway
 * Created by Kevin Nygaard on 6/14/06.
 * Copyright 2008 Kevin Nygaard.
 * Plugin template sample code from Rainer Brockerhoff, MacHack 2002.
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

#import "PreferenceHandler.h"
#import "AppController.h"
#import "Sparkle/SUUpdater.h"
#import "AITrigger.h"
#import "defines.h"
#import <sys/sysctl.h>

#define UI_PLIST_LOCATION 23
@implementation PreferenceHandler

// [[[NSApplication sharedApplication]delegate] = AppController
-(void)awakeFromNib
{	
	// Setting up these for plugin stuff
	pluginClasses = [[NSMutableArray alloc] init];
	pluginInstances = [[NSMutableArray alloc] init];
	
	// create our instance array. this is essientially the table
	triggersArray = [NSMutableArray array];
	
	[self loadTriggers];
	
	[triggerArrayController setContent:triggersArray];
	
	// Watch these keypaths on our array controller. if its modified, it will save our triggers to our nsdefauts (via -observeValueForKeyPath:...)
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.enabled" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.name" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.nmode" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.hpmode" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.mute" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.unmute" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.hin" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.hout" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.script" options:nil context:nil];
	[triggerArrayController addObserver:self forKeyPath:@"arrangedObjects.lod" options:nil context:nil];
	
	NSLog(@"preference handler loaded");
	
	// this is used for testing the system (startTest:)
	done=0;
}

#pragma mark 
#pragma mark Plugin Stuff

//	This is called to activate each plug-in, meaning that each candidate bundle is checked,
//	loaded if it seems to contain a valid plug-in, and the plug-in's class' initiateClass
//	method is called. If this returns YES, it means that the plug-in agrees to run and the
//	class is added to the pluginClass array. Some plug-ins might refuse to be activated
//	depending on some external condition.

- (void)activatePlugin:(NSString*)path {
	NSBundle* pluginBundle = [NSBundle bundleWithPath:path];
	if (pluginBundle) {
		NSDictionary* pluginDict = [pluginBundle infoDictionary];
		NSString* pluginName = [pluginDict objectForKey:@"NSPrincipalClass"];
		if (pluginName) {
			Class pluginClass = NSClassFromString(pluginName);
			if (!pluginClass) {
				pluginClass = [pluginBundle principalClass];
				if ([pluginClass conformsToProtocol:@protocol(AITriggerPluginProtocol)] &&
					[pluginClass isKindOfClass:[NSObject class]] &&
					[pluginClass initializeClass:pluginBundle]) {
					[pluginClasses addObject:pluginClass];
				}
			}
		}
	}
}

- (void)instantiatePlugins:(Class)pluginClass {
	NSObject<AITriggerPluginProtocol>* plugin = [[pluginClass alloc]init];
	[pluginInstances addObject:plugin];
	NSLog(@"%@",[plugin pluginUniqueName]);
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self exportToArray];
}

- (IBAction)forceSave:(id)sender
{
	[self exportToArray];
}

#pragma mark Trigger Functions
- (void)exportToArray
{
	int i;
	id trigger;
	NSMutableArray* returnArray = [NSMutableArray array];
	
	for (i=0;[triggersArray count]>i;i++)
	{
		trigger = [triggersArray objectAtIndex:i];
		[returnArray addObject:[trigger export]];
	}
	
	NSArray* trueArray = [NSArray arrayWithArray:returnArray];
	
	[[NSUserDefaults standardUserDefaults]setObject:trueArray forKey:@"triggers"];
	[[NSUserDefaults standardUserDefaults]synchronize];
}

- (void)loadTriggers
{
	// loading in our plugins
	NSString* folderPath = [[NSBundle mainBundle] builtInPlugInsPath]; // path= ./Breakaway.app/Contents/PlugIns
	if (folderPath) {
		NSEnumerator* enumerator = [[NSBundle pathsForResourcesOfType:@"plugin" inDirectory:folderPath] objectEnumerator];
		NSString* pluginPath;
		while ((pluginPath = [enumerator nextObject])) {
			[self activatePlugin:pluginPath];
		}
	}
	
	NSEnumerator* enumerator = [pluginClasses objectEnumerator];
	Class pluginClass;
	while ((pluginClass = [enumerator nextObject])) {
		[self instantiatePlugins:pluginClass];
	}

	/*
	int i;
	NSMutableArray* tmpArray = [[NSUserDefaults standardUserDefaults]objectForKey:@"triggers"];
	for (i=0;[tmpArray count]>i;i++)
	{
		if ([[tmpArray objectAtIndex:i]count] > 9)
			[triggersArray addObject:[[AITrigger alloc]initFromDictionary:[tmpArray objectAtIndex:i]]];
		else NSLog(@"Not enough attributes to make an AITrigger (%i). Not adding to triggersArray.",[[tmpArray objectAtIndex:i]count]);
	}
	 */
}

- (void)executeTriggers:(int)prototype
{	
	NSEnumerator* enumerator = [pluginClasses objectEnumerator];
	Class pluginClass;
	while ((pluginClass = [enumerator nextObject])) {
		//NSLog([NSString stringWithFormat:@"%@",[pluginClass ]]);
	}
	
	int i;
	id tmpTrigger;
	for (i=0;i<[triggersArray count];i++)
	{
		tmpTrigger = [triggersArray objectAtIndex:i];
		if (([tmpTrigger familyCode] & prototype) == prototype) [tmpTrigger execute];
	}
	//[[NSUserDefaults standardUserDefaults]setObject:triggersArray forKey:@"triggers"];
}

#pragma mark Script Manipulators
- (IBAction)locateScript:(id)sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	if([panel runModalForDirectory:nil file:nil types:nil] == NSOKButton)
		[[[triggerArrayController selectedObjects]objectAtIndex:0] setScript:[[panel filenames]objectAtIndex:0]];
	
	[triggerTable tableViewSelectionDidChange:nil];
	[triggerTable reloadData];
	
}
- (IBAction)revealScript:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile: [[[triggerArrayController selectedObjects]objectAtIndex:0]script] inFileViewerRootedAtPath:nil];
}

- (IBAction)openScript:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[triggerArrayController selectedObjects]objectAtIndex:0]script]];
}

#pragma mark IBActions
- (IBAction)donate:(id)sender
{
	[[[NSApplication sharedApplication]delegate] openDonate:nil];
}

- (IBAction)showInMenuBar:(id)sender
{
	[[[NSApplication sharedApplication]delegate] showInMenuBarAct:nil];
}

- (IBAction)muteKeyEnable:(id)sender
{
	[[[NSApplication sharedApplication]delegate] muteKeyEnableAct:nil];
}

- (IBAction)showInDock:(id)sender
{
	NSString* path = [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"];
	NSMutableArray* infoContents = [[NSString stringWithContentsOfFile:path] componentsSeparatedByString:@"\n"];
	[infoContents replaceObjectAtIndex:UI_PLIST_LOCATION withObject:[NSString stringWithFormat:@"	<string>%i</string>",![sender state]]];
	NSString* smashedFile = [infoContents componentsJoinedByString:@"\n"];
	[smashedFile writeToFile:path atomically:YES];
	
	// touch the bundle so the changes are noticed by the OS
	[[NSFileManager defaultManager] changeFileAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] atPath:[[NSBundle mainBundle] bundlePath]];
}

- (IBAction)update:(id)sender
{
	/* Selections
	0 Never
	1 On Launch
	2 Daily: 86,400
	3 Weekly:  604,800*/
	
	id sparkle = [[[NSApplication sharedApplication]delegate] sparkle];
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	int selection = [sender indexOfSelectedItem];
	
	switch (selection)
	{
		case 0: [userDefaults removeObjectForKey:@"SUScheduledCheckInterval"];
			[sparkle scheduleCheckWithInterval:0];
			[userDefaults setInteger:0 forKey:@"SUCheckAtStartup"];
			break;
			
		case 1: [userDefaults removeObjectForKey:@"SUScheduledCheckInterval"];
			[sparkle scheduleCheckWithInterval:0];
			[userDefaults setInteger:1 forKey:@"SUCheckAtStartup"];
			break;
			
		case 2: [userDefaults setFloat:86400 forKey:@"SUScheduledCheckInterval"];
			[sparkle scheduleCheckWithInterval:86400];
			[userDefaults setInteger:1 forKey:@"SUCheckAtStartup"];
			break;
		
		case 3: [userDefaults setFloat:604800 forKey:@"SUScheduledCheckInterval"];
			[sparkle scheduleCheckWithInterval:604800];
			[userDefaults setInteger:1 forKey:@"SUCheckAtStartup"];
			break;
			
	}
	[userDefaults setInteger:selection forKey:@"SUUpdate"];
	
}

- (IBAction)updateCheck:(id)sender
{
	id sparkle = [[[NSApplication sharedApplication]delegate] sparkle];
	[sparkle checkForUpdates:self];
}

- (IBAction)modeCheck:(id)sender
{
	if ([[triggerArrayController selectedObjects]count] && [[[triggerArrayController selectedObjects]objectAtIndex:0]modeSelected])
	{
		[mute setEnabled:1];
		[unmute setEnabled:1];
	}
	else
	{
		[mute setEnabled:0];
		[unmute setEnabled:0];
	}
}

- (IBAction)testFadeIn:(id)sender
{
	[[[NSApplication sharedApplication]delegate]recompileFadeIn];
	[[[NSApplication sharedApplication]delegate]executeFadeIn];
}

NSString* osTypeToFourCharCode(OSType inType) {
return [NSString stringWithFormat:@"%c%c%c%c", (unsigned char)(inType >> 24), (unsigned char)(inType >> 16 ), (unsigned char)(inType >> 8), (unsigned char)inType];
}


- (IBAction)startTest:(id)sender
{	
	//====================================================================================
	// get a device up
    AudioDeviceID device;
    
    // set up our buffer and data size so we may recieve it
    UInt32 size = sizeof device;
    
    // These need to be declared up here to make the compiler happy
    UInt32 outt = 3;	
	NSString *fccString;
	
	UInt32 dataSource;
	UInt32 dataSourceBuff = sizeof(outt);
	
    // find out what the main output device is (assuming it's built in audio)
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &size, &device);
	if (err != noErr) [log insertText:@"Could not get main output device\n"];
	else [log insertText:@"Successfully retrieved main output device\n"];
	
	[log insertText:@"======================================================\n"];
	
	err = AudioDeviceGetProperty( device,
										   0,
										   0,
										   kAudioDevicePropertyJackIsConnected,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyJackIsConnected ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyJackIsConnected ('%@')\n",fccString]];

	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   0,
										   kAudioDevicePropertyDataSources,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSources ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSources ('%@')\n",fccString]];

	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   0,
										   kAudioDevicePropertyDataSource,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSource ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSource ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	
	//////////////////////////////////////////////////////////// CHAN 1
	err = AudioDeviceGetProperty( device,
										   0,
										   1,
										   kAudioDevicePropertyJackIsConnected,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyJackIsConnected(chan 1) ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyJackIsConnected(chan 1) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   1,
										   kAudioDevicePropertyDataSources,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSources(chan 1) ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSources(chan 1) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   1,
										   kAudioDevicePropertyDataSource,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSource(chan 1) ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSource(chan 1) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	
	//////////////////////////////////////////////////////////// CHAN 2
	err = AudioDeviceGetProperty( device,
										   0,
										   2,
										   kAudioDevicePropertyJackIsConnected,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyJackIsConnected(chan 2) ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyJackIsConnected(chan 2) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   2,
										   kAudioDevicePropertyDataSources,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSources(chan 2) ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSources(chan 2) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   2,
										   kAudioDevicePropertyDataSource,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [log insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSource(chan 2) ('%@')\n", osTypeToFourCharCode(err)]];
	else [log insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSource(chan 2) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	
	if (done) 
	{
		[log insertText:@"\n\n"];
		[log insertText:NSLocalizedString(@"You are done! Click the sumbit results button. Thank you for making Breakaway better.",nil)];
		[log insertText:@"\n"];
		done=0;
	}
	else
	{
		[log insertText:@"\n\n"];
		[log insertText:NSLocalizedString(@"Please connect headphones now and click on the button again",nil)];
		[log insertText:@"\n"];
		done=1;
	}
}

- (IBAction)sendResults:(id)sender
{
	static NSString *hardwareModel = nil;
    if (!hardwareModel) {
        char buffer[128];
        size_t length = sizeof(buffer);
        if (sysctlbyname("hw.model", &buffer, &length, NULL, 0) == 0) {
            hardwareModel = [[NSString allocWithZone:NULL] initWithCString:buffer encoding:NSASCIIStringEncoding];
        }
        if (!hardwareModel || [hardwareModel length] == 0) {
            hardwareModel = @"Unknown";
        }
    }
	
	static NSString *computerModel = nil;
    if (!computerModel) {
        NSString *path;
        if ((path = [[NSBundle mainBundle] pathForResource:@"Macintosh" ofType:@"dict"])) {
            computerModel = [[[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:hardwareModel] copy];
        }
        if (!computerModel) {
            char buffer[128];
            size_t length = sizeof(buffer);
            if (sysctlbyname("hw.machine", &buffer, &length, NULL, 0) == 0) {
                computerModel = [[NSString allocWithZone:NULL] initWithCString:buffer encoding:NSASCIIStringEncoding];
            }
        }
        if (!computerModel || [computerModel length] == 0) {
            computerModel = [[NSString allocWithZone:NULL] initWithFormat:@"%@ computer model", hardwareModel];
        }
    }
	
    SInt32 systemVersion=0, versionMajor=0, versionMinor=0, versionBugFix=0;
	OSErr err = Gestalt(gestaltSystemVersion, &systemVersion);
	unsigned main, next, bugFix;
    if (systemVersion < 0x1040)
    {
        main = ((systemVersion & 0xF000) >> 12) * 10 + ((systemVersion & 0x0F00) >> 8);
        next = (systemVersion & 0x00F0) >> 4;
        bugFix = (systemVersion & 0x000F);
    }
    else
    {
		if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) NSLog(@"y");
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr)NSLog(@"e");
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr)NSLog(@"s\n");
        main = versionMajor;
        next = versionMinor;
        bugFix = versionBugFix;
    }
	NSString *url = [NSString string];
	url = [url stringByAppendingString:[NSString stringWithFormat:@"mailto:balthamos89@gmail.com?subject=Expand Breakaway Test Results&body=%@ | OS %u.%u.%u \n\n%@\n\n", computerModel,main, next, bugFix ,[log string]]];
	url = [url stringByAppendingString:NSLocalizedString(@"Feel free to add additional questions and comments (like if Breakaway \"kind of\" works, etc.). Please have these statements in English, if possible.",nil)];
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

#pragma mark Accessors (external)

/* PreferenceHandler.m (self) - Just to act as a portal for everyone else ()
AITriggerTable.m - For displaying the validity of triggers (colering rows, etc) (-objectAtIndex:)*/
- (NSMutableArray*)triggersArray
{
	return triggersArray;
}

/* PreferenceHandler.m (self) - Just to act as a portal for everyone else ()
AITriggerTable.m - For displaying the validity of triggers in the trigger option window (-setBackgroundColor:)*/
- (id)scriptField
{
	return scriptField;
}

/* PreferenceHandler.m (self) - Just to act as a portal for everyone else ()
AIDropLink.m - For getting current selection of table (-selectedObjects:) */
- (id)triggerArrayController
{
	return triggerArrayController;
}

#pragma mark Delegates
- (BOOL)windowShouldClose:(id)sender
{
	[self exportToArray];
	[drawer close:nil];
	[[[NSApplication sharedApplication]delegate]recompileFadeIn];
	return YES;
}

@end
