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
	IBOutlet id parentController;
	IBOutlet id pluginSelectorController;
	IBOutlet id pluginContentTable;
	IBOutlet id optionsDrawerView;
	
	IBOutlet id addButton;
	IBOutlet id removeButton;
}

@end
