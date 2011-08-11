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
#import "defines.h"

#import "GrowlNotifier.h"
#import "PreferencesController.h"
#import "AIPluginController.h"

#import "DebugUtils.h"

#import "AIPluginSelector.h"
#import "AIPluginProtocol.h"
#import "PreferenceHandler.h"

#import <CoreAudio/CoreAudio.h>
#import <Sparkle/SUUpdater.h>

//#define ANIMATION_SPEED 0.01666666 /* 60 Hz */
#define ANIMATION_SPEED 0.03333333 /* 30 Hz */

@implementation AppController

static NSArray *Animations = nil;

@synthesize growlNotifier, preferencesController, pluginController, userDefaults;

- (id)init
{
	if (!(self = [super init])) return nil;
    setSharedBreakaway(self);
	return self;
}

- (void)awakeFromNib
{
    // Our animations. It looks like a bit of a mess, but it makes sense.
    // It looked better without the NSNumbers, but it turns out you need them
    Animations = [[NSArray arrayWithObjects:
        [NSArray arrayWithObjects:[NSNumber numberWithInt:kPlugged],[NSNumber numberWithInt:kPU1],[NSNumber numberWithInt:kPU2],[NSNumber numberWithInt:kPU3],[NSNumber numberWithInt:kPU4],[NSNumber numberWithInt:kPU5],[NSNumber numberWithInt:kPU6],[NSNumber numberWithInt:kUnplugged],nil],
        [NSArray arrayWithObjects:[NSNumber numberWithInt:kPlugged],[NSNumber numberWithInt:kPD1],[NSNumber numberWithInt:kPD2],[NSNumber numberWithInt:kPD3],[NSNumber numberWithInt:kPD4],[NSNumber numberWithInt:kPD5],[NSNumber numberWithInt:kPD6],[NSNumber numberWithInt:kDisabled],nil],
        [NSArray arrayWithObjects:[NSNumber numberWithInt:kUnplugged],[NSNumber numberWithInt:kUD1],[NSNumber numberWithInt:kUD2],[NSNumber numberWithInt:kUD3],[NSNumber numberWithInt:kUD4],[NSNumber numberWithInt:kUD5],[NSNumber numberWithInt:kUD6],[NSNumber numberWithInt:kDisabled],nil],
        nil] retain];
    
    inAnimation = FALSE;
    
    // Setting up our defaults here
    NSDictionary *defaults;
    defaults = [NSDictionary dictionaryWithObjectsAndKeys: 
                // General
                [NSNumber numberWithBool:1], @"showInMenuBar",
                [NSNumber numberWithBool:1], @"enableBreakaway",
                
                [NSNumber numberWithBool:0], @"showIcon",                
                [NSNumber numberWithInt:2], @"SUUpdate",
                
                [NSNumber numberWithFloat:2], @"fadeInTime",
                
                [NSNumber numberWithBool:1], @"iTunesPluginEnabled", // FIXME: this shouldn't be hardcoded
                
                [NSNumber numberWithBool:1], @"keepVol",
                nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    DEBUG_OUTPUT1(@"Registered Defaults: %@",defaults);
    
    // Initialize controllers
    growlNotifier = [[GrowlNotifier alloc] init];
    pluginController = [[AIPluginController alloc] init];
    
    // For convience
	userDefaults = [NSUserDefaults standardUserDefaults];

	// Start Loading Stuff
    
    [self setStatusItem:[userDefaults boolForKey:@"showInMenuBar"]];
    [self setEnabled:[userDefaults boolForKey:@"enableBreakaway"]];
    
	
	// calls our controller to load our preference window, including all our plugins
    DEBUG_OUTPUT(@"finished setting up and loading prefs");
}

- (void)dealloc
{
    [self setStatusItem:NO];
    [self setEnabled:NO];
    [Animations release];
    
    [super dealloc];
}

#pragma mark 
#pragma mark Status item
- (void)setStatusItem:(BOOL)enable
{	
    if (enable)
    {
        // Access these images using the enums
        // Therefore, order is important. Do not change
        if (images) [images release];
        images = [[NSArray arrayWithObjects: 
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"plugged" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu1" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu2" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu3" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu4" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu5" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu6" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"unplugged" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud1" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud2" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud3" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud4" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud5" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud6" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"disabled" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd1" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd2" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd3" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd4" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd5" ofType:@"tiff"]] autorelease],
                   [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd6" ofType:@"tiff"]] autorelease],
                   nil] retain];
        
        // get the images for the status item set up
        for (NSImage *img in images)
        {
            if (!img) continue; // if we don't have an image to work with, don't fret
            [img setSize:NSMakeSize(15,15)]; 
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

/******************************************************************************
 * fadeInUsingTimer:
 *
 * Change the status icon. Very cool
 * To make it faster/slower, change the #define ANIMATION_SPEED
 * With the current implementation, it's kind of a pain to make more frames
 * All state transitions are 8 frames long
 *****************************************************************************/
- (void)animateUsingTimer:(NSTimer*)timer
{
    NSNumber *nextFrame = nil;
    nextFrame = [curAnimationEnumerator nextObject];
    
    if (nextFrame == nil)
    {
        [timer invalidate]; // base case
        inAnimation = FALSE;
        [curAnimationEnumerator release];
        return;
    }
    
    [statusItem setImage:[images objectAtIndex:[nextFrame intValue]]];
}

/******************************************************************************
 * updateStatusItem
 *
 * Creates a thread which runs animateUsingTimer:
 * This function is essentially mutex'd, so you don't need to worry about
 * calling it too often, as successive calls will be thrown away
 *****************************************************************************/
- (void)updateStatusItem
{
    // -1 is an illegal number. Serves us well for startup purposes (when you don't want/need an animation)
    static tImageType prevImage = -1;
    
    if (inAnimation) return;
    if (!statusItem) return;
    
    tImageAnimation animation = -1;
    BOOL reverse = FALSE;
        
    // Disabled
    if (![userDefaults boolForKey:@"enableBreakaway"])
    {
        reverse = FALSE;
        if (prevImage == kPlugged) animation = kPluggedDisabled; // plugged->disabled
        else if (prevImage == kUnplugged) animation = kUnpluggedDisabled; // unplugged->disabled
        prevImage = kDisabled;
        
        [disableMI setTitle:NSLocalizedString(@"Enable",nil)];
    }
    // Enabled
    else
    {        
        if (jackConnected()) // plugged
        {
            reverse = TRUE;
            if (prevImage == kUnplugged) animation = kPluggedUnplugged; // unplugged->plugged
            else if (prevImage == kDisabled) animation = kPluggedDisabled; // disabled->plugged
            prevImage = kPlugged;
        }
        else // unplugged
        {
            if (prevImage == kPlugged) animation = kPluggedUnplugged; // plugged->unplugged
            else if (prevImage == kDisabled){ animation = kUnpluggedDisabled; reverse = TRUE; } // disabled->unplugged
            prevImage = kUnplugged;
        }
        [disableMI setTitle:NSLocalizedString(@"Disable",nil)];
    }
    
    if (animation == -1) [statusItem setImage:[images objectAtIndex:prevImage]];
    else
    {
        curAnimationEnumerator = (!reverse) ? [[Animations objectAtIndex:animation] objectEnumerator] : [[Animations objectAtIndex:animation] reverseObjectEnumerator];
        
        [curAnimationEnumerator retain];
        
        inAnimation = TRUE;
        [NSTimer scheduledTimerWithTimeInterval:ANIMATION_SPEED target:self selector:@selector(animateUsingTimer:) userInfo:nil repeats:YES];
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
    if (!preferencesController) preferencesController = [[PreferencesController alloc] init];
	[preferencesController showWindow:nil];
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
            multichanMute = TRUE;
            channel = 1;
        }
        else 
        {
            DEBUG_OUTPUT(@"Mute is not multichanneled");
            multichanMute = FALSE;
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
    if(adProp == kAudioDevicePropertyMute && multichanMute) channel = 1;
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
}

#pragma mark AD Prop Fetches
- (BOOL)jackConnected
{
    return jackConnected();
}

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
    OSStatus err = AudioDeviceGetProperty(inDevice, (int)multichanMute, 0, kAudioDevicePropertyMute, &muteOnSize, &muteOn);
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

    DEBUG_OUTPUT1(@"'%@' Trigger",osTypeToFourCharCode(inPropertyID));
    
    bool muteOn = muteStatus(inDevice); // true if mute is on
    bool jConnect = jackConnected(); // true if headphones in jack
    
    // save mute data
    // we are changing audio sources. Mute data is old (we get the previous audio source's mute status)
	if (inPropertyID == kAudioDevicePropertyDataSource || inPropertyID == kAudioDevicePropertyDataSources)
	{
        // Store old mute data
		if (jConnect) ispkMuteStatus = muteOn;
		else hpMuteStatus = muteOn;

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
    [[self pluginController] executeTriggers:triggerMask];

    [self updateStatusItem];
    // TODO: Growl notifications go here
    
    [pool release];
    return noErr;
}

@end
