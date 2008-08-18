/*
 * PreferenceHandler.m
 * Breakaway
 * Created by Kevin Nygaard on 6/14/06.
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

#import "PreferenceHandler.h"

#import "AppController.h"
#import "Sparkle/SUUpdater.h"
#import "defines.h"
#import <sys/sysctl.h>

#define UI_PLIST_LOCATION 23
@implementation PreferenceHandler

-(void)awakeFromNib
{	
	NSLog(@"preference handler loaded");
	
	// this is used for testing the system (startTest:)
	done=0;
}

#pragma mark IBActions
- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://balthamos.awardspace.com/donate.php"]];
}

- (IBAction)viewReadme:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:@"Readme.rtf"]];
}

- (IBAction)showInMenuBar:(id)sender
{
	[[AppController appController] showInMenuBarAct:nil];
}

- (IBAction)muteKeyEnable:(id)sender
{
	[[AppController appController] muteKeyEnableAct:nil];
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
	
	id sparkle = [[AppController appController] sparkle];
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
	id sparkle = [[AppController appController] sparkle];
	[sparkle checkForUpdates:self];
}

- (IBAction)testFadeIn:(id)sender
{
	[[AppController appController] recompileFadeIn];
	[[AppController appController] executeFadeIn];
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
	if (err != noErr) [testResultBox insertText:@"Could not get main output device\n"];
	else [testResultBox insertText:@"Successfully retrieved main output device\n"];
	
	[testResultBox insertText:@"======================================================\n"];
	
	err = AudioDeviceGetProperty( device,
										   0,
										   0,
										   kAudioDevicePropertyJackIsConnected,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyJackIsConnected ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyJackIsConnected ('%@')\n",fccString]];

	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   0,
										   kAudioDevicePropertyDataSources,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSources ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSources ('%@')\n",fccString]];

	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   0,
										   kAudioDevicePropertyDataSource,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSource ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSource ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	
	//////////////////////////////////////////////////////////// CHAN 1
	err = AudioDeviceGetProperty( device,
										   0,
										   1,
										   kAudioDevicePropertyJackIsConnected,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyJackIsConnected(chan 1) ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyJackIsConnected(chan 1) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   1,
										   kAudioDevicePropertyDataSources,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSources(chan 1) ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSources(chan 1) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   1,
										   kAudioDevicePropertyDataSource,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSource(chan 1) ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSource(chan 1) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	
	//////////////////////////////////////////////////////////// CHAN 2
	err = AudioDeviceGetProperty( device,
										   0,
										   2,
										   kAudioDevicePropertyJackIsConnected,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyJackIsConnected(chan 2) ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyJackIsConnected(chan 2) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   2,
										   kAudioDevicePropertyDataSources,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSources(chan 2) ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSources(chan 2) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	err = AudioDeviceGetProperty( device,
										   0,
										   2,
										   kAudioDevicePropertyDataSource,
										   &dataSourceBuff,
										   &dataSource);
	
	fccString = osTypeToFourCharCode(dataSource);
	if (err != noErr) [testResultBox insertText:[NSString stringWithFormat:@"Error getting property kAudioDevicePropertyDataSource(chan 2) ('%@')\n", osTypeToFourCharCode(err)]];
	else [testResultBox insertText:[NSString stringWithFormat:@"Successfully retrieved property kAudioDevicePropertyDataSource(chan 2) ('%@')\n",fccString]];
	
	dataSourceBuff = sizeof(outt);
	
	if (done) 
	{
		[testResultBox insertText:@"\n\n"];
		[testResultBox insertText:NSLocalizedString(@"You are done! Click the sumbit results button. Thank you for making Breakaway better.",nil)];
		[testResultBox insertText:@"\n"];
		done=0;
	}
	else
	{
		[testResultBox insertText:@"\n\n"];
		[testResultBox insertText:NSLocalizedString(@"Please connect headphones now and click on the button again",nil)];
		[testResultBox insertText:@"\n"];
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
	url = [url stringByAppendingString:[NSString stringWithFormat:@"mailto:balthamos89@gmail.com?subject=Expand Breakaway Test Results&body=%@ | OS %u.%u.%u | v %@\n\n%@\n\n", computerModel,main, next, bugFix, [[[NSBundle mainBundle]infoDictionary]valueForKey:@"CFBundleVersion"] ,[testResultBox string]]];
	url = [url stringByAppendingString:NSLocalizedString(@"Please state what part of the application is not working. Please have these statements in English, if possible.",nil)];
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

#pragma mark Delegates
- (BOOL)windowShouldClose:(id)sender
{
	//[self exportToArray];
	[drawer close:nil];
	[[AppController appController] recompileFadeIn];
	return YES;
}

@end
