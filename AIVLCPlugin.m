/*
 * AIVLCPlugin.m
 * Breakaway
 * Created by Kevin Nygaard on 7/22/08.
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

#import "AIVLCPlugin.h"
#import <ApplicationServices/ApplicationServices.h>


@implementation AIVLCPlugin
#pragma mark Some Required Plugin Info

- (NSString*)pluginTypeName
{
	return @"VLC Plugin";
}

/*
 - (void)setName:(NSString*)var
{
}
 */

- (NSString*)name
{
	return @"VLC Plugin";
}

- (BOOL)isInstantiable 
{
	return FALSE;
}

-(BOOL)enabled
{
	enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AIVLCPluginEnable"];
	return enabled;
}

- (int)familyCode
{
	return 127;
}

- (NSArrayController*)arrayController
{
	return arrayController;
}

-(void)setEnabled:(bool)var
{
	enabled = var;
	[[NSUserDefaults standardUserDefaults]setBool:enabled forKey:@"AIVLCPluginEnable"];
	[[NSUserDefaults standardUserDefaults]synchronize];
}

- (NSView*)preferenceView
{
	if(!preferences)
	{ 
		//Load our view 
		[NSBundle loadNibNamed:@"VLCPlugin.nib" owner:self]; 
	}
	// link up your NSView in IB and return that outlet here. Breakaway handles loading your plugin nib for you
	return preferences;
}

#pragma mark 
-(id)init
{
	if (!(self = [super init])) return nil;
	
	// if our array, hasn't been made yet, make it and fill it up
	if (!instancesArray)
	{
		instancesArray = [[NSMutableArray alloc]init];
		arrayController = [[NSArrayController alloc]init];
		[instancesArray addObject:self];
		[self setEnabled:[[NSUserDefaults standardUserDefaults] boolForKey:@"AIVLCPluginEnable"]];
		[arrayController setContent: instancesArray];
	}
	return self;
}

- (void)activate:(int)prototype
{	
	if (enabled)
	{		
		///////////////// grab our original sound
		NSAppleEventDescriptor* finder = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplicationBundleID
														data:[@"com.Apple.Finder" dataUsingEncoding:NSUTF8StringEncoding]];
		
		
		NSAppleEventDescriptor* ae = [NSAppleEventDescriptor appleEventWithEventClass:'syso' 
												 eventID:'gtvl' 
										targetDescriptor:finder
												returnID:kAutoGenerateReturnID 
										   transactionID:kAnyTransactionID];
		NSAppleEventDescriptor* reply = [NSAppleEventDescriptor nullDescriptor];
		// ignore this warning; we got it right
		AESendMessage([ae aeDesc], [reply aeDesc], kAEWaitReply | kAECanInteract, kAEDefaultTimeout);
		int origVolume = [[[reply descriptorAtIndex:1]descriptorAtIndex:1]int32Value];
		
		///////////////// kill sound
		NSAppleEventDescriptor* muter = [NSAppleEventDescriptor appleEventWithEventClass:'aevt' 
																				 eventID:'stvl' 
																		targetDescriptor:finder
																				returnID:kAutoGenerateReturnID 
																		   transactionID:kAnyTransactionID];
		
		[muter setParamDescriptor:[NSAppleEventDescriptor descriptorWithInt32:origVolume?0:1] forKeyword:'ouvl'];
		AESendMessage([muter aeDesc], NULL, kAENoReply | kAENeverInteract, kAEDefaultTimeout);
		
		///////////////// do our freakin long logic
		if ([self isPlaying])
		{
			// mute/hout
			if(((prototype & 79)==prototype)) { [self pauseMusic]; appHit = 1;}
		}
		// unmute/hin
		else if(((prototype & 55)==prototype) && appHit) { [self pauseMusic]; appHit = 0;}
		
		///////////////// put volume back the way it was
		
		[muter setParamDescriptor:[NSAppleEventDescriptor descriptorWithInt32:origVolume] forKeyword:'ouvl'];
		AESendMessage([muter aeDesc], NULL, kAENoReply | kAENeverInteract, kAEDefaultTimeout);
	}
}

-(void)playMusic
{
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/curl" arguments:[NSArray arrayWithObjects:@"http://localhost:8080/requests/status.xml?command=pl_play", nil]];
}

-(void)pauseMusic
{
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/curl" arguments:[NSArray arrayWithObjects:@"http://localhost:8080/requests/status.xml?command=pl_pause", nil]];
}

-(BOOL)isPlaying
{
	NSTask *statusTask = [[NSTask alloc]init];
	
	NSString *tmp = [[NSBundle bundleForClass:@"AIVLCPlugin"]bundlePath];
	[statusTask setLaunchPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"vlcPlaying" ofType:nil]];
	[statusTask launch];
	[statusTask waitUntilExit];
	int status = [statusTask terminationStatus];
	return status;
}

@end
