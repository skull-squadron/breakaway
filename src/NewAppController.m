/*
 * NewAppController.m
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

#import "NewAppController.h"
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

@implementation NewAppController

static BOOL newAPIRegistered = NO;
static BOOL newAPIJackConnected = NO;


- (void)registerNewAPI
{
    if (newAPIRegistered) {
        DEBUG_OUTPUT(@"registerNewAPI: already registered");
        return;
    }
    DEBUG_OUTPUT(@"registerNewAPI: registering...");
    AudioDeviceID defaultDevice = 0;
    UInt32 defaultSize = sizeof(AudioDeviceID);

    const AudioObjectPropertyAddress defaultAddr = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    AudioObjectGetPropertyData(kAudioObjectSystemObject, &defaultAddr, 0, NULL, &defaultSize, &defaultDevice);

    AudioObjectPropertyAddress sourceAddr;
    sourceAddr.mSelector = kAudioDevicePropertyDataSource;
    sourceAddr.mScope = kAudioDevicePropertyScopeOutput;
    sourceAddr.mElement = kAudioObjectPropertyElementMaster;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    AudioObjectAddPropertyListenerBlock(defaultDevice,
                                        &sourceAddr,
                                        queue, ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses) {
        DEBUG_OUTPUT(@"jack state listener: changed");
        if (breakaway.enabled) {
            DEBUG_OUTPUT(@"jack state listener: api enabled");
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
            UInt32 bDataSourceId = 0;
            UInt32 bDataSourceIdSize = sizeof(UInt32);
            AudioObjectGetPropertyData(defaultDevice, inAddresses, 0, NULL, &bDataSourceIdSize, &bDataSourceId);
            
            UInt32 muteOn;
            muteStatusNew(defaultDevice, &muteOn);
            kTriggerMask triggerMask = 0;
        
            if (bDataSourceId == 'ispk') {
                DEBUG_OUTPUT1(@"New API: Headphones removed",nil);
                newAPIJackConnected = NO;
                
                [self updateStatusItem];
                
                // send data to plugins
                triggerMask |= (muteOn) ? kTriggerMute : 0;
                triggerMask |= kTriggerJackStatus;
                [[self pluginController] executeTriggers:triggerMask];
            } else if (bDataSourceId == 'hdpn') {
                DEBUG_OUTPUT1(@"New API: Headphones connected",nil);
                newAPIJackConnected = YES;
                
                [self updateStatusItem];
                
                // send data to plugins
                triggerMask |= (muteOn) ? kTriggerMute : 0;
                triggerMask |= kTriggerJackStatus;
                [[self pluginController] executeTriggers:triggerMask];
            }
            [pool release];
        } else {
            DEBUG_OUTPUT(@"jack state listener: api NOT enabled");
        }

    });
    newAPIRegistered = YES;
    DEBUG_OUTPUT(@"registerNewAPI: registered");
}


- (void)setEnabled:(BOOL)enable
{	
    [self.userDefaults setBool:enable forKey:@"enableBreakaway"];
    if (enable) {
        DEBUG_OUTPUT(@"Enabling (new) ...");
        [self attachListener:kAudioDevicePropertyDataSource];
        [self attachListener:kAudioDevicePropertyMute];
        [self registerNewAPI];
        //[self attachListener:kAudioDevicePropertyVolumeScalar];
    } else {
        DEBUG_OUTPUT(@"Disabling (new) ...");
        [self removeListener:kAudioDevicePropertyDataSource];
        [self removeListener:kAudioDevicePropertyMute];
        //[self removeListener:kAudioDevicePropertyVolumeScalar];
    }
    [self updateStatusItem];
}

#pragma mark 
#pragma mark CoreAudio Queries
- (void)attachListener:(AudioDevicePropertyID)adProp
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    AudioDeviceID defaultDevice;
    UInt32 audioDeviceSize = sizeof(defaultDevice);
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &audioDeviceSize,
                                            &defaultDevice);
    
    int channel = 0;
    
    if (adProp == kAudioDevicePropertyVolumeScalar) {
        channel = 1;
    } else if (adProp == kAudioDevicePropertyMute) {
        UInt32 muteOn;
        OSStatus err2 = AudioDeviceGetProperty(defaultDevice,
                                               1,
                                               0,
                                               kAudioDevicePropertyMute,
                                               &audioDeviceSize,
                                               &muteOn);
        
        // If we get a return on channel 1 for mute status, it has channels. If we get an error, we will use channel 0
        if (err2 == noErr) {
            DEBUG_OUTPUT(@"Mute is multichanneled");
            multichanMute = TRUE;
            channel = 1;
        } else {
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
                                                   (AudioDevicePropertyListenerProc)AHPropertyListenerProcNew,
                                                   self);
    
    if (err != noErr || err3 != noErr) {
        NSLog(@"ERROR: Trying to attach listener '%@'", osTypeToFourCharCode(adProp));
    } else {
        DEBUG_OUTPUT1(@"Listener Attached '%@'", osTypeToFourCharCode(adProp));
    }
    
    [pool release];
}

- (void)removeListener:(AudioDevicePropertyID)adProp
{
    AudioDeviceID defaultDevice;
    UInt32 audioDeviceSize = sizeof(defaultDevice);
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &audioDeviceSize,
                                            &defaultDevice);
    
    // If we have a multichannel mute and we are trying to take it off, make sure we take it off the right channel
    int channel = ((adProp == kAudioDevicePropertyMute && multichanMute) ||
                   (adProp == kAudioDevicePropertyVolumeScalar))
                  ? 1
                  : 0;

	
    OSStatus err2 = AudioDeviceRemovePropertyListener(defaultDevice,
                                                      channel,
                                                      0,
                                                      adProp,
                                                      (AudioDevicePropertyListenerProc)AHPropertyListenerProcNew);
	
    if (err != noErr || err2 != noErr) {
      NSLog(@"ERROR: Trying to remove listener '%@'", osTypeToFourCharCode(adProp));
    } else {
      DEBUG_OUTPUT1(@"Listener Removed '%@'", osTypeToFourCharCode(adProp));
    }
}



#pragma mark AD Prop Fetches
- (BOOL)jackConnected
{
    return jackConnectedNew();
}

// returns true if jack is connected. false otherwise
bool jackConnectedNew(void)
{
    AudioDeviceID defaultDevice;
    UInt32 audioDeviceSize = sizeof(defaultDevice);
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &audioDeviceSize,
                                            &defaultDevice);
    if (err != noErr) {
        DEBUG_OUTPUT(@"ERROR: Legacy jackConnected AudioHardwareGetProperty");
        return false;
    }
	
	UInt32 dataSource;
	UInt32 dataSourceSize = sizeof(dataSource);
	err = AudioDeviceGetProperty(defaultDevice,
                                 0,
                                 0,
                                 kAudioDevicePropertyDataSource,
                                 &dataSourceSize,
                                 &dataSource);
    if (err != noErr) {
        DEBUG_OUTPUT(@"ERROR: Legacy jackConnected AudioDeviceGetProperty");
        return false;
    }

    bool result = (dataSource == 'hdpn');
    DEBUG_OUTPUT1(@"Legacy jackConnected = %d", result);
    return result;
}
/*
Float32
systemVolumeLevel(AudioDeviceID inDevice)
{
    // Getting the volume | this solves the problem coming out of mute, or when the user does some freaky stuff with the mute button
    Float32 volLevel = 0.0;
    UInt32 volLevelSize = sizeof(volLevel);
    OSStatus err = AudioDeviceGetProperty(inDevice,
                                          1,
                                          0,
                                          kAudioDevicePropertyVolumeScalar,
                                          &volLevelSize,
                                          &volLevel);
    if (err != noErr) {
        DEBUG_OUTPUT(@"ERROR: Volume property fetch bad");
        return volLevel;
    }
	DEBUG_OUTPUT1(@"Volume Level: %f", volLevel);
    return volLevel;
}
*/

bool muteStatusNew(AudioDeviceID inDevice, UInt32 *muteOn)
{
    // Getting the mute button status 
    UInt32 muteOnSize = sizeof(*muteOn);
    OSStatus err = AudioDeviceGetProperty(inDevice,
                                          (int)multichanMute,
                                          0,
                                          kAudioDevicePropertyMute,
                                          &muteOnSize,
                                          muteOn);
    if (err != noErr) {
        DEBUG_OUTPUT(@"ERROR: Mute property fetch bad");
        return muteOn;
    }
    DEBUG_OUTPUT1(@"Mute On: %i", (int)muteOn);
    return muteOn;
}


#pragma mark-
// Fn run when proc'ed by the listener
static OSStatus AHPropertyListenerProcNew(AudioDeviceID        inDevice,
                                       UInt32                  inChannel,
                                       Boolean                 isInput,
                                       AudioDevicePropertyID   inPropertyID,
                                       void*                   inClientData)
{
    // see large comment below
    static bool hpMuteStatusNew = false;
    static bool ispkMuteStatusNew = false;

    if (!breakaway.enabled) { // dont change things if we're not enabled
        DEBUG_OUTPUT(@"other state listener: api NOT enabled");
        return noErr;
    }
    DEBUG_OUTPUT(@"other state listener: api enabled");

    id self = (id)inClientData; // for obj-c calls

    // Create a pool for our Cocoa objects to dump into. Otherwise we get lots of leaks. this thread is running off the main thread, therefore it has no automatic autorelease pool
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    DEBUG_OUTPUT1(@"'%@' Trigger", osTypeToFourCharCode(inPropertyID));
    
    UInt32 muteOn = 0;
    muteStatusNew(inDevice, &muteOn); // true if mute is on
    bool jConnect = jackConnectedNew(); // true if headphones in jack
    
    // save mute data
    // we are changing audio sources. Mute data is old (we get the previous audio source's mute status)
	if (inPropertyID == kAudioDevicePropertyDataSource ||
        inPropertyID == kAudioDevicePropertyDataSources)
    {
        // Store old mute data
        if (jConnect) {
          ispkMuteStatusNew = muteOn;
        } else {
          hpMuteStatusNew = muteOn;
        }
        // Grab correct mute data
		muteOn = (jConnect) ? hpMuteStatusNew : ispkMuteStatusNew;
	} else { // mute triggers are always correct
        // update our status
        if (jConnect) {
          hpMuteStatusNew = muteOn;
        } else {
          ispkMuteStatusNew = muteOn;
        }
	}

    
    // send data to plugins
    kTriggerMask triggerMask = 0;
    
    triggerMask |= (muteOn) ? kTriggerMute : 0;
    triggerMask |= (jConnect) ? kTriggerJackStatus : 0;
    triggerMask |= (inPropertyID != kAudioDevicePropertyMute) ? kTriggerInt : 0;
    [[self pluginController] executeTriggers:triggerMask];

    [self updateStatusItem];
    // TODO: Growl notifications go here
    
    [pool release];
    DEBUG_OUTPUT(@"other state listener: api enabled, updated");
    return noErr;
}

@end
