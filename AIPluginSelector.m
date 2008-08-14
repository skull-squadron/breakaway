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
#import "AIPluginControllerProtocol.h"
#import "AIPluginProtocol.h"

static AIPluginSelector *pluginController = nil;

@implementation AIPluginSelector

-(void)awakeFromNib
{
	pluginController = self;
	// Setting up these for plugin stuff
	pluginInstances = [[NSMutableArray alloc] init];
		
	// load all our bundles, init them, and put them in pluginInstances
	[self loadAllBundles];
	
	[pluginSelectorController setContent:pluginInstances];
	
	[self setDelegate:self];	
}

+ (AIPluginSelector*)pluginController
{
	return pluginController;
}

#pragma mark 
#pragma mark Plugin Loading

- (void)loadAllBundles
{                                        
    NSMutableArray *bundlePaths;
	NSDictionary *infoDictionary;
    NSEnumerator *pathEnum;
    NSString *currPath;
    NSBundle *currBundle;
    Class currPrincipalClass;
    id currInstance;
	
    bundlePaths = [NSMutableArray array];
	
    [bundlePaths addObjectsFromArray:[self allBundles]];               
	
    pathEnum = [bundlePaths objectEnumerator];
    while(currPath = [pathEnum nextObject])
    {
        currBundle = [NSBundle bundleWithPath:currPath];               
        if(currBundle)
        {
            currPrincipalClass = [currBundle principalClass];
			infoDictionary = [currBundle infoDictionary];
            if(currPrincipalClass && [currPrincipalClass conformsToProtocol:@protocol(AIPluginControllerProtocol)])
            {
                currInstance = [[currPrincipalClass alloc] init]; 
                if(currInstance)
                {
                    [pluginInstances addObject:[currInstance autorelease]];
                }
            }
        }
    }
}

- (NSMutableArray *)allBundles
{
    NSArray *librarySearchPaths;
    NSEnumerator *searchPathEnum;
    NSString *currPath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];
	
    librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
	
    searchPathEnum = [librarySearchPaths objectEnumerator];
	while(currPath = [searchPathEnum nextObject])
    {
        [bundleSearchPaths addObject:
		 [currPath stringByAppendingPathComponent:@"Application Support/Breakaway/PlugIn"]];
    }
    [bundleSearchPaths addObject:
	 [[NSBundle mainBundle] builtInPlugInsPath]];
	
    searchPathEnum = [bundleSearchPaths objectEnumerator];
    while(currPath = [searchPathEnum nextObject])
    {
        NSDirectoryEnumerator *bundleEnum;
        NSString *currBundlePath;
        bundleEnum = [[NSFileManager defaultManager]
					  enumeratorAtPath:currPath];
        if(bundleEnum)
        {
            while(currBundlePath = [bundleEnum nextObject])
            {
                if([[currBundlePath pathExtension] isEqualToString:@"plugin"])
                {
					[allBundles addObject:[currPath stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }
	
    return allBundles;
}

#pragma mark 
#pragma mark Plugin Management
- (void)executeTriggers:(int)prototype
{	
	NSEnumerator* listEnum = [pluginInstances objectEnumerator];
	id plugin;
	while ((plugin = [listEnum nextObject]))
	{
		id pluginInstance;
		NSEnumerator* instanceEnum = [[[plugin arrayController]content] objectEnumerator];
		while ((pluginInstance = [instanceEnum nextObject])) 
			if (([pluginInstance familyCode] & prototype) == prototype) [pluginInstance activate:prototype];
	}
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
