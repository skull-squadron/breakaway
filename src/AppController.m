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

#import <Sparkle/SUUpdater.h>
#import <CoreAudio/CoreAudio.h>

#import "PreferencesController.h"
#import "GrowlNotifier.h"
#import "DebugUtils.h"
#import "defines.h"
#import "AIPluginSelector.h"

static AppController *sharedAppController = nil;

@implementation AppController

+ (AppController *)sharedAppController
{
    if (!sharedAppController) sharedAppController = self;
    return sharedAppController;
}

// Cool thing about +initialize is that it runs before any other method gets called
+ (void)initialize
{
    // Setting up our defaults here
    NSDictionary *defaults;
    defaults = [NSDictionary dictionaryWithObjectsAndKeys: 
                // General
                [NSNumber numberWithBool:1], @"guessMode",
                [NSNumber numberWithBool:1], @"headphonesMode",
                                
                [NSNumber numberWithBool:1], @"showInMenuBar",
                [NSNumber numberWithBool:0], @"showIcon",                
                [NSNumber numberWithInt:2], @"SUUpdate",
                
                [NSNumber numberWithFloat:0], @"fadeInTime",
                [NSNumber numberWithBool:1], @"keepVol",                
                // Advanced
                [NSNumber numberWithBool:1], @"enableAppHit", // hidden
                nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    DEBUG_OUTPUT1(@"Registered Defaults: %@",defaults);
}

- (void)dealloc
{
    [self killStatusItem];
    [super dealloc];
}

- (void)awakeFromNib
{
    sharedAppController = self;
	userDefaults = [NSUserDefaults standardUserDefaults];
    iTunes = [[SBApplication alloc] initWithBundleIdentifier:@"com.apple.iTunes"];
    appHit = FALSE;
    inFadeIn = FALSE;

	// Start Loading Stuff
    [self loadListeners];
	[self loadiTunesObservers];
    if ([userDefaults boolForKey:@"showInMenuBar"]) [self setupStatusItem];
    
	isActive = [self iTunesActive];	
    isPlaying = isActive ? [self iTunesPlaying] : FALSE;
    hpMode = [userDefaults boolForKey:@"headphonesMode"];
    enableAppHit = [userDefaults boolForKey:@"enableAppHit"];
	
	// calls our controller to load our preference window, including all our plugins
	[PreferencesController sharedPreferencesController];
    DEBUG_OUTPUT(@"finished setting up and loading prefs");
}

#pragma mark-
#pragma mark Startup Functions
- (void)loadListeners
{
    // Audio
    [self attachListener:kAudioDevicePropertyDataSource];
    [self attachListener:kAudioDevicePropertyMute];
    [self attachListener:kAudioDevicePropertyVolumeScalar];
    
    // Backend
    [userDefaults addObserver:self forKeyPath:@"headphonesMode" options:NSKeyValueObservingOptionNew context:NULL];
    [userDefaults addObserver:self forKeyPath:@"enableAppHit" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)loadiTunesObservers
{
	// Installing this observer will proc songChanged: every time iTunes is stop/started
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(songChanged:) name:@"com.apple.iTunes.playerInfo" object:nil];
    
    // Installing these observers will proc their respective functions when iTunes opens/closes
    [[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(handleAppLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(handleAppQuit:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
}

#pragma mark 
#pragma mark Status item
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
    [self growlNotify:NSLocalizedString(@"Breakaway Disabled",nil) andDescription:NSLocalizedString(@"The menu extra has sucessfully been disabled. Breakaway is still running.",nil)];
}

- (void)disable
{	
    if ([[disableMI title] isEqual: NSLocalizedString(@"Disable",nil)])
    {
		DEBUG_OUTPUT(@"Disabling...");
		
		[self removeListener:kAudioDevicePropertyDataSource];
        [self removeListener:kAudioDevicePropertyMute];
        [self removeListener:kAudioDevicePropertyVolumeScalar];
        
        [disableMI setTitle:NSLocalizedString(@"Enable",nil)];
        [statusItem setImage:disabled];
    }
    else if ([[disableMI title] isEqual: NSLocalizedString(@"Enable",nil)])
    {
		DEBUG_OUTPUT(@"Enabling...");
        
		[self attachListener:kAudioDevicePropertyDataSource];
        [self attachListener:kAudioDevicePropertyMute];
        [self attachListener:kAudioDevicePropertyVolumeScalar];
		[disableMI setTitle:NSLocalizedString(@"Disable",nil)];
		[self jackConnected];
    }
    else
    {
        NSLog(@"An error has occured while trying to disable Breakaway. Please notify the developer.");
    }
    
}
#pragma mark 
#pragma mark IB Button Actions
- (IBAction)showInMenuBarAct:(id)sender
{
    [userDefaults boolForKey:@"showInMenuBar"] ? [self setupStatusItem]:[self killStatusItem];
}

- (IBAction)openPrefs:(id)sender
{
	[[PreferencesController sharedPreferencesController] showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)openInfo:(id)sender
{
	[NSApp orderFrontStandardAboutPanel:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)openUpdater:(id)sender
{
	[[SUUpdater sharedUpdater] checkForUpdates:nil];
	[NSApp activateIgnoringOtherApps:YES];
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

#pragma mark 
#pragma mark iTunes
-(BOOL)iTunesActive
{
    //*DEPRECIATED* Used only once for the initial status of iTunes. Further queries of iTunes status are handled by handleAppLaunch/Quit:
    BOOL iTunesUp = [[[[NSWorkspace sharedWorkspace] launchedApplications] valueForKey:@"NSApplicationName"] containsObject:@"iTunes"];
    
    if (iTunesUp) return YES;
    return NO;
}

// Will wake iTunes
-(BOOL)iTunesPlaying
{
    int state = [iTunes playerState];
    if (state == iTunesEPlSPlaying) return TRUE;
    return FALSE;     
}

// Will wake iTunes
- (void)iTunesPlayPause
{
    [iTunes playpause];
}

// Will wake iTunes
- (void)iTunesVolumeFadeIn
{
    DEBUG_OUTPUT(@"Executing fade in...");
    inFadeIn = TRUE;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    float fadeInSpeed = [userDefaults floatForKey:@"fadeInTime"];
    
    [self fadeInUsingTimer:[NSTimer scheduledTimerWithTimeInterval:0.5*fadeInSpeed target:self selector:@selector(fadeInUsingTimer:) userInfo:nil repeats:YES]];
    
    [pool release];
    inFadeIn = FALSE;
}

- (void)fadeInUsingTimer:(NSTimer*)timer
{
    static int maxVolume = 100;
    static int x = 0;
    if (x == 0) maxVolume = [iTunes soundVolume];
    
    [iTunes setValue:[NSNumber numberWithInt:x] forKey:@"soundVolume"];
    x++;
    
    if (x > maxVolume)
    {
        [timer invalidate]; // base case
        x = 0;
        inFadeIn = FALSE;
    }
}

- (void)iTunesThreadedFadeIn
{
    if (inFadeIn || ![userDefaults boolForKey:@"fadeInEnable"]) return;
    
    int fadeInSpeed = [userDefaults integerForKey:@"fadeInTime"];
    fadeInSpeed = (100 - fadeInSpeed); // gives multiplier between 0 -- 100
    float interval = (float)fadeInSpeed/10 + 1;
    
    inFadeIn = TRUE;
    [NSTimer scheduledTimerWithTimeInterval:BASE_FADE_IN_DELAY*interval target:self selector:@selector(fadeInUsingTimer:) userInfo:nil repeats:YES];
}

#pragma mark iTunes launch/quit
- (void)handleAppLaunch:(NSNotification *)notification
{
    if ([@"com.apple.iTunes" caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame) isActive = TRUE;    
}

- (void) handleAppQuit:(NSNotification *)notification
{
    if ([@"com.apple.iTunes" caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame) isActive = FALSE;
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
        if ([userDefaults boolForKey:@"showInMenuBar"] && [[disableMI title] isEqual:NSLocalizedString(@"Disable",nil)]) [statusItem setImage:conn];
        jackConnected = TRUE;
    }
    else
	{
        DEBUG_OUTPUT(@"Jack: Disconnected");
        if ([userDefaults boolForKey:@"showInMenuBar"] && [[disableMI title] isEqual:NSLocalizedString(@"Disable",nil)]) [statusItem setImage:disconn];
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
    if (!flag) [self openPrefs:self];
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Keep these ivars updated so the proc method doesn't have to call these methods
    if ([keyPath isEqualToString:@"headphonesMode"]) hpMode = [userDefaults boolForKey:@"headphonesMode"];
    else if ([keyPath isEqualToString:@"enableAppHit"]) enableAppHit = [userDefaults boolForKey:@"enableAppHit"];
}

- (void)songChanged:(NSNotification *)aNotification 
{
    NSString *pState = nil;
    isPlaying = NO;

    pState = [[aNotification userInfo] objectForKey:@"Player State"];    
	if ([pState isEqualToString:@"Playing"]) isPlaying = YES;

	// Gussing the right mode
    if (isPlaying)
	{
		BOOL connected = [self jackConnected];
		[userDefaults setBool:connected forKey:@"headphonesMode"];
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
    
    DEBUG_OUTPUT1(@"'%@' Trigger",osTypeToFourCharCode(inPropertyID));
    
    // Getting the volume | this solves the problem coming out of mute, or when the user does some freaky stuff with the mute button
    Float32 volLevel;
    UInt32 volLevelSize = sizeof volLevel;
    OSStatus err = AudioDeviceGetProperty(inDevice,1,0,kAudioDevicePropertyVolumeScalar,&volLevelSize,&volLevel);
    if (err != noErr) DEBUG_OUTPUT(@"ERROR: Volume property fetch bad");
	DEBUG_OUTPUT1(@"Volume Level: %f",volLevel);
    
    // Here's what happens. Since we are set up to listen for the volume trigger AND (potentially) the mute trigger, when the volume is put to 0, we get put here for 0 volume and mute (because Apple likes 0 volume == mute). To counter this, we will just blow off 0 volume trigger and then wait for our mute, as it is much easier that way. The only purpose it serves is to tell us if the volume is hit to zero
    if (inPropertyID == kAudioDevicePropertyVolumeScalar && volLevel == 0.0) return noErr;
    
    // Getting the mute button status 
    UInt32 muteOn;
    UInt32 muteOnSize = sizeof muteOn;
    OSStatus err2 = AudioDeviceGetProperty(inDevice,[[NSUserDefaults standardUserDefaults] integerForKey:@"multichannelMute"],0,kAudioDevicePropertyMute,&muteOnSize,&muteOn);
    if (err2 != noErr) DEBUG_OUTPUT(@"ERROR: Mute property fetch bad");
    DEBUG_OUTPUT1(@"Mute On: %i",muteOn);
    
    /*
     If we have 0 volume and our mute is labeled as off, act as if it was on.	 
     Actually, there may be a faint sound, but if you have 0 sound and hit mute, chances are, you don't want sound.
     */
    if (muteOn == 0 && volLevel == 0.0) muteOn = 1;
    
    BOOL jConnect = [self jackConnected]; // TRUE if headphones in jack
    
	/* 
	 When we modify the jack, we are always looking the properties prior to modification. For example, if we plug->unplug, we will be looking at all of plug's properties. The same happens the other way around.
	 
	 This may not seem like an immediate problem, but consider the following situation-
	 
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
	
    // We have no further reason to continue. Goodbye!
    if (!isActive) {[pool release]; return noErr;}
    
    if (hpMode)
    {
        DEBUG_OUTPUT(@"Headphones Mode");
        if (isPlaying)
        {
            if (!jConnect)
            {
                [self iTunesPlayPause];
                appHit = 1;
            }
            else if (muteOn == 1)
            {
                [self iTunesPlayPause];
                appHit = 1;
            }
        }
        else // if (!playing)
        {
            if (jConnect && muteOn == 0 && appHit == 1)
            {
                [self iTunesPlayPause];
                [self iTunesThreadedFadeIn];
                appHit = 0;
            }
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
    } // end hpmode
    else //if (!hpmode)
    {        
        DEBUG_OUTPUT(@"Normal Mode");
        if (isPlaying)
        {
            if (muteOn == 1)
            {
                [self iTunesPlayPause];
                appHit = 1;
            }
            else if (jConnect) [userDefaults setBool:TRUE forKey:@"headphonesMode"];
        }
        else // if (!playing)
        {
            if (!muteOn && appHit == 1)
            {
                [self iTunesPlayPause];
                [self iTunesThreadedFadeIn];
                appHit = 0;                
            }
        }
        
        // User Triggers
        if (inPropertyID == kAudioDevicePropertyMute)
        {
            if (muteOn)  [[AIPluginSelector pluginController] executeTriggers:11];
            else [[AIPluginSelector pluginController] executeTriggers:19];
        }			 
    }
        
    [pool release];
    return noErr;
}

@end
