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
	
    [self tableViewSelectionDidChange:nil];
    
	[self setDelegate:self];
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
        id plugin = [[pluginSelectorController selectedObjects] objectAtIndex:0];

        // set the plugin's preferences in the drawer (loading the nib)
        // note, that once this code is called (the nib is loaded), NSApp delegate gets _changed_ to the plugin instance loading the nib
        // i have no idea why this happens, but it does. to solve this, we will use a different way to access appcontroller
        if ([[pluginView subviews] count] != 0)
            [[[pluginView subviews] objectAtIndex:0] removeFromSuperview];

        [pluginView addSubview:[plugin prefView]];
    }
    else
    {
        if ([[pluginView subviews] count] != 0)
            [[[pluginView subviews] objectAtIndex:0] removeFromSuperview];
        [pluginView addSubview:defaultPluginView];

    }
}

@end
