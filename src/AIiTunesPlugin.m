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
#import "AIiTunesPlugin.h"


@implementation AIiTunesPlugin

@synthesize enabled;

// Required: name of unique plugin
- (NSString*)name
{
    return @"iTunes Plugin";
}

// Initilizer for the plugin. Sets up global variables
- (id)init
{
	if (!(self = [super init])) return nil;
	
	userDefaults = [NSUserDefaults standardUserDefaults];
    iTunes = [[SBApplication alloc] initWithBundleIdentifier:@"com.apple.iTunes"];
	isActive = [self iTunesActive];
    isPlaying = isActive ? [self iTunesPlaying] : FALSE;

    [self loadObservers];

    [GrowlApplicationBridge setGrowlDelegate:self];

    NSLog(@"iTunes plugin successfully loaded");

    
	return self;
}

// Run when plugin is destroyed. Clean up
- (void)dealloc
{
    [iTunes release];
    [self removeObservers];

    [super dealloc];
}

// Loads observers to see when iTunes changes playstates
- (void)loadObservers
{
	// Installing this observer will proc songChanged: every time iTunes is stop/started
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(songChanged:) name:@"com.apple.iTunes.playerInfo" object:nil];
    
    // Installing these observers will proc their respective functions when iTunes opens/closes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(handleAppLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(handleAppQuit:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}

// Removes iTunes observers
- (void)removeObservers
{
    // iTunes
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

- (void)songChanged:(NSNotification *)aNotification 
{
    NSString *pState = nil;
    isPlaying = NO;

    pState = [[aNotification userInfo] objectForKey:@"Player State"];    
	if ([pState isEqualToString:@"Playing"]) isPlaying = YES;
}

#pragma mark 
#pragma mark iTunes
// returns true if iTunes is running
-(BOOL)iTunesActive
{
    return [iTunes isRunning];
}

// returns true if iTunes is playing a song currently
// Note: Will wake iTunes
-(BOOL)iTunesPlaying
{
    int state = [iTunes playerState];
    if (state == iTunesEPlSPlaying) return TRUE;
    return FALSE;     
}

// pauses iTunes if it is playing, and vice versa
// Note: Will wake iTunes
- (void)iTunesPlayPause
{
    [iTunes playpause];
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

// Required: sends the interrupt mask (jack/mute status)
- (void)activate:(kTriggerMask)triggerMask
{
    bool jConnect = triggerMask & kTriggerJackStatus;
    bool muteOn = triggerMask & kTriggerMute;

    if (hpMode)
    {
        DEBUG_OUTPUT(@"Headphones Mode");
        if (isPlaying)
        {
            if (!jConnect || muteOn)
            {
                [self iTunesPlayPause];
                [self growlNotify:NSLocalizedString(@"SmartPause",@"") andDescription:@""];
                appHit = true;
            }
        }
        else // if (!playing)
        {
            if (jConnect && muteOn && appHit)
            {
                [self iTunesPlayPause];
                [self iTunesThreadedFadeIn];
                [self growlNotify:NSLocalizedString(@"SmartPlay",@"") andDescription:@""];
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
                [self growlNotify:NSLocalizedString(@"SmartPause",@"") andDescription:@""];
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
                [self growlNotify:NSLocalizedString(@"SmartPlay",@"") andDescription:@""];
                appHit = false;                
            }
        }
    }
    DEBUG_OUTPUT(@"\n\n");
}

- (void)growlNotify:(NSString *)title andDescription:(NSString *)description
{
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:title
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

- (NSDictionary *)registrationDictionaryForGrowl
{
	NSArray *defaultNotifications = [NSArray arrayWithObjects:
                                     NSLocalizedString(@"SmartPlay",@""),
                                     NSLocalizedString(@"SmartPause",@""),
                                     nil];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
                              defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
                              defaultNotifications, GROWL_NOTIFICATIONS_ALL,
                              @"Breakaway", GROWL_APP_NAME,
                              [NSNumber numberWithInt:1], GROWL_TICKET_VERSION,
                              nil];

}
@end
