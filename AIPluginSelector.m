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
		[pluginContentController setContent:[plugin instancesArray]];
		[plugin observeValues:pluginContentController using:self];
	}
	else [[parentController drawer] setContentView:optionsDrawerView];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[[[pluginSelectorController selectedObjects]objectAtIndex:0] save];
}

@end
