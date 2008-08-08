/*
 * DebugUtils.h
 * Breakaway
 * Created by Kevin Nygaard on 7/6/08.
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

#import "AIAppleScriptPluginController.h"
#import "AIAppleScriptPlugin.h"

@implementation AIAppleScriptPluginController

#pragma mark Required Plugin Info

- (NSString*)pluginTypeName
{
	return @"AppleScript Trigger";
}

- (bool)isInstantiable 
{
	return TRUE;
}

- (NSView*)preferenceView
{
	if(!preferences)
	{ 
		//Load our view 
		[NSBundle loadNibNamed:@"AppleScriptPlugin.nib" owner:self]; 
	}
	// link up your NSView in IB and return that outlet here. Breakaway handles loading your plugin nib for you
	return preferences;
}

-(NSArrayController*)arrayController
{
	return arrayController; 
}

#pragma mark 

/*
 this gets called when the plugin is first instantiated (loaded). This is our controller that is getting loaded
 */
- (id)init
{
	if (!(self = [super init])) return nil;
	
	// if our array hasn't been made yet (which it shouldn't have been), make it and fill it up
	if (!instancesArray)
	{
		instancesArray = [[NSMutableArray alloc]init];
		
		int i;
		NSMutableArray* tmpArray = [[NSUserDefaults standardUserDefaults]objectForKey:@"AIAppleScriptTriggers"];
		for (i=0;[tmpArray count]>i;i++)
		{
			if ([[tmpArray objectAtIndex:i]count] >= 8)
				[instancesArray addObject:[[AIAppleScriptPlugin alloc]initFromDictionary:[tmpArray objectAtIndex:i]]];
			else NSLog(@"Not enough attributes to make an AITrigger (%@). Not adding to instancesArray.",[[tmpArray objectAtIndex:i]description]);
		}
	}
	return self;
	
}


/*
 this fn is called when we load our nib, so this hooks in all our stuff for saving
 make sure you set the application's delegate to your file owner, or this won't be called at the right time
 */
-(void)awakeFromNib
{
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.enabled" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.name" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.nmode" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.hpmode" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.mute" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.unmute" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.hin" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.hout" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.script" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.lod" options:nil context:nil];
	
	[arrayController setContent: instancesArray];
}

// this fn is whats the observers call from above during a change
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// if something is selected, save
	if ([[arrayController selectedObjects]count] != 0)
	{
		[self exportToArray];
		if ([keyPath isEqualToString:@"arrangedObjects.script"]) NSLog(@"We changed");
	}
}

- (IBAction)modeCheck:(id)sender
{
	if ([[arrayController selectedObjects] count] && [[[arrayController selectedObjects]objectAtIndex:0] modeSelected])
	{
		[muteButton setEnabled:TRUE];
		[unmuteButton setEnabled:TRUE];
	}
	else
	{
		[muteButton setEnabled:FALSE];
		[unmuteButton setEnabled:FALSE];
	}
}

- (void)exportToArray
{
	int i;
	id instance;
	NSMutableArray* returnArray = [NSMutableArray array];
	
	for (i=0;[instancesArray count]>i;i++)
	{
		instance = [instancesArray objectAtIndex:i];
		[returnArray addObject:[instance export]];
	}
	
	NSArray* trueArray = [NSArray arrayWithArray:returnArray];
	
	[[NSUserDefaults standardUserDefaults]setObject:trueArray forKey:@"AIAppleScriptTriggers"];
	[[NSUserDefaults standardUserDefaults]synchronize];
}
@end
