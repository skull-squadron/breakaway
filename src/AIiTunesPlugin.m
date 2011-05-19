//
//  AIiTunesPlugin.m
//  Breakaway
//
//  Created by Kevin Nygaard on 4/30/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#import "defines.h"
#import "debugUtils.h"
#import "iTunesBridge.h"
#import "AppController.h"
#import "AIiTunesPlugin.h"


static NSBundle *PluginBundle = nil;

@implementation AIiTunesPlugin

@synthesize enabled;

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
    return @"iTunes Plugin";
}

/******************************************************************************
 * image
 *
 * Required by protocol
 * The icon of the plugin
 *****************************************************************************/
- (NSImage*)image
{
    return [NSImage imageNamed:@"iTunes"];
}

#pragma mark -
#pragma mark Growl
/******************************************************************************
 * acceptedGrowlNotes
 *
 * Not required, unless you want to use Growl notifications
 * An array which specifies all the messages your plugin can send to Growl
 *****************************************************************************/
- (NSArray*)acceptedGrowlNotes
{
    return [self defaultGrowlNotes];
}

/******************************************************************************
 * defaultGrowlNotes
 *
 * Not required, unless you want to use Growl notifications
 * An array which specifies the default Growl messages you want to show the user
 *****************************************************************************/
- (NSArray*)defaultGrowlNotes
{
    return [NSArray arrayWithObjects:
        NSLocalizedString(@"SmartPlay",@""),
        NSLocalizedString(@"SmartPause",@""),
        nil];
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
	
    [NSBundle loadNibNamed:@"iTunesPlugin" owner:self];
    appController = controller;
    iTunes = [[SBApplication alloc] initWithBundleIdentifier:@"com.apple.iTunes"];
	isActive = [self iTunesActive];
    isPlaying = isActive ? [self iTunesPlaying] : FALSE;

    [self loadObservers];

    NSLog(@"iTunes plugin successfully loaded");

    
	return self;
}

- (NSView*) prefView
{
    return prefView;
}

/******************************************************************************
 * dealloc
 *
 * Called when plugin is destroyed. Cleans up
 *****************************************************************************/
- (void)dealloc
{
    [iTunes release];
    [self removeObservers];

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
    static bool appHit = false;
    bool jConnect, muteOn;

    // Don't need to do anything if iTunes is not running, or, we are disabled
    if (!isActive || !enabled) return;

    jConnect = triggerMask & kTriggerJackStatus;
    muteOn = triggerMask & kTriggerMute;

    if (hpMode)
    {
        DEBUG_OUTPUT(@"Headphones Mode");
        if (isPlaying)
        {
            if (!jConnect || muteOn)
            {
                [self iTunesPlayPause];
                [appController growlNotify:NSLocalizedString(@"SmartPause",@"") andDescription:@""];
                appHit = true;
            }
        }
        else // if (!playing)
        {
            if (jConnect && !muteOn && appHit)
            {
                [self iTunesPlayPause];
                [self iTunesThreadedFadeIn];
                [appController growlNotify:NSLocalizedString(@"SmartPlay",@"") andDescription:@""];
                appHit = false;
            }
        }
    } // end hpmode
    else //if (!hpmode)
    {        
        DEBUG_OUTPUT(@"Normal Mode");
        if (isPlaying)
        {
            if (muteOn)
            {
                [self iTunesPlayPause];
                [appController growlNotify:NSLocalizedString(@"SmartPause",@"") andDescription:@""];
                appHit = true;
            }
            else if (jConnect) hpMode = true;
        }
        else // if (!playing)
        {
            if (!muteOn && appHit)
            {
                [self iTunesPlayPause];
                [self iTunesThreadedFadeIn];
                [appController growlNotify:NSLocalizedString(@"SmartPlay",@"") andDescription:@""];
                appHit = false;                
            }
        }
    }
    DEBUG_OUTPUT(@"\n\n");
}

#pragma mark 
#pragma mark iTunes Observers
/******************************************************************************
 * loadObservers
 *
 * Loads observers to to monitor iTunes launching and playstate changes
 *****************************************************************************/
- (void)loadObservers
{
	// Installing this observer will proc songChanged: every time iTunes is stop/started
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(songChanged:) name:@"com.apple.iTunes.playerInfo" object:nil];
    
    // Installing these observers will proc their respective functions when iTunes opens/closes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(handleAppLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(handleAppQuit:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}

/******************************************************************************
 * removeObservers
 *
 * Removes iTunes observers
 *****************************************************************************/
- (void)removeObservers
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

/******************************************************************************
 * songChanged:
 *
 * Called whenever a song is changed/played/paused
 * Used to dynamically keep track of when iTunes is playing/paused
 * Also used for auto-determining headphones/normal mode
 *****************************************************************************/
- (void)songChanged:(NSNotification *)aNotification 
{
    NSString *pState = nil;
    BOOL jConnect = FALSE;
    jConnect = [appController jackConnected];
    
    pState = [[aNotification userInfo] objectForKey:@"Player State"];    
	if ([pState isEqualToString:@"Playing"])
    {
        isPlaying = YES;
        if (!jConnect) hpMode = FALSE;
        else hpMode = TRUE;
    }
    else isPlaying = NO;
}

/******************************************************************************
 * handleAppLaunch:
 *
 * Called when iTunes is launched
 * Used to dynamically keep track of the run status of iTunes
 *****************************************************************************/
- (void)handleAppLaunch:(NSNotification *)notification
{
    if ([@"com.apple.iTunes" caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame) isActive = TRUE;
}

/******************************************************************************
 * handleAppQuit:
 *
 * Called when iTunes is launched
 * Used to dynamically keep track of the run status of iTunes
 *****************************************************************************/
- (void)handleAppQuit:(NSNotification *)notification
{
    if ([@"com.apple.iTunes" caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame) isActive = FALSE;
}

#pragma mark 
#pragma mark iTunes Control
/******************************************************************************
 * iTunesActive
 *
 * Returns TRUE if iTunes is running. FALSE otherwise
 *****************************************************************************/
- (BOOL)iTunesActive
{
    return [iTunes isRunning];
}

/******************************************************************************
 * iTunesPlaying
 *
 * Returns TRUE if iTunes is playing a song
 * NOTE: this will activate iTunes, if iTunes wasn't running
 *****************************************************************************/
- (BOOL)iTunesPlaying
{
    int state = [iTunes playerState];
    if (state == iTunesEPlSPlaying) return TRUE;
    return FALSE;     
}

/******************************************************************************
 * iTunesPlayPause
 *
 * Pauses iTunes if it is playing, and vice versa
 * NOTE: this will activate iTunes, if iTunes wasn't running
 *****************************************************************************/
- (void)iTunesPlayPause
{
    [iTunes playpause];
}

/******************************************************************************
 * fadeInUsingTimer:
 *
 * Slowly raises the iTunes volume for a fade in effect
 * The current iTunes volume is saved, and then the fadein effect occurs up to
 * that point
 *****************************************************************************/
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

/******************************************************************************
 * iTunesThreadedFadeIn
 *
 * Creates a thread which runs fadeInUsingTimer
 * This function is essentially mutex'd, so you don't need to worry about
 * calling it too often, as successive calls will be thrown away
 *****************************************************************************/
- (void)iTunesThreadedFadeIn
{
    if (inFadeIn) return;
    
    int fadeInSpeed = [[appController userDefaults] integerForKey:@"fadeInTime"];
    if (fadeInSpeed <= 0) return;
    
    fadeInSpeed <<= 1; // gives multiplier between 1 -- 10
    
    inFadeIn = TRUE;
    [NSTimer scheduledTimerWithTimeInterval:BASE_FADE_IN_DELAY*fadeInSpeed target:self selector:@selector(fadeInUsingTimer:) userInfo:nil repeats:YES];
}

- (IBAction)testFadeIn:(id)sender
{
    [self iTunesThreadedFadeIn];
}

@end

