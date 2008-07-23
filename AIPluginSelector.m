//
//  AIPluginSelector.m
//  Breakaway
//
//  Created by Kevin Nygaard on 7/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AIPluginSelector.h"

#import "PreferenceHandler.h"

@implementation AIPluginSelector

-(void)awakeFromNib
{
	[self setDelegate:self];	
}

#pragma mark Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	// make sure we have something selected
	if ([self selectedRow] != -1)
	{
		// figure out which plugin instances to display
		id plugin = [[pluginSelectorController selectedObjects]objectAtIndex:0];
		
		// set the plugin's preferences in the drawer
		[[parentController drawer] setContentView:[plugin preferenceView]];
		
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
		if ([plugin instantiate])
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
		[[parentController drawer] setContentView:optionsDrawerView];
		[pluginContentTable reloadData];
	}
}


@end
