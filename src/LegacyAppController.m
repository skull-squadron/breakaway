/*
 * LegacyAppController.m
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

#import "LegacyAppController.h"
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



@implementation LegacyAppController


- (void)setEnabled:(BOOL)enable
{	
    [self.userDefaults setBool:enable forKey:@"enableBreakaway"];
    if (!enable) {
		DEBUG_OUTPUT(@"Disabling (legacy) ...");
        [self removeListener:kAudioDevicePropertyDataSource];
        [self removeListener:kAudioDevicePropertyMute];
        //[self removeListener:kAudioDevicePropertyVolumeScalar];
    } else {
		DEBUG_OUTPUT(@"Enabling (legacy) ...");
        [self attachListener:kAudioDevicePropertyDataSource];
        [self attachListener:kAudioDevicePropertyMute];
        //[self attachListener:kAudioDevicePropertyVolumeScalar];
    }

    [self updateStatusItem];
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
    OSStatus err3 = AudioDeviceAddPropertyListener(defaultDevice,
                                                   channel,
                                                   0,
                                                   adProp,
                                                   (AudioDevicePropertyListenerProc)AHPropertyListenerProcLegacy,
                                                   self);
    
    if (err != noErr || err3 != noErr) NSLog(@"ERROR: Trying to attach listener '%@'",osTypeToFourCharCode(adProp));
    else DEBUG_OUTPUT1(@"Listener Attached '%@'",osTypeToFourCharCode(adProp));
    
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
	
    OSStatus err2 = AudioDeviceRemovePropertyListener(defaultDevice,channel,0,adProp,(AudioDevicePropertyListenerProc)AHPropertyListenerProcLegacy);
	
    if (err != noErr || err2 != noErr) NSLog(@"ERROR: Trying to remove listener '%@'",osTypeToFourCharCode(adProp));
    else DEBUG_OUTPUT1(@"Listener Removed '%@'",osTypeToFourCharCode(adProp));
}


#pragma mark AD Prop Fetches
- (BOOL)jackConnected
{
    return jackConnectedLegacy();
}

// returns true if jack is connected. false otherwise
bool jackConnectedLegacy(void)
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
/*
Float32 systemVolumeLevelLegacy(AudioDeviceID inDevice)
{
    // Getting the volume | this solves the problem coming out of mute, or when the user does some freaky stuff with the mute button
    Float32 volLevel = 0;
    UInt32 volLevelSize = sizeof volLevel;
    OSStatus err = AudioDeviceGetProperty(inDevice,1,0,kAudioDevicePropertyVolumeScalar,&volLevelSize,&volLevel);
    if (err != noErr) DEBUG_OUTPUT(@"ERROR: Volume property fetch bad");
	DEBUG_OUTPUT1(@"Volume Level: %f",volLevel);
    return volLevel;
}
*/

bool muteStatusLegacy(AudioDeviceID inDevice)
{
    // Getting the mute button status 
    UInt32 muteOn = 0;
    UInt32 muteOnSize = sizeof muteOn;
    OSStatus err = AudioDeviceGetProperty(inDevice, (int)multichanMute, 0, kAudioDevicePropertyMute, &muteOnSize, &muteOn);
    if (err != noErr) NSLog(@"ERROR: Mute property fetch bad");
    DEBUG_OUTPUT1(@"Mute On: %i", (int)muteOn);
    return muteOn;
}

#pragma mark-
// Fn run when proc'ed by the listener
static OSStatus AHPropertyListenerProcLegacy(AudioDeviceID           inDevice,
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
    
    bool muteOn = muteStatusLegacy(inDevice); // true if mute is on
    bool jConnect = jackConnectedLegacy(); // true if headphones in jack
    
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
