//
//  AIPluginSelector.h
//  Breakaway
//
//  Created by Kevin Nygaard on 7/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIPluginSelector : NSTableView
{
	IBOutlet id pluginSelectorController;
	IBOutlet id pluginContentTable;
	
	IBOutlet id drawer;
	IBOutlet id optionsDrawerView;
	
	IBOutlet id addButton;
	IBOutlet id removeButton;
	
	// Plugins
	NSMutableArray* pluginInstances;		//	an array of all plug-in instances
}

// Plugin
- (void)loadAllBundles;
- (NSMutableArray *)allBundles;

- (void)executeTriggers:(int)prototype;

+ (AIPluginSelector *)pluginController;

@end
