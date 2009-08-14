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
#import "GrowlNotifier.h"
#import <Sparkle/SUUpdater.h>
#import <MTCoreAudio/MTCoreAudio.h>
#import "DebugUtils.h"
#import "defines.h"
#import "AIPluginSelector.h"

static     unsigned char outBuff[4096];

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
                
                [NSNumber numberWithInt:2], @"SUUpdate",
                
                // Advanced
                [NSNumber numberWithBool:1], @"smartPlay",
                [NSNumber numberWithBool:1], @"enableAppHit",
                [NSNumber numberWithBool:0], @"multichannelMute",
                [NSNumber numberWithBool:0], @"enableFlowing",
                [NSNumber numberWithFloat:0], @"fadeInTime",
                [NSNumber numberWithBool:1], @"keepVol",                
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
	userDefaults = [NSUserDefaults standardUserDefaults];
	
	// We havent touched iTunes yet, so mark it in our preferences
    [userDefaults setBool:FALSE forKey:@"appHit"];	

    if ([userDefaults boolForKey:@"showSplash"]) [self startSplash];
	//////// Start Loading Stuff
    [self loadListeners];
	[self loadiTunesObservers];
    
	// MUST GO IN THIS ORDER (isActive, compile, isPlaying)
	
	isActive = [self iTunesActive];	
    [self compileScript];
    isPlaying = [self iTunesPlaying]; [playerState release];
    [self audioFlowing];
	
    DEBUG_OUTPUT(@"done!");
	
	// calls our controller to load our preference window, including all our plugins
	[PreferencesController sharedPreferencesController];
	
	//////// Stop Loading Stuff
	if ([userDefaults boolForKey:@"showSplash"])
	{
		[progressWheel stopAnimation:self];
		[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(stopSplash) userInfo:nil repeats:NO];
	}
}

- (void)disable
{	
    if ([[disableMI title] isEqual: NSLocalizedString(@"Disable",nil)])
    {
		DEBUG_OUTPUT(@"Disabling...");
		
		[self removeListener:kAudioDevicePropertyDataSource];
        if ([userDefaults boolForKey:@"mute watch"])
        {
            [self removeListener:kAudioDevicePropertyMute];
            [self removeListener:kAudioDevicePropertyVolumeScalar];
        }
        
        [disableMI setTitle:NSLocalizedString(@"Enable",nil)];
        [statusItem setImage:disabled];
    }
    else if ([[disableMI title] isEqual: NSLocalizedString(@"Enable",nil)])
    {
		DEBUG_OUTPUT(@"Enabling...");
        
		[self attachListener:kAudioDevicePropertyDataSource];
		if ([userDefaults boolForKey:@"mute watch"])
		{
			[self attachListener:kAudioDevicePropertyMute];
			[self attachListener:kAudioDevicePropertyVolumeScalar];
		}
        
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
    [self attachListener:kAudioDevicePropertyDataSource];
    if ([userDefaults boolForKey:@"showInMenuBar"]) [self setupStatusItem];
    if ([userDefaults boolForKey:@"mute watch"])
	{
        [self attachListener:kAudioDevicePropertyMute];
        [self attachListener:kAudioDevicePropertyVolumeScalar];
	}
}

- (void)loadiTunesObservers
{
	// Installing this observer will proc songChanged: every time iTunes is stop/started
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(songChanged:) name:@"com.apple.iTunes.playerInfo" object:nil];
    
    // Installing these observers will proc their respective functions when iTunes opens/closes
    [[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(handleAppLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(handleAppQuit:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
}

#pragma mark Splash

- (void)startSplash
{
    // Find our version number so we can display it
    [versionString setStringValue: [NSString stringWithFormat:@"v%@", [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleVersion"]]];
    
    // make a window and make the contents that of what we put in the nib
    splashWind = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,392,218) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    [splashWind setHasShadow:YES];
    [splashWind setContentView: splash];
	[splashWind setBackgroundColor:[NSColor colorWithDeviceWhite:1.0 alpha:100]];
    [splashWind setAlphaValue:100];
    [splashWind makeKeyAndOrderFront:self];
    [splashWind setOpaque:NO];
	[splashWind setLevel:NSFloatingWindowLevel];
    [splashWind center];
    
    [progressWheel startAnimation:self];
}

- (void)stopSplash
{	    
    [splashWind setAlphaValue:0];
    [splashWind display];
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
    
    AudioDeviceID defaultDevice;
    UInt32 audioDeviceSize = sizeof defaultDevice;
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,&audioDeviceSize,&defaultDevice);
    
    int channel = 0;
    
    if (adProp == kAudioDevicePropertyVolumeScalar) channel = 1;
	else if (adProp == kAudioDevicePropertyMute)
    {
        UInt32 muteOn;
        OSStatus err2 = AudioDeviceGetProperty(defaultDevice,1,0,kAudioDevicePropertyMute,&audioDeviceSize,&muteOn);
        
        // If we get a return on channel 1 for mute status, it has channels. If we get an error, we will use channel 0
        if (err2 == noErr)
        {
            DEBUG_OUTPUT(@"Mute is multichanneled");
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"multichannelMute"];
            channel = 1;
        }
        else 
        {
            DEBUG_OUTPUT(@"Mute is not multichanneled");
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"multichannelMute"];
            channel = 0;
        }
    }
    
    // add a listener for changes in jack connectivity
    OSStatus err3 = AudioDeviceAddPropertyListener(defaultDevice,channel,0,adProp,(AudioDevicePropertyListenerProc)AHPropertyListenerProc,self);
    
    if (err != noErr || err3 != noErr) NSLog(@"ERROR: Trying to attach listener '%@'",osTypeToFourCharCode(adProp));
    else NSLog(@"Listener Attached '%@'",osTypeToFourCharCode(adProp));
    
    [pool release];
}

- (void)removeListener:(AudioDevicePropertyID)adProp
{
    AudioDeviceID defaultDevice;
    UInt32 audioDeviceSize = sizeof defaultDevice;
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,&audioDeviceSize,&defaultDevice);
    
    int channel = 0;
    
    // If we have a multichannel mute and we are trying to take it off, make sure we take it off the right channel
    if(adProp == kAudioDevicePropertyMute && [[NSUserDefaults standardUserDefaults] boolForKey:@"multichannelMute"]) channel = 1;
	else if (adProp == kAudioDevicePropertyVolumeScalar) channel = 1;
	
    OSStatus err2 = AudioDeviceRemovePropertyListener(defaultDevice,channel,0,adProp,(AudioDevicePropertyListenerProc)AHPropertyListenerProc);
	
    if (err != noErr || err2 != noErr) NSLog(@"ERROR: Trying to remove listener '%@'",osTypeToFourCharCode(adProp));
    else NSLog(@"Listener Removed '%@'",osTypeToFourCharCode(adProp));
}

- (BOOL)audioFlowing
{
#if DEBUG
#warning Soundflower status set programatically
#else
#error Soundflower status set programatically
#endif
    BOOL useSoundflower = TRUE;
    
    AudioDeviceID defaultDevice;
    UInt32 audioDeviceSize = sizeof defaultDevice;
    AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,&audioDeviceSize,&defaultDevice);
    
    // we could be switching between defaultOut and headphones. best wait for everyone to get resituated
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    
    UInt32 runningSomewhere;
    UInt32 uint32Size = sizeof runningSomewhere;
    AudioDeviceGetProperty(defaultDevice,0,0,kAudioDevicePropertyDeviceIsRunningSomewhere,&uint32Size,&runningSomewhere);
    
    if (!runningSomewhere || !useSoundflower) return runningSomewhere;
        
    audioIsFlowing = BAAudioActivityUnknown;
    NSArray *soundflowerArray = [MTCoreAudioDevice devicesWithName:@"Soundflower (2ch)" havingStreamsForDirection:kMTCoreAudioDevicePlaybackDirection];
    if (![soundflowerArray count]) return BAAudioDormant;
    
    MTCoreAudioDevice *soundflowerDevice = [soundflowerArray objectAtIndex:0];
    AudioDeviceID soundflowerDeviceID = [soundflowerDevice deviceID];
    
    AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice,audioDeviceSize,&soundflowerDeviceID);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    
    // set up the recording callback
    [soundflowerDevice setIOTarget: self withSelector: @selector(readCycleForDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:) withClientData: NULL];
    [soundflowerDevice deviceStart];
    
    while (audioIsFlowing == BAAudioActivityUnknown);
    
    [soundflowerDevice deviceStop];
    //[soundflowerDevice removeIOTarget];
    
    audioIsFlowing = BAAudioActivityUnknown;
    [soundflowerDevice setIOTarget: self withSelector: @selector(readCycleForDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:) withClientData: NULL];
    [soundflowerDevice deviceStart];
    
    // we put this here instead of a while loop because there are certain instances where the iotarget won't get called, then we would be stuck here forever
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);    
    
    [soundflowerDevice deviceStop];    
    
    DEBUG_OUTPUT1(@"Audio is %@.",audioIsFlowing?@"flowing":@"not flowing");
    
    AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice,audioDeviceSize,&defaultDevice);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);    
    
    return audioIsFlowing == BAAudioActive;
}

- (OSStatus)readCycleForDevice:(MTCoreAudioDevice*)theDevice timeStamp:(const AudioTimeStamp*)now inputData:(const AudioBufferList*)inputData inputTime:(const AudioTimeStamp*)inputTime outputData:(AudioBufferList*)outputData outputTime:(const AudioTimeStamp*)outputTime clientData:(void*)clientData
{
    if (audioIsFlowing != BAAudioActivityUnknown) return (noErr);
    
    const AudioBuffer *buffer;
    buffer = &inputData->mBuffers[0];
    
    memcpy (outBuff,buffer->mData, buffer->mDataByteSize);
    
    if (outBuff[0] != 0) audioIsFlowing = BAAudioActive;
    else audioIsFlowing = BAAudioDormant;
    
    return (noErr);
}


- (BOOL)jackConnected
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    AudioDeviceID defaultDevice;
    UInt32 audioDeviceSize = sizeof defaultDevice;
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,&audioDeviceSize,&defaultDevice);
	
	UInt32 dataSource;
	UInt32 dataSourceSize = sizeof dataSource;
	OSStatus err2 = AudioDeviceGetProperty(defaultDevice,0,0,kAudioDevicePropertyDataSource,&dataSourceSize,&dataSource);
    
    BOOL jackConnected = FALSE;

    if (err != noErr || err2 != noErr) NSLog(@"ERROR: Trying to get jack status");	
    else if (dataSource == 'hdpn')
	{
        DEBUG_OUTPUT(@"Jack: Connected");
        if ([userDefaults boolForKey:@"showInMenuBar"]) [statusItem setImage:conn];
        jackConnected = TRUE;
    }
    else
	{
        DEBUG_OUTPUT(@"Jack: Disconnected");
        if ([userDefaults boolForKey:@"showInMenuBar"]) [statusItem setImage:disconn];
        jackConnected = FALSE;
    }
    
    [pool release];
    return jackConnected;
}

#pragma mark 
#pragma mark Delegate Fns

// pretty much when the app is open and someone double clicks the icon in the finder
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if( !flag ) [self openPrefs:self];
    return YES;
} 

- (void)songChanged:(NSNotification *)aNotification 
{
    NSString *pState = nil;
    
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

    // we don't know who self is, so we passed it in as a parameter. how clever!
    id self = (id)inClientData;
    
    BOOL isPlaying = [self isPlaying]; // TRUE if iTunes is playing

    // this has to be determined now; if we wait any longer, then we are going to detect the sound that plays when you change the volume! also, if we are playing, this option is useless to us.
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.3, false);
    BAAudioFlowing isFlowing = (!isPlaying && [userDefaults boolForKey:@"enableFlowing"]) ? [self audioFlowing] : BAAudioDormant;

    DEBUG_OUTPUT1(@"'%@' Trigger",osTypeToFourCharCode(inPropertyID));
    
    // Getting the volume | this solves the problem coming out of mute, or when the user does some freaky stuff with the mute button
    Float32 volLevel;
    UInt32 volLevelSize = sizeof volLevel;
    OSStatus err = AudioDeviceGetProperty(inDevice,1,0,kAudioDevicePropertyVolumeScalar,&volLevelSize,&volLevel);
    if (err != noErr) DEBUG_OUTPUT(@"ERROR: Volume property fetch bad");
	DEBUG_OUTPUT1(@"Volume Level: %f",volLevel);
    
    // Here's what happens. Since we are set up to listen for the volume trigger AND the mute trigger, when the volume is put to 0, we get put here for 0 volume and mute (because Apple likes 0 volume == mute). To counter this, we will just blow off 0 volume trigger and then wait for our mute, as it is much easier that way. The only purpose it serves is to tell us if the volume is hit to zero
    if (inPropertyID == kAudioDevicePropertyVolumeScalar && volLevel == 0.0) return noErr;
    
    // Getting the mute button status 
    UInt32 muteOn;
    UInt32 muteOnSize = sizeof muteOn;
    OSStatus err2 = AudioDeviceGetProperty(inDevice,[[NSUserDefaults standardUserDefaults] integerForKey:@"multichannelMute"],0,kAudioDevicePropertyMute,&muteOnSize,&muteOn);
    if (err2 != noErr) DEBUG_OUTPUT(@"ERROR: Mute property fetch bad");
    DEBUG_OUTPUT1(@"Mute On: %i",muteOn);
    
    // If we have 0 volume and our mute is labeled as off, act as if it was on.	 
    // Actually, there may be a faint sound, but if you have 0 sound and hit mute, chances are, you don't want sound.
    if (muteOn == 0 && volLevel == 0.0) muteOn = 1;
    
    //// Pre-fetching all our stats
    BOOL hpMode = [userDefaults boolForKey:@"headphonesMode"]; // TRUE if headphones mode is on
    BOOL jConnect = [self jackConnected]; // TRUE if headphones in jack
    
    // if we want !force open, take isActive, otherwise lie and always say TRUE (which will activate iTunes if it has to)
    BOOL isActive = (![userDefaults boolForKey:@"force open"]) ? [self isActive] : TRUE;
    
    // AppHit keeps track of who started playing itunes. When enabled, AppHit makes sure that it will only turn itunes on if it touched it first (ie. you have itunes playing and plug in the headphones; you dont want it to start playing)
    // if we want enableAppHit, take appHit, otherwise lie and always say 1 (always touch iTunes, regardless if it touched it first or not)
    BOOL appHit = ([userDefaults boolForKey:@"enableAppHit"]) ? [userDefaults boolForKey:@"appHit"] : 1;

    // if we want enableFlowing, take audioFlowing, otherwise lie and always say 0 (allows iTunes to be touched regardless of whats playing)
    // funny, 
    
	
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
	
    if (!isActive) {[pool release]; return noErr;}
    if (hpMode)
    {
        DEBUG_OUTPUT(@"Headphones Mode");
        // This should take care of everything. Only thing that screws it up is when you have 0 vol and hit mute
        if (isPlaying)
        {
            if (!jConnect) {[self executeScript]; appHit = 1;}
            else if (muteOn == 1) {[self executeScript]; appHit = 1;}
        }
        else
            if ([userDefaults boolForKey:@"ror"] && jConnect && muteOn == 0 && !isFlowing && appHit == 1) {[self executeScript]; [self executeFadeIn]; appHit = 0;}
        
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
    else
    {
        // TRUE if we want smartPlay on
        BOOL smartPlay = [userDefaults boolForKey:@"smartPlay"];
        
        DEBUG_OUTPUT(@"Normal Mode");
        
         // 1:1 mode is too cruel (starting play when system is muted,etc), but I added it as a secret option for those that want it. Makes sure that iTunes isn't playing when we can't hear it
        if (smartPlay)
        {
            if (isPlaying && muteOn == 1) {[self executeScript]; appHit = 1;}
            else if (!isPlaying && muteOn == 0 && [userDefaults boolForKey:@"ror"] && appHit == 1 && !isFlowing) {[self executeScript]; [self executeFadeIn]; appHit = 0;}
            else if (isPlaying && jConnect && [userDefaults boolForKey:@"guessMode"]) [userDefaults setBool:TRUE forKey:@"headphonesMode"];
        } 
        else if (!isFlowing)[self executeScript];
        
        if (inPropertyID == kAudioDevicePropertyMute)
        {
            if (muteOn)  [[AIPluginSelector pluginController] executeTriggers:11];
            else [[AIPluginSelector pluginController] executeTriggers:19];
        }			 
        
    }
    // Write our appHit
    [[NSUserDefaults standardUserDefaults] setBool:appHit forKey:@"appHit"];
        
    // Flush when we are done to rid ourselves of this mess ;)
    DEBUG_OUTPUT(@"\n\n");
    
    [pool release];
    return noErr;
}

@end
