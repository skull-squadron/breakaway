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

#import "defines.h"
#import "AppController.h"
#import "Sparkle/SUUpdater.h"
#import "SUHost.h"
#import "SUSystemProfiler.h"

@implementation PreferenceHandler

- (void)awakeFromNib
{
    [[SUUpdater sharedUpdater] setDelegate:self];
    [lastCheck setObjectValue:[[SUUpdater sharedUpdater] lastUpdateCheckDate]];
    [[NSUserDefaults standardUserDefaults] setBool:[self isUIElement] forKey:@"LSUIElement"];
    [testResultBox setFont:[NSFont fontWithName:@"Monaco" size:10]];
    [loginItem setState:[self isLoginItem]?1:0];
    
	// this is used for testing the system (startTest:)
	done = NO;
}

#pragma mark Login item
- (IBAction)addAsLoginItem:(id)sender
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems,NULL);
    NSString *applicationPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef applicationURL = (CFURLRef)[NSURL fileURLWithPath:applicationPath];
    
    if ([sender state])
    {
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, applicationURL, NULL, NULL);		
        if (item) CFRelease(item);    
    }
    else
    {
        UInt32 seedValue;
        
        NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
        for (id item in loginItemsArray)
        {		
            if (LSSharedFileListItemResolve((LSSharedFileListItemRef)item, 0, (CFURLRef*)&applicationURL, NULL) == noErr && [[(NSURL *)applicationURL path] hasPrefix:applicationPath])
                LSSharedFileListItemRemove(loginItems, (LSSharedFileListItemRef)item); // Remove startup item
        }
        [loginItemsArray release];        
    }
}

- (BOOL)isLoginItem
{
    BOOL isLoginItem = NO;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems,NULL);
    NSString *applicationPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef applicationURL = (CFURLRef)[NSURL fileURLWithPath:applicationPath];
    UInt32 seedValue;
    NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
    for (id item in loginItemsArray)
        if (LSSharedFileListItemResolve((LSSharedFileListItemRef)item, 0, (CFURLRef*)&applicationURL, NULL) == noErr && [[(NSURL *)applicationURL path] hasPrefix:applicationPath])
            isLoginItem = YES;
    [loginItemsArray release];
    return isLoginItem;
}

#pragma mark UI Element
- (IBAction)showInDock:(id)sender
{
    NSString *infoPlistLocation = [NSString stringWithFormat:@"%@/Contents/Info.plist",[[NSBundle mainBundle] bundlePath]];
    NSMutableDictionary *appPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlistLocation];
    
    [appPrefs setObject:[NSNumber numberWithBool:![sender state]] forKey:@"LSUIElement"];
    [appPrefs writeToFile:infoPlistLocation atomically:YES];
    
	// touch the bundle so the changes are noticed by the OS
	[[NSFileManager defaultManager] changeFileAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] atPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)isUIElement
{
    NSString *infoPlistLocation = [NSString stringWithFormat:@"%@/Contents/Info.plist",[[NSBundle mainBundle] bundlePath]];
    NSMutableDictionary *appPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlistLocation];
    
    return [[appPrefs objectForKey:@"LSUIElement"] boolValue];
}

#pragma mark Misc Actions
- (IBAction)showInMenuBar:(id)sender
{
	[[AppController sharedAppController] showInMenuBarAct:nil];
}

- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:donateAddress]];
}

- (IBAction)viewReadme:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Readme.rtf"]];
}

- (IBAction)testFadeIn:(id)sender
{
    [[AppController sharedAppController] iTunesThreadedFadeIn];
}

#pragma mark Sparkle
- (void)updater:(SUUpdater *)updater didFinishLoadingAppcast:(SUAppcast *)appcast
{
    [lastCheck setObjectValue:[[SUUpdater sharedUpdater] lastUpdateCheckDate]];
}

- (IBAction)checkForUpdates:(id)sender
{
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
}

- (void)setSendsSystemProfile:(BOOL)sendsSystemProfile
{
    [[SUUpdater sharedUpdater] setSendsSystemProfile:sendsSystemProfile];
}

- (void)setAutomaticallyDownloadsUpdates:(BOOL)automaticallyDownloadsUpdates
{
    [[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:automaticallyDownloadsUpdates];
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)automaticallyChecks
{
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:automaticallyChecks];
}

- (BOOL)sendsSystemProfile
{
    return [[SUUpdater sharedUpdater] sendsSystemProfile];
}

- (BOOL)automaticallyDownloadsUpdates
{
    return [[SUUpdater sharedUpdater] automaticallyDownloadsUpdates];
}

- (BOOL)automaticallyChecksForUpdates
{
    return [[SUUpdater sharedUpdater] automaticallyChecksForUpdates];
}

#pragma mark Test
NSString* osTypeToFourCharCode(OSType inType) {
return [NSString stringWithFormat:@"%c%c%c%c", (unsigned char)(inType >> 24), (unsigned char)(inType >> 16 ), (unsigned char)(inType >> 8), (unsigned char)inType];
}

- (void)logTestResultForProperty:(NSString *)property withReturn:(OSStatus)returnStatus andData:(UInt32)dataSource
{
    NSMutableString *resultString = nil;
    resultString = [NSMutableString stringWithFormat:@"%@ %@", (returnStatus != noErr) ? @"[ERROR]" : @"   [OK]", property];
    [resultString appendString:[NSString stringWithFormat:@": '%@'\n", ((returnStatus != noErr) ? osTypeToFourCharCode(returnStatus) : osTypeToFourCharCode(dataSource))]];
	[testResultBox insertText:resultString];
}

- (IBAction)startTest:(id)sender
{	
    AudioDeviceID device;
    UInt32 size = sizeof device;
    UInt32 outt = 3;	
	UInt32 dataSource, dataSourceBuff;
    OSStatus err;

    if (!done) [testResultBox insertText:@"=================== Headphones Unplugged ===================\n"];
    else [testResultBox insertText:@"==================== Headphones Plugged ====================\n"];
    
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
    [self logTestResultForProperty:@"kAudioHardwarePropertyDefaultOutputDevice" withReturn:err andData:device];
    
    int i;
    for (i = 0; i < 3; i++)
    {
        dataSourceBuff = sizeof(outt);
        err = AudioDeviceGetProperty(device, 0, i, kAudioDevicePropertyJackIsConnected, &dataSourceBuff, &dataSource);
        [self logTestResultForProperty:[NSString stringWithFormat:@"(chan %i) kAudioDevicePropertyJackIsConnected", i] withReturn:err andData:dataSource];
        
        dataSourceBuff = sizeof(outt);
        err = AudioDeviceGetProperty(device, 0, i, kAudioDevicePropertyDataSources, &dataSourceBuff, &dataSource);
        [self logTestResultForProperty:[NSString stringWithFormat:@"(chan %i) kAudioDevicePropertyDataSources", i] withReturn:err andData:dataSource];
        
        dataSourceBuff = sizeof(outt);
        err = AudioDeviceGetProperty(device, 0, i, kAudioDevicePropertyDataSource, &dataSourceBuff, &dataSource);
        [self logTestResultForProperty:[NSString stringWithFormat:@"(chan %i) kAudioDevicePropertyDataSource", i] withReturn:err andData:dataSource];
	}

    
	if (!done) 
    {
		[testResultBox insertText:@"\n"];
        [testResultBox insertText:@"========================== STEP 3 ==========================\n"];
		[testResultBox insertText:NSLocalizedString(@"Please connect headphones now and click on the button again", nil)];
		[testResultBox insertText:@"\n"];
		done = YES;
	}
    else
	{
		[testResultBox insertText:@"\n"];
        [testResultBox insertText:@"====================== TEST COMPLETE =======================\n"];
		[testResultBox insertText:NSLocalizedString(@"You are done! Click the sumbit results button. Thank you for making Breakaway better.", nil)];
		[testResultBox insertText:@"\n"];
        // If we wanted to run another test
		done = NO;
	}	
}

- (IBAction)sendResults:(id)sender
{    
	NSMutableString *mailtoURL = [NSMutableString string];
	[mailtoURL appendFormat:@"mailto:%@?subject=%@&body=", resultsEmailAddress, resultsEmailSubject];
    
    SUHost *host = [[SUHost alloc] initWithBundle:nil];
    NSMutableArray *systemProfile = [[SUSystemProfiler sharedSystemProfiler] systemProfileArrayForHost:host];

    int i;
    for (i = 0; i < [systemProfile count]; i++)
    {
        switch (i)
        {
            case 5:
            case 6:
            case 7:
            case 9:
            case 10:
                break;
            default:
                [mailtoURL appendFormat:@"%@: %@ [%@]\n", [[systemProfile objectAtIndex:i] objectForKey:@"displayKey"], [[systemProfile objectAtIndex:i] objectForKey:@"displayValue"], [[systemProfile objectAtIndex:i] objectForKey:@"value"]];
                break;
        }
    }
    [mailtoURL appendFormat:@"\n%@",[testResultBox string]];
    
    NSString *messageString = nil;
    switch ([userConcernRadioButton selectedRow])
    {
        case APP_BROKEN_ROW:
            messageString = NSLocalizedString(@"Please state what part of the application is not working. Please have these statements in English, if possible.", nil);
            break;
        case APP_WORKING_ROW:
            messageString = NSLocalizedString(@"Thank you for helping make Breakaway better.", nil);
            break;
        default:
            messageString = NSLocalizedString(@"*NOTE* You (the user) have not specified if the application is working or not. Please go back and choose an option or state here. Note, \"42\" is not a valid answer.", nil);
            break;
    }
    [mailtoURL appendFormat:@"\n\n%@", messageString];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[mailtoURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    [host release];
}

#pragma mark Delegates
- (BOOL)windowShouldClose:(id)sender
{
	[drawer close:nil];
	return YES;
}

@end
