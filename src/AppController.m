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
#import "AIPluginProtocol.h"

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
                [NSNumber numberWithBool:1], @"showInMenuBar",
                [NSNumber numberWithBool:1], @"enableBreakaway",
                
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
    [self removeObservers];
    [self setStatusItem:NO];
    [self setEnabled:NO];
    
    //[VLC release];
    [super dealloc];
}

- (void)awakeFromNib
{
    sharedAppController = self;
	userDefaults = [NSUserDefaults standardUserDefaults];
    //VLC = [[SBApplication alloc] initWithBundleIdentifier:@"org.videolan.vlc"];
    
    appHit = FALSE;
    inFadeIn = FALSE;

	// Start Loading Stuff
	[self loadObservers];
    
    [self setStatusItem:[userDefaults boolForKey:@"showInMenuBar"]];
    [self setEnabled:[userDefaults boolForKey:@"enableBreakaway"]];
    
    enableAppHit = [userDefaults boolForKey:@"enableAppHit"];
	
	// calls our controller to load our preference window, including all our plugins
	[PreferencesController sharedPreferencesController];
    DEBUG_OUTPUT(@"finished setting up and loading prefs");
}

#pragma mark-
#pragma mark Startup Functions
- (void)loadObservers
{
    // Backend
    [userDefaults addObserver:self forKeyPath:@"enableAppHit" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeObservers
{
    // Backend
    [userDefaults removeObserver:self forKeyPath:@"enableAppHit"];
    
}


#pragma mark 
#pragma mark Status item
- (void)setStatusItem:(BOOL)enable
{	
    if (enable)
    {
        // Access these images using the enums
        if (images) [images release];
        images = [[NSArray arrayWithObjects: 
            [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"connected" ofType:@"png"]] autorelease],
            [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"disabled" ofType:@"png"]] autorelease],
            [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"disconnected" ofType:@"png"]] autorelease],
             nil] retain];

        // get the images for the status item set up
        for (NSImage *img in images)
        {
            if (!img) continue; // if we don't have an image to work with, don't fret
            [img setScalesWhenResized:TRUE];
            [img setSize:NSMakeSize(10,10)];
        }
        
        // Status bar stuff
        if (statusItem) [statusItem release];
        statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        [statusItem retain];
        
        [statusItem setMenu:statusItemMenu];
        [statusItem setEnabled:YES];
        [statusItem setHighlightMode:YES];
        
        // run this so we can get a correct state on our menu extra
        [self updateStatusItem];
    }
    else
    {
        // Release our status item
        if (statusItem)
        {
            [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
            [statusItem release];
        }

        if (images) [images release];
    }
}

- (void)updateStatusItem
{
    if (!statusItem) return;

    // Disabled
    if (![userDefaults boolForKey:@"enableBreakaway"])
    {
        [disableMI setTitle:NSLocalizedString(@"Enable",nil)];
        [statusItem setImage:[images objectAtIndex:kDisabledImg]];
    }
    // Enabled
    else
    {
        [disableMI setTitle:NSLocalizedString(@"Disable",nil)];

        // Status image
        if (jackConnected()) [statusItem setImage:[images objectAtIndex:kConnectedImg]];
        else [statusItem setImage:[images objectAtIndex:kDisconnectedImg]];
    }
}

- (void)setEnabled:(BOOL)enable
{	
    [userDefaults setBool:enable forKey:@"enableBreakaway"];
    if (!enable)
    {
		DEBUG_OUTPUT(@"Disabling...");
		
        [self removeListener:kAudioDevicePropertyDataSource];
        [self removeListener:kAudioDevicePropertyMute];
        //[self removeListener:kAudioDevicePropertyVolumeScalar];
    }
    else
    {
		DEBUG_OUTPUT(@"Enabling...");
        
        [self attachListener:kAudioDevicePropertyDataSource];
        [self attachListener:kAudioDevicePropertyMute];
        //[self attachListener:kAudioDevicePropertyVolumeScalar];
    }

    [self updateStatusItem];
}

#pragma mark 
#pragma mark IB Button Actions
- (IBAction)showInMenuBarAct:(id)sender
{
    [self setStatusItem:[userDefaults boolForKey:@"showInMenuBar"]];
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
    BOOL disable = NO;
    if ([[disableMI title] isEqual: NSLocalizedString(@"Disable",nil)]) disable = YES;
    [self setEnabled:!disable];
}

- (void)growlNotify:(NSString *)title andDescription:(NSString *)description
{
    [growlNotifier growlNotify:title andDescription:description];
}


#pragma mark VLC
-(BOOL)VLCActive
{
    return [VLC isRunning];
}

- (void)VLCPlayPause
{
    VLCDocument *doc = [[[VLC windows] objectAtIndex:0] document];
    [doc play];
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
    if ([keyPath isEqualToString:@"enableAppHit"]) enableAppHit = [userDefaults boolForKey:@"enableAppHit"];
}

#pragma mark AD Prop Fetches
// returns true if jack is connected. false otherwise
bool jackConnected(void)
{
    AudioDeviceID defaultDevice;
    OSStatus err;
    UInt32 audioDeviceSize = sizeof defaultDevice;
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,&audioDeviceSize,&defaultDevice);
    if (err != noErr) return false;
	
	UInt32 dataSource;
	UInt32 dataSourceSize = sizeof dataSource;
	err = AudioDeviceGetProperty(defaultDevice,0,0,kAudioDevicePropertyDataSource,&dataSourceSize,&dataSource);
    if (err != noErr) return false;

    return (dataSource == 'hdpn');
}

Float32 systemVolumeLevel(AudioDeviceID inDevice)
{
    // Getting the volume | this solves the problem coming out of mute, or when the user does some freaky stuff with the mute button
    Float32 volLevel = 0;
    UInt32 volLevelSize = sizeof volLevel;
    OSStatus err = AudioDeviceGetProperty(inDevice,1,0,kAudioDevicePropertyVolumeScalar,&volLevelSize,&volLevel);
    if (err != noErr) DEBUG_OUTPUT(@"ERROR: Volume property fetch bad");
	DEBUG_OUTPUT1(@"Volume Level: %f",volLevel);
    return volLevel;
}

bool muteStatus(AudioDeviceID inDevice)
{
    // Getting the mute button status 
    UInt32 muteOn = 0;
    UInt32 muteOnSize = sizeof muteOn;
    OSStatus err = AudioDeviceGetProperty(inDevice,[[NSUserDefaults standardUserDefaults] integerForKey:@"multichannelMute"],0,kAudioDevicePropertyMute,&muteOnSize,&muteOn);
    if (err != noErr) DEBUG_OUTPUT(@"ERROR: Mute property fetch bad");
    DEBUG_OUTPUT1(@"Mute On: %i",muteOn);
    return muteOn;
}

#pragma mark-
// Fn run when proc'ed by the listener
inline OSStatus AHPropertyListenerProc(AudioDeviceID           inDevice,
                                       UInt32                  inChannel,
                                       Boolean                 isInput,
                                       AudioDevicePropertyID   inPropertyID,
                                       void*                   inClientData)
{
    // see large comment below
    static bool hpMuteStatus = false;
    static bool ispkMuteStatus = false;

    id self = (id)inClientData; // for obj-c calls

    // Create a pool for our Cocoa objects to dump into. Otherwise we get lots of leaks. this thread is running off the main thread, therefore it has no automatic autorelease pool
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    DEBUG_OUTPUT1(@"'%@' Trigger",osTypeToFourCharCode(inPropertyID));
    
    bool muteOn = muteStatus(inDevice); // true if mute is on
    bool jConnect = jackConnected(); // true if headphones in jack
    
    // save mute data
    // we are changing audio sources. Mute data is old (we get the previous audio source's mute status)
	if (inPropertyID == kAudioDevicePropertyDataSource || inPropertyID == kAudioDevicePropertyDataSources)
	{
        // Store old mute data
		if (jConnect) muteOn = ispkMuteStatus;
		else muteOn = hpMuteStatus;

        // Grab correct mute data
		muteOn = jConnect ? hpMuteStatus : ispkMuteStatus;
	}
    // mute triggers are always correct
	else
	{
        // update our status
		if (jConnect) hpMuteStatus = muteOn;
		else ispkMuteStatus = muteOn;
	}

    // send data to plugins
    kTriggerMask triggerMask = 0;
    
    triggerMask |= muteOn ? kTriggerMute : 0;
    triggerMask |= jConnect ? kTriggerJackStatus : 0;
    triggerMask |= (inPropertyID != kAudioDevicePropertyMute) ? kTriggerInt : 0;
    [[AIPluginSelector pluginController] executeTriggers:triggerMask];

    // TODO: Growl notifications go here
    
#if 0
    if (hpMode)
    {
        DEBUG_OUTPUT(@"Headphones Mode");
        if (isPlaying)
        {
            if (!jConnect || muteOn == 1)
            {
                [self iTunesPlayPause];
                [self growlNotify:NSLocalizedString(@"SmartPause",@"") andDescription:@""];
                appHit = 1;
            }
        }
        else // if (!playing)
        {
            if (jConnect && muteOn == 0 && appHit == 1)
            {
                [self iTunesPlayPause];
                [self iTunesThreadedFadeIn];
                [self growlNotify:NSLocalizedString(@"SmartPlay",@"") andDescription:@""];
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
                [self growlNotify:NSLocalizedString(@"SmartPause",@"") andDescription:@""];
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
                [self growlNotify:NSLocalizedString(@"SmartPlay",@"") andDescription:@""];
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
    
    DEBUG_OUTPUT(@"\n\n");
#endif
    [pool release];
    return noErr;
}

@end
