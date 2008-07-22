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
	if ([self selectedRow] != -1)
	{
		id plugin = [[pluginSelectorController selectedObjects]objectAtIndex:0];
		[[parentController drawer] setContentView:[plugin preferenceView]];
		[pluginContentController setObjectClass:[plugin class]];
		[[pluginContentTable tableColumnWithIdentifier:@"enabled"] bind:@"value"
															   toObject:[plugin arrayController]
															withKeyPath:@"arrangedObjects.enabled"
																options:nil];
		
		[[pluginContentTable tableColumnWithIdentifier:@"name"] bind:@"value"
															toObject:[plugin arrayController]
														 withKeyPath:@"arrangedObjects.name"
															 options:nil];
		
	}
	else
	{
		[pluginContentController setContent:nil];
		[[pluginContentTable tableColumnWithIdentifier:@"enabled"] unbind:@"value"];
		
		[[pluginContentTable tableColumnWithIdentifier:@"name"] unbind:@"value"];
		[[parentController drawer] setContentView:optionsDrawerView];
	}
}


@end
