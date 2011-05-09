/*
 * AIPluginSelector.m
 * Breakaway
 * Created by Kevin Nygaard on 7/21/08.
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

#import "AIPluginSelector.h"

#import <Growl/Growl.h>

#import "SharedBreakaway.h"
#import "AppController.h"
#import "AIPluginProtocol.h"
#import "GrowlNotifier.h"
#import "AIPluginController.h"

static AIPluginSelector *pluginController = nil;

@implementation AIPluginSelector

/******************************************************************************
 * init
 *
 * Sets up environment variables
 *****************************************************************************/
- (id)init
{
	if (!(self = [super init])) return nil;

	pluginController = self;

    return self;
}

/******************************************************************************
 * awakeFromNib
 *
 * Initializes object
 * Sets up plugins
 *****************************************************************************/
- (void)awakeFromNib
{
	// load all our bundles, init them, and put them in pluginInstances
	//[self loadAllBundles];
	
	[pluginSelectorController setContent:breakaway.pluginController.pluginInstances];
	
	//[self setDelegate:self];	
}

/******************************************************************************
 * openPluginFolder:
 *
 * Opens the builtInPlugin directory in Finder
 *****************************************************************************/
- (IBAction)openPluginFolder:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:[[NSBundle mainBundle] builtInPlugInsPath] inFileViewerRootedAtPath:@""];
}

#pragma mark Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	// make sure we have something selected
	if ([self selectedRow] != -1)
	{
		// figure out which plugin instances to display
		id plugin = [[pluginSelectorController selectedObjects]objectAtIndex:0];
		
		// set the plugin's preferences in the drawer (loading the nib)
		// note, that once this code is called (the nib is loaded), NSApp delegate gets _changed_ to the plugin instance loading the nib
		// i have no idea why this happens, but it does. to solve this, we will use a different way to access appcontroller
		[drawer setContentView:[plugin preferenceView]];
		
		// remove our bindings (thus displaying nothing anymore)
		[[pluginContentTable tableColumnWithIdentifier:@"enabled"] unbind:@"value"];
		[[pluginContentTable tableColumnWithIdentifier:@"name"] unbind:@"value"];

		// hook in the content table to display the plugin's instances
		[[pluginContentTable tableColumnWithIdentifier:@"enabled"] bind:@"value"
															   toObject:[plugin arrayController]
															withKeyPath:@"arrangedObjects.enabled"
																options:nil];
		
		[[pluginContentTable tableColumnWithIdentifier:@"name"] bind:@"value"
															toObject:[plugin arrayController]
														 withKeyPath:@"arrangedObjects.name"
															 options:nil];
		
		// hook in our buttons to make/remove instances
		if ([plugin isInstantiable])
		{
			[addButton setTarget:[plugin arrayController]];
			[addButton setAction:@selector(add:)];
			
			[removeButton setTarget:[plugin arrayController]];
			[removeButton setAction:@selector(remove:)];
			
			[addButton setEnabled:TRUE];
			[removeButton setEnabled:TRUE];
		}
		else
		{
			[addButton setTarget:nil];
			[addButton setAction:NULL];
			
			[removeButton setTarget:nil];
			[removeButton setAction:NULL];
			
			[addButton setEnabled:FALSE];
			[removeButton setEnabled:FALSE];
		}
		[pluginContentTable reloadData];
	}
	else
	{
		// remove our bindings (thus displaying nothing anymore)
		[[pluginContentTable tableColumnWithIdentifier:@"enabled"] unbind:@"value"];
		[[pluginContentTable tableColumnWithIdentifier:@"name"] unbind:@"value"];
		
		// remove button actions
		[addButton setTarget:nil];
		[addButton setAction:NULL];
		
		[removeButton setTarget:nil];
		[removeButton setAction:NULL];
		
		[addButton setEnabled:FALSE];
		[removeButton setEnabled:FALSE];
		
		// set preferences back to the default (none)
		[drawer setContentView:optionsDrawerView];
		[pluginContentTable reloadData];
	}
}


@end
