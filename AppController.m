/*
 * AppController.m
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

#import "AppController.h"

#import <CoreAudio/CoreAudio.h>
#import <ApplicationServices/ApplicationServices.h>

#import "PreferencesController.h"
//#import "PreferenceHandler.h"
#import "GrowlNotifier.h"
#import <Sparkle/SUUpdater.h>
#import "DebugUtils.h"
#import "defines.h"
#import "AIPluginSelector.h"

@implementation AppController

static AppController *appController = nil;  

// Cool thing about +initialize is that it runs before any other method gets called
+ (void)initialize
{
    // Setting up our defaults here
    NSDictionary *defaults;
    defaults = [NSDictionary dictionaryWithObjectsAndKeys: 
		// General
        [NSNumber numberWithBool:1], @"guessMode",
		[NSNumber numberWithBool:1], @"headphonesMode",
		[NSNumber numberWithBool:1], @"ror",
		
        [NSNumber numberWithBool:1], @"mute watch",
        [NSNumber numberWithBool:0], @"force open",
		
		[NSNumber numberWithBool:1], @"showInMenuBar",
		[NSNumber numberWithBool:0], @"showIcon",
		[NSNumber numberWithBool:1], @"showSplash",
		
		[NSNumber numberWithInt:2], @"SUUpdate", // the selected tag in the popup box. SUScheduledCheckInterval derived from this value
		//[NSNumber numberWithLong:86400], @"SUScheduledCheckInterval", // daily
        
		// Advanced
		[NSNumber numberWithBool:1], @"smartPlay",
		[NSNumber numberWithBool:1], @"enableAppHit",
		[NSNumber numberWithBool:0], @"multichannelMute",
		[NSNumber numberWithBool:0], @"enableFlowing",
		[NSNumber numberWithFloat:0], @"fadeInTime",
		[NSNumber numberWithBool:1], @"keepVol",
		[NSNumber numberWithFloat:0.1], @"throwout",
        
        nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    DEBUG_OUTPUT1(@"Registered Defaults: %@",defaults);
}

+ (AppController*)appController
{
	return appController;
}

-(void) awakeFromNib
{		
	appController = self;
	
	// sets up our user defaults for preference fetching
	userDefaults = [NSUserDefaults standardUserDefaults];
	
	// We havent touched iTunes yet, so mark it in our preferences
    [userDefaults setBool:FALSE forKey:@"appHit"];	
	
	BOOL showSplash = [userDefaults boolForKey:@"showSplash"];
	
    if (showSplash) [self startSplash];
	
	//////// Start Loading Stuff
    [self loadListeners];
	[self loadiTunesObservers];
    
	// MUST GO IN THIS ORDER (isActive, compile, isPlaying)
	
	// Set our instance varibales
	isActive = [self iTunesActive];	
	
	// Try to compile our scripts (rids of us the nasty delay accompanied with uncompiled Applescripts)
    [self compileScript];
	
    // Set our instance varibales
    isPlaying = [self iTunesPlaying]; [playerState release];
    
    // See if there is any audio flowing in the IO
    [self audioFlowing];
	
    DEBUG_OUTPUT(@"done!");
	
	// calls our controller to load our preference window, including all our plugins
	[PreferencesController sharedPreferencesController];
	
	//////// Stop Loading Stuff
	if (showSplash)
	{
		// stop our animation
		[progressWheel stopAnimation:self];
		
		// make a timer that waits 1.5 sec, then kill splash
		[NSTimer scheduledTimerWithTimeInterval:1.5
										 target:self
									   selector:@selector(stopSplash)
									   userInfo:nil
										repeats:NO];
	}
    
    // sets up our timer. needs to be called at least once so we have a time point to refrence from (on first call)
    [self updateThen];
}

- (void)disable
{	
    if ([[disableMI title] isEqual: NSLocalizedString(@"Disable",nil)])
     {
		DEBUG_OUTPUT(@"Disabling...");
		
        // If we are using the new method | else we are using the old method, so which type do we want to remove?
		[self removeListener:kAudioDevicePropertyDataSource];
        
        // Attach listener to mute if the user wants us to
        if ([userDefaults boolForKey:@"mute watch"]) {[self removeListener:kAudioDevicePropertyMute]; [self removeListener:kAudioDevicePropertyVolumeScalar];}
        
		 // This is what the user will click if he wants to enable it
        [disableMI setTitle:NSLocalizedString(@"Enable",nil)];
        
        [statusItem setImage:disabled];
     }
    else if ([[disableMI title] isEqual: NSLocalizedString(@"Enable",nil)])
     {
		DEBUG_OUTPUT(@"Enabling...");

		// Attach our listener for the jack (depending on what the state of type b is)
		[self attachListener:kAudioDevicePropertyDataSource];

		// Attach listener to mute if the user wants us to
		if ([userDefaults boolForKey:@"mute watch"])
		{
			[self attachListener:kAudioDevicePropertyMute];
			[self attachListener:kAudioDevicePropertyVolumeScalar];
		}

		// This is what the user will click if he wants to disable it
		[disableMI setTitle:NSLocalizedString(@"Disable",nil)];
		[self jackConnected];
     }
    else
     {
		 NSLog(@"An error has occured while trying to disable Breakaway. Please notify the developer.");
     }
    
}


#pragma mark-

#pragma mark Startup Functions
- (void)loadListeners
{
    // check the menu item preference and load one up if they want one
    if ([userDefaults boolForKey:@"showInMenuBar"]) [self setupStatusItem];
    
    // Load our jack listener
	[self attachListener:kAudioDevicePropertyDataSource];
    
    // Attach listener to mute if the user wants us to
    if ([userDefaults boolForKey:@"mute watch"])
	{
        [self attachListener:kAudioDevicePropertyMute];
        [self attachListener:kAudioDevicePropertyVolumeScalar];
	}
}

- (void)loadiTunesObservers
{
	// Installing this observer will proc songChanged: every time iTunes is stop/started
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(songChanged:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    
    // Installing these observers will proc their respective functions when iTunes opens/closes
    NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [workspaceCenter addObserver:self
                        selector:@selector(handleAppLaunch:)
                            name:NSWorkspaceDidLaunchApplicationNotification
                          object:nil];
    
    [workspaceCenter addObserver:self
                        selector:@selector(handleAppQuit:)
                            name:NSWorkspaceDidTerminateApplicationNotification
                          object:nil];
	
}

#pragma mark Splash

- (void)startSplash //**done**
{
    // Find our version number so we can display it
    [versionString setStringValue: [NSString stringWithFormat:@"v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
    
    
    // make a window and make the contents that of what we put in the nib
    splashWind = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,392,218)
                                             styleMask: NSBorderlessWindowMask
                                               backing: NSBackingStoreBuffered
                                                 defer:YES];
    [splashWind setHasShadow:YES];
    [splashWind setContentView: splash];
	[splashWind setBackgroundColor:[NSColor colorWithDeviceWhite:1.0 alpha:100]];
    [splashWind setAlphaValue:0];
    [splashWind makeKeyAndOrderFront:self];
    [splashWind setOpaque:NO];
	[splashWind setLevel:NSFloatingWindowLevel];
    [splashWind center];
    
    //start our animation
    [progressWheel startAnimation:self];
    
    // fade in the window
    int i;
    for (i=0;[splashWind alphaValue]<1;i++)
     {
        [splashWind setAlphaValue:[splashWind alphaValue] + 0.05];
        [splashWind display];
     }
    
}

- (void)stopSplash //**done**
{	
    //[splashWind setAlphaValue:1];
    //[splashWind setOpaque:NO];
    //[splashWind center];
    //[progressWheel stopAnimation:self]; // We stopped this earlier
    
    //fade out the window
    int i;
    for (i=0;[splashWind alphaValue]>0;i++)
     {
        [splashWind setAlphaValue:[splashWind alphaValue] - 0.05];
        [splashWind display];
     }
    
    // release the window we alloced because we dont have a use for it anymore
    [splashWind release];
}


#pragma mark 
#pragma mark Menu Extra
- (void)setupStatusItem
{	
    // get the images for the status item set up
    conn = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"connected" ofType:@"png"]];
    [conn setScalesWhenResized:TRUE];
    [conn setSize:NSMakeSize(10,10)];
    
    disconn = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"disconnected" ofType:@"png"]];
    [disconn setScalesWhenResized:TRUE];
    [disconn setSize:NSMakeSize(10,10)];
    
    disabled = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"disabled" ofType:@"png"]];
    
    
    //Status bar stuff
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem retain];
    
    [statusItem setMenu:statusItemMenu];
    [statusItem setEnabled:YES];
    [statusItem setHighlightMode:YES];
    
    // Notify the user whats going on
    [self growlNotify:NSLocalizedString(@"Enabled",nil) andDescription:NSLocalizedString(@"The menu extra has sucessfully been enabled.",nil)];
    
    // run this so we can get a correct state on our menu extra
    [self jackConnected];
}

- (void)killStatusItem
{
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    
    // Release our status item
    [statusItem release];
    
    // Release our images that the status item used
    [conn release];
    [disconn release];
    [disabled release];
    
    // Display a notification via Growl to tell the user that Breakaway is still active
    [self growlNotify:NSLocalizedString(@"Disabled",nil) andDescription:NSLocalizedString(@"The menu extra has sucessfully been disabled. Breakaway is still running.",nil)];
}

#pragma mark 

#pragma mark IB Button Actions
- (IBAction)muteKeyEnableAct:(id)sender
{
    // Implemented in this method and in -awakeOnNib
    if ([userDefaults boolForKey:@"mute watch"]) 
	{
		[self attachListener:kAudioDevicePropertyMute];
		[self attachListener:kAudioDevicePropertyVolumeScalar];
	}
	else 
	{
		[self removeListener:kAudioDevicePropertyMute];
		[self removeListener:kAudioDevicePropertyVolumeScalar];
	}
}

- (IBAction)showInMenuBarAct:(id)sender
{
    [userDefaults boolForKey:@"showInMenuBar"] ? [self setupStatusItem]:[self killStatusItem];
}

- (IBAction)openPrefs:(id)sender
{
	[[PreferencesController sharedPreferencesController]showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)sendemail:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:balthamos89@gmail.com?subject=Breakaway%20Feedback"]];
}

- (void)updateThen
{
    DEBUG_OUTPUT(@"time updated");
    [then release];
    then=[[NSDate alloc] init];
    //DEBUG_OUTPUT1(@"%@",then);
}

- (IBAction)openInfo:(id)sender
{
	[NSApp orderFrontStandardAboutPanel:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)openUpdater:(id)sender
{
	[[self sparkle] checkForUpdates:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

#pragma mark
#pragma mark Accessor (external)
/* List of other files accessing this function and why
FileAccessorCalledFrom.m - Reason of accessing (-functionCalledUsingAccessor:)

AppController.m (self) - Just to act as a portal for everyone else ()
PreferenceHandler.m - For changing auto update preferences (-scheduleCheckWithInterval:)
*/
-(id)sparkle
{
	return sparkleController;
}

#pragma mark
#pragma mark Accessor Functions
- (NSDate *)then
{
    return then;
}

- (IBAction)disable:(id)sender
{
    [self disable];
}

- (void)growlNotify:(NSString *)title andDescription:(NSString *)description
{
    [growlNotifier growlNotify:title andDescription:description];
}

- (BOOL)isPlaying
{		
    return isPlaying;
}

- (BOOL)isActive
{		
    return isActive;
}

#pragma mark 
#pragma mark Old Queries
-(BOOL)iTunesActive
{
    //*DEPRECIATED* Used only once for the initial status of iTunes. Further queries of iTunes status are handled by handleAppLaunch/Quit:
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    BOOL iTunesUp = [[[workspace launchedApplications] valueForKey:@"NSApplicationName"] containsObject:@"iTunes"];
    
    if (iTunesUp)
     {
        DEBUG_OUTPUT(@"iTunes active");
        return YES;
     }
    else if (!iTunesUp) 
     {
        DEBUG_OUTPUT(@"iTunes inactive");
        return NO;
     }
    else
     {
        NSLog(@"ERROR: Could not find iTunes Activity");
        return NO;
     }
}

-(BOOL)iTunesPlaying
{
    //*DEPRECIATED* Used only once for the initial player status of iTunes. Further queries of iTunes status are handled by songChange:
    if (isActive)
     {
        NSAppleEventDescriptor* result = [playerState executeAndReturnError:nil];
        NSString* test = [result stringValue];
        if ([test isEqual: @"playing"]) return YES;
        else return NO;
     }
    else return NO;
    
}


#pragma mark 
#pragma mark New Queries
//**done**
- (void) handleAppLaunch:(NSNotification *)notification
{
    if ([@"com.apple.iTunes" caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
     {
        isActive = TRUE;
        if(!isCompiled) [self compileScript];		
     }
    
}

- (void) handleAppQuit:(NSNotification *)notification
{
    if ([@"com.apple.iTunes" caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
        isActive = FALSE;
}

#pragma mark 
#pragma mark Script Manipulation
- (void)compileScript
{
    // Define and compile our playstate script
    playerState = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" to return (player state) as string"];
	    
    // If iTunes is open, compile the scripts. If not, they will be compiled at a later time by handleAppLaunch:
    // We do this because if the scripts were compiled when iTunes was not active, it would activate it (stupid Applescripts)
    if (isActive || [userDefaults boolForKey:@"force open"])
     {
        DEBUG_OUTPUT(@"Compiling Script...");
        [playerState compileAndReturnError:nil];
		[self recompileFadeIn];
        isCompiled = TRUE;
     }
	else isCompiled = FALSE;
}

- (void)executeScript
{	
	// If iTunes is running, we can execute. If not, don't do anything
    if (isActive)
     {
		BOOL wasVisible = [[[PreferencesController sharedPreferencesController]window]isVisible];
		 
		DEBUG_OUTPUT(@"Executing iTunes stop/start...");
		 const OSType sig ='hook';
		 AppleEvent *event = malloc(sizeof(AppleEvent));
		 AEBuildAppleEvent(sig,
						   'PlPs',
						   typeApplSignature,
						   &sig,
						   sizeof(sig),
						   kAutoGenerateReturnID,
						   kAnyTransactionID,
						   event,
						   NULL,
						   "'----':'null'()");
		 
		 AESendMessage(event, NULL, kAENoReply | kAENeverInteract, kAEDefaultTimeout);
		 AEDisposeDesc(event);
		 free(event);
		 
		 // When we run the script, our preference window closes, so we have to open it again if it was open to begin with
		 if (wasVisible) [[[PreferencesController sharedPreferencesController]window]makeKeyAndOrderFront:nil];
     }
}

- (void)executeFadeIn
{
	// If iTunes is running, we can execute. If not, don't do anything
	if (isActive)
	{
		DEBUG_OUTPUT(@"Executing fade in...");
		if ([userDefaults floatForKey:@"fadeInTime"]) [fadeIn executeAndReturnError:nil];
		//[fadeIn release];
		//[fadeIn performSelectorOnMainThread: @selector(executeAndReturnError:) withObject:nil waitUntilDone: NO];
		//[fadeIn performSelectorOnMainThread: @selector(release) withObject:nil waitUntilDone: NO];
	}
}

- (void)recompileFadeIn
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
	if (fadeIn) [fadeIn release];
	// If iTunes is running, we can execute. If not, don't do anything
	if (isActive)
	{
		//NSLog([NSString stringWithFormat:@"tell application \"iTunes\"\nset x to 0\nset y to sound volume\nrepeat\nset x to x + %f\nset sound volume to x\nif x is greater than or equal to y then exit repeat\nend repeat\nend tell",[userDefaults floatForKey:@"fadeInTime"]]);
		
		fadeIn = [[NSAppleScript alloc] initWithSource:
				  [NSString stringWithFormat:@"tell application \"iTunes\"\nset y to %@\nrepeat with x from 0 to y by %d\ndelay 0.025\nset sound volume to x\nend repeat\nend tell", ([userDefaults boolForKey:@"keepVol"])?@"sound volume":@"100", [userDefaults integerForKey:@"fadeInTime"]]];
		if(![fadeIn compileAndReturnError:nil]) NSLog(@"Error compiling fade in script");
		//[fadeIn performSelectorOnMainThread:@selector(compileAndReturnError:) withObject:nil waitUntilDone:NO];// NSLog(@"PROBLEM COMPILING SCRIPT");
	}
	// Check to see if the script exists and if it is compiled; if so, free it so we can remake it
	[pool release];
}
#pragma mark 
#pragma mark CoreAudio Queries
- (void)attachListener:(AudioDevicePropertyID)adProp
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
	// get a device up
    AudioDeviceID device;
    
    // set up our buffer and data size so we may recieve it
    UInt32 size = sizeof device;
    
    // find out what the main output device is (assuming it's built in audio)
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &size, &device);
    int theNumber = 0;
    if (adProp == kAudioDevicePropertyVolumeScalar) theNumber = 1;
	else if (adProp == kAudioDevicePropertyMute)
     {
        // Checking if mute is multichanneled
        UInt32 muteOn;
        OSStatus err3 = AudioDeviceGetProperty(device,1,0,kAudioDevicePropertyMute,&size,&muteOn);
        
        // If we get a return on channel 1 for mute status, it has channels. If we get an error, we will use channel 0
        if (err3 == noErr)
         {
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"multichannelMute"];
            DEBUG_OUTPUT(@"Mute is multichanneled");
            theNumber = 1;
         }
        else 
         {
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"multichannelMute"];
            DEBUG_OUTPUT(@"Mute is not multichanneled");
            theNumber = 0;
         }
     }
    
    // add a listener for changes in jack connectivity
    OSStatus err2 = AudioDeviceAddPropertyListener( device,
                                                    theNumber,
                                                    0,
                                                    adProp, // kAudioDevicePropertyJackIsConnected, or kAudioDevicePropertyDataSources, or kAudioDevicePropertyMute,
                                                    (AudioDevicePropertyListenerProc)AHPropertyListenerProc,
                                                    self);

    // Layout all this so we can log what's happening
    NSString* prop;
    if (adProp == kAudioDevicePropertyJackIsConnected) prop = @"Jack";
    else if (adProp == kAudioDevicePropertyDataSources) prop = @"Data Sources";
    else if (adProp == kAudioDevicePropertyMute) prop = @"Mute";
    else if (adProp == kAudioDevicePropertyDataSource) prop = @"Data Source";
    else prop = @"Unknown";
    
    if (err != noErr) NSLog(@"ERROR: Can't get main device(%@)",prop);
    if (err2 != noErr) NSLog(@"ERROR: Can't attach listener(%@)",prop);
    if (err == noErr && err2 == noErr) NSLog(@"Listener Attached(%@)",prop);

    [pool release];
    
}

- (void)removeListener:(AudioDevicePropertyID)adProp
{
    // get a device up
    AudioDeviceID device;
    
    // set up our buffer and data size so we may recieve it
    UInt32 size = sizeof device;
    
    // find out what the main output device is (assuming it's built-in audio/line in)
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &size, &device);
    
    int theNumber = 0;
    
    // If we have a multichannel mute and we are trying to take it off, make sure we take it off the right channel
    if(adProp == kAudioDevicePropertyMute && [[NSUserDefaults standardUserDefaults] boolForKey:@"multichannelMute"]) theNumber = 1;
	else if (adProp == kAudioDevicePropertyVolumeScalar) theNumber = 1;
	
    OSStatus err2 = AudioDeviceRemovePropertyListener( device,
                                                       theNumber,
                                                       0,
                                                       adProp, // kAudioDevicePropertyJackIsConnected, or kAudioDevicePropertyDataSources,
                                                       (AudioDevicePropertyListenerProc)AHPropertyListenerProc);
	
    // Layout all this so we can log what's happening
    NSString* prop;
    if (adProp == kAudioDevicePropertyJackIsConnected) prop = @"Jack";
    else if (adProp == kAudioDevicePropertyDataSources) prop = @"Data Sources";
    else if (adProp == kAudioDevicePropertyMute) prop = @"Mute";
    else if (adProp == kAudioDevicePropertyDataSource) prop = @"DataSource";
	else prop = @"Unknown";

    if (err != noErr) NSLog(@"ERROR: Can't get main device for removal(%@)",prop);
    if (err2 != noErr) NSLog(@"ERROR: Can't remove listener(%@)",prop);
    if (err == noErr && err2 == noErr) NSLog(@"Listener Removed(%@)",prop);
}

- (BOOL)audioFlowing
{
    // get a device up
    AudioDeviceID device;
    
    // set up our buffer and data size so we may recieve it
    UInt32 size = sizeof device;
    
    // find out what the main output device is (assuming it's built-in audio/line in)
    AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &size, &device);
    
    UInt32 audOn;
    UInt32 buff2 = sizeof audOn;
    
    AudioDeviceGetProperty(device,0,0,kAudioDevicePropertyDeviceIsRunningSomewhere,&buff2,&audOn);
    
    if (audOn == 1) return 1;
    else if (audOn == 0) return 0;
    else
     {
        DEBUG_OUTPUT(@"audio flowing problem");
        return 0;
     }
    
}

- (BOOL)jackConnected
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    // get a device up
    AudioDeviceID device;
    
    // set up our buffer and data size so we may recieve it
    UInt32 size = sizeof device;
    
    
    // find out what the main output device is (assuming it's built in audio)
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &size, &device);
	
	UInt32 dataSource;
	UInt32 dataSourceBuff = sizeof(UInt32);
	OSStatus err3 = AudioDeviceGetProperty( device, 0 , 0, kAudioDevicePropertyDataSource, &dataSourceBuff, &dataSource);
#if MY_DEBUG_FLAG
    if (err != noErr) DEBUG_OUTPUT(@"Can't get main device(Jack status)");
	if (err3 != noErr) DEBUG_OUTPUT(@"Can't get jack property(Jack status)");
#endif
	
	/////////////////////
    // Based on all this data, look and see what the jack status is
    
    if (dataSource == 'hdpn')
	{
        DEBUG_OUTPUT(@"Jack: Connected");
        if ([userDefaults boolForKey:@"showInMenuBar"]) [statusItem setImage:conn];
        [pool release];
        return TRUE;
    }
    else if (dataSource == 'ispk')
	{
        DEBUG_OUTPUT(@"Jack: Disconnected");
        //DEBUG_OUTPUT1(@"%@",dataSourceName);
        if ([userDefaults boolForKey:@"showInMenuBar"]) [statusItem setImage:disconn];
        [pool release];
        return FALSE;
    }
    else
	{
        DEBUG_OUTPUT(@"Jack: Error in connection check");
        [pool release];
        return FALSE;
    }
	
	
}
#pragma mark 
#pragma mark Delegate Fns

// pretty much when the app is open and someone double clicks the icon in the finder
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag
{
    if( !flag ) [self openPrefs:self];
    return YES;
} 

- (void) songChanged:(NSNotification *)aNotification 
{
    NSString     *pState = nil;
    
    pState = [[aNotification userInfo] objectForKey:@"Player State"];
    if ([pState isEqualToString:@"Paused"])
	{
        isPlaying = NO;
        DEBUG_OUTPUT(@"iTunes status: PAUSED");
	}
	else if ([pState isEqualToString:@"Stopped"])
	{
		isPlaying = NO;
		DEBUG_OUTPUT(@"iTunes status: STOPPED");
		
	}
	else if ([pState isEqualToString:@"Playing"])
	{
		isPlaying = YES;
		DEBUG_OUTPUT(@"iTunes status: PLAYING");
	}
	
	if (isPlaying && [userDefaults boolForKey:@"guessMode"])
	{
		BOOL connected = [self jackConnected];
		
		if (!connected) [userDefaults setBool:FALSE forKey:@"headphonesMode"];
		else if (connected) [userDefaults setBool:TRUE forKey:@"headphonesMode"];
	}
}


#pragma mark-

// Fn run when proc'ed by the listener
inline OSStatus AHPropertyListenerProc(AudioDeviceID           inDevice,
                                       UInt32                  inChannel,
                                       Boolean                 isInput,
                                       AudioDevicePropertyID   inPropertyID,
                                       void*                   inClientData)
{
    // Create a pool for our Cocoa objects to dump into. Otherwise we get lots of leaks.
	// this thread is running off the main thread, therefore it has no automatic autorelease pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    // inClientData works now! Makes my job _so_ much easier. Turns out that I was using the wrong proc template
    // C fns don't know what 'self' is, so we spell it out right here
    id self = (id)inClientData;
	
	
    // debug block. comparing int's, so really shouldnt effect speed
	#if MY_DEBUG_FLAG
		if (inPropertyID == kAudioDevicePropertyVolumeScalar) DEBUG_OUTPUT(@"Volume Trigger");
		else if (inPropertyID == kAudioDevicePropertyMute) DEBUG_OUTPUT(@"Mute Trigger");
		else if (inPropertyID == kAudioDevicePropertyDataSource) DEBUG_OUTPUT(@"DataSource Trigger");
		else if (inPropertyID == kAudioDevicePropertyDataSources) DEBUG_OUTPUT(@"DataSources Trigger");
	#endif
    
    // Getting the volume | this solves the problem coming out of mute, or when the user does some freaky stuff with the mute button
    Float32 volLvl;
    UInt32 buff1 = sizeof volLvl;
    OSStatus err1 = AudioDeviceGetProperty(inDevice,1,0,kAudioDevicePropertyVolumeScalar,&buff1,&volLvl);

    if (err1 != noErr) DEBUG_OUTPUT(@"Can't get volume property");
    
	DEBUG_OUTPUT1(@"Volume Level: %f", volLvl);
    
     /* 
	    Here's what happens. Since we are set up to listen for the volume trigger AND the mute trigger, when the volume is put to 0, 
        we get put here for 0 volume and mute (because Apple likes 0 volume == mute). To counter this, we will just blow off 0 volume 
        trigger and then wait for our mute, as it is much easier that way 
	
		The second part (the else return) is there because we don't care about the volume scalar adjustments, so we just throw it out
		if we proc off it. The only purpose it serves is to tell us if the volume is hit to zero
	 */
    if (inPropertyID == kAudioDevicePropertyVolumeScalar)
	{
		if (volLvl == 0.0) return noErr;
		//else return noErr;
	}
    
    // Getting the mute button status 
    UInt32 muteOn;
    UInt32 buff2 = sizeof muteOn;
    OSStatus err2 = AudioDeviceGetProperty(inDevice,
                                           [[NSUserDefaults standardUserDefaults] integerForKey:@"multichannelMute"],
                                           0,kAudioDevicePropertyMute,&buff2,&muteOn);
    if (err2 != noErr) DEBUG_OUTPUT(@"Can't get mute property");
    DEBUG_OUTPUT1(@"Mute On: %i", muteOn);
    
    /* The old jab-jab-hook combo. When the volume is at zero, and the mute is OFF, we don't want to play. 
	 Just because mute is off doesn't mean that I can hear you ;)
	 
	 Actually, if there is a very faint volume setting you can put on by doing some combo of mute and whatnot
	 We really don't care about that though
	 */
    if ((muteOn == 0) && volLvl == 0.0) muteOn = 1;
    
    //// Pre-fetching all our stats
    
    // TRUE if headphones mode is on
    BOOL hpMode = [userDefaults boolForKey:@"headphonesMode"];
    
    // if we want !force open, take isActive, otherwise lie and always say TRUE (activates iTunes if it has to)
    BOOL isActive = (![userDefaults boolForKey:@"force open"]) ? [self isActive] : TRUE;
    
    // AppHit keeps track of who started playing itunes. When enabled, AppHit makes sure that it will only turn itunes on if it touched it first (ie. you have itunes playing and plug in the headphones; you dont want it to start playing)
    // if we want enableAppHit, take appHit, otherwise lie and always say 1 (always touch iTunes, regardless if it touched it first or not)
    BOOL appHit = ([userDefaults boolForKey:@"enableAppHit"]) ? [userDefaults boolForKey:@"appHit"] : 1;
    
    // TRUE if iTunes is playing
    BOOL isPlaying = [self isPlaying];
    
    // if we want enableFlowing, take audioFlowing, otherwise lie and always say 0 (allows iTunes to be touched regardless of whats playing)
    BOOL isFlowing = ([userDefaults boolForKey:@"enableFlowing"]) ? [self audioFlowing] : 0;
    
	// TRUE if headphones in jack
	BOOL jConnect = [self jackConnected];
	
	/* 
	 here is the story
	 when we modify the jack, we are always looking the properties prior to modification
	 for example, if we go plug->unplug, we will be looking at all of plug's properties
	 same the other way round
	 
	 now this may not seem like an immediate problem, but consider the following situation
	 to start:
	 
	 ispk mute:0
	 hdpn mute:0
	 
	 user is using hdpn
	 user mutes
	 breakaway correctly registers and cuts off sound
	 user pulls hdpn (moving to ispk)
	 breakaway does not start itunes again
	 
	 now, we have this situation
	 
	 ispk mute:0
	 hdpn mute:1
	 
	 if the user were to plug in, then breakaway would read that the mute is off, because
	 we are moving from ispk->hdpn, thus, it would be reading ispk instead of hdpn, registering mute as off
	 
	 as such, breakaway will start itunes with the system muted
	 
	 this line stores the last known state of the mute in question
	 */
	if (inPropertyID == kAudioDevicePropertyDataSource || inPropertyID == kAudioDevicePropertyDataSources)
	{
		if (jConnect) [[NSUserDefaults standardUserDefaults] setBool:muteOn forKey:@"ispkMuteOn"];
		else if (!jConnect) [[NSUserDefaults standardUserDefaults] setBool:muteOn forKey:@"hdpnMuteOn"];
		muteOn = [[NSUserDefaults standardUserDefaults] boolForKey:(jConnect?@"hdpnMuteOn":@"ispkMuteOn")];
	}
	else
	{
		if (jConnect) [[NSUserDefaults standardUserDefaults] setBool:muteOn forKey:@"hdpnMuteOn"];
		else if (!jConnect) [[NSUserDefaults standardUserDefaults] setBool:muteOn forKey:@"ispkMuteOn"];
	}
	
	
    // If we call in too rapid a succession, the audio device is too slow to know if audio has stopped flowing or not. We check here to make sure that a set amount of time has passed before trusting isFlowing
    DEBUG_OUTPUT1(@"Time between calls: %f (seconds)",[[NSDate date] timeIntervalSinceDate:[self then]]);
    // DEBUG_OUTPUT1(@"%@",[NSDate date]);
    
    // If the time between two procs is less than 10ms, disregard the successive call
	// Note, this if expression is a hot line (though the isFlowing condition at the beginning should cool it down)
    if (isFlowing && ([[NSDate date] timeIntervalSinceDate:[self then]] < [userDefaults floatForKey:@"throwout"]))
     {
        DEBUG_OUTPUT1(@"Time between calls < %f. Throwing out proc",[userDefaults floatForKey:@"throwout"]);
        DEBUG_OUTPUT(@"\n\n");
        [pool release];
        return noErr;
     }
	
    //Actual Logic starts here
	if (isActive)
	{
		if (hpMode)
		 {
			DEBUG_OUTPUT(@"Headphones Mode");
			// This should take care of everything. Only thing that screws it up is when you have 0 vol and hit mute
			if (isPlaying)
			 {
				if (!jConnect) {[self executeScript]; appHit = 1;}
				else if (muteOn == 1) {[self executeScript]; appHit = 1;}
				//else if (jConnect);
				//else if (muteOn == 0);
			 }
			else
			 {
				 if ([userDefaults boolForKey:@"ror"] && jConnect && muteOn == 0 && !isFlowing && appHit == 1) {[self executeScript]; [self executeFadeIn]; appHit = 0;}
			 }
			
			 // User Triggers
			 if (inPropertyID == kAudioDevicePropertyMute)
			 {
				 if (muteOn) [[AIPluginSelector pluginController] executeTriggers:13];
				 else [[AIPluginSelector pluginController] executeTriggers:21];
			 }
			 // we iced scalar volume trigger, so if it's not mute, it has to be jack
			 else if (inPropertyID == kAudioDevicePropertyDataSource || inPropertyID == kAudioDevicePropertyDataSources)
			 {
				 if (jConnect) [[AIPluginSelector pluginController] executeTriggers:37];
				 else [[AIPluginSelector pluginController] executeTriggers:69];
			 }			 
			 
			// Printing our Growl notifications
			if ((inPropertyID != kAudioDevicePropertyMute) && (inPropertyID != kAudioDevicePropertyVolumeScalar)) jConnect ? [self growlNotify:NSLocalizedString(@"Jack Connected",@"") andDescription:@""] : [self growlNotify:NSLocalizedString(@"Jack Disconnected",@"") andDescription:@""];
		 }
		else if (!hpMode)
		 {
			// TRUE if we want smartPlay on
			BOOL smartPlay = [userDefaults boolForKey:@"smartPlay"];
			
			DEBUG_OUTPUT(@"Normal Mode");
			
			/* Putting in SmartPlay.
			   1:1 mode is too cruel (starting play when system is muted,etc), but I added it as a secret option for those that want it
			   Makes sure that iTunes isn't playing when we can't hear it
			*/
			if (smartPlay)
			 {
				if (isPlaying && muteOn == 1) {[self executeScript]; appHit = 1;}
				else if (!isPlaying && muteOn == 0 && [userDefaults boolForKey:@"ror"] && appHit == 1 && !isFlowing) {[self executeScript]; [self executeFadeIn]; appHit = 0;}
				else if (isPlaying && jConnect && [userDefaults boolForKey:@"guessMode"]) [userDefaults setBool:TRUE forKey:@"headphonesMode"];
				//else if (!isPlaying && muteOn == 1);
				//else if (isPlaying && muteOn == 0);
			 } 
			else if (!isFlowing)[self executeScript];
			 
			 if (inPropertyID == kAudioDevicePropertyMute)
			 {
				 if (muteOn)  [[AIPluginSelector pluginController] executeTriggers:11];
				 else [[AIPluginSelector pluginController] executeTriggers:19];
			 }			 
			
		 }
    }
    // Write our appHit
    [[NSUserDefaults standardUserDefaults] setBool:appHit forKey:@"appHit"];
    
    // update our time. (this point in time - next call) cannot be below 10ms
    [self updateThen];
		
    // Flush when we are done to rid ourselves of this mess ;)
    DEBUG_OUTPUT(@"\n\n");
    [pool release];
    
    // return noErr. Needed for an OSStatus call
    return noErr;
}

@end
