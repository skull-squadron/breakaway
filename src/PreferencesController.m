/*
 * PreferencesController.m
 * Breakaway
 * Created by Kevin Nygaard on 6/14/06.
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

#import "PreferencesController.h"
#import "defines.h"

static PreferencesController *sharedPreferencesController = nil;

@implementation PreferencesController

+ (PreferencesController *)sharedPreferencesController
{
	if (!sharedPreferencesController) {
		sharedPreferencesController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
	}
	
	// we need to call this now so our triggers will be loaded
	if (![sharedPreferencesController loadedNib])[sharedPreferencesController awakeFromNib];
	return sharedPreferencesController;
}

#pragma mark -
- (void)awakeFromNib
{
	GeneralToolbarItemIdentifier				= NSLocalizedString(@"General",nil);
	PluginsToolbarItemIdentifier				= NSLocalizedString(@"Plugins",nil);
	DonateToolbarItemIdentifier				    = NSLocalizedString(@"Donate",nil);
	AboutToolbarItemIdentifier  				= NSLocalizedString(@"About",nil);
	ExpandBreakawayToolbarItemIdentifier  		= NSLocalizedString(@"Expand",nil);
	QuitToolbarItemIdentifier     				= NSLocalizedString(@"Quit",nil);

	// hide our window when we are done with it. if we didn't put this in, the preferences would be showing when done loading
	[[self window] orderOut:nil];
	loadedNib = TRUE;

	id toolbar = [[[NSToolbar alloc] initWithIdentifier:@"preferences toolbar"] autorelease];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
	[toolbar setSizeMode:NSToolbarSizeModeDefault];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setDelegate:self];

	[toolbar setSelectedItemIdentifier:GeneralToolbarItemIdentifier];
	[[self window] setToolbar:toolbar];
	
	[self setActiveView:generalPreferenceView animate:NO];
	[[self window] setTitle:GeneralToolbarItemIdentifier];
	
	NSSize content;
	content.width = 280;
	content.height = 239;
	[pluginPreferenceDrawer setContentSize:content]; 
}

- (IBAction)showWindow:(id)sender 
{
	if (![[self window] isVisible]) [[self window] center];
	
	[pluginPreferenceDrawer close:nil];
	[super showWindow:sender];
	[[self window]makeKeyAndOrderFront:self];
}

#pragma mark Accessors
-(BOOL)loadedNib
{
	return loadedNib;
}

//{{{
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		GeneralToolbarItemIdentifier,
		PluginsToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		ExpandBreakawayToolbarItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		DonateToolbarItemIdentifier,
		AboutToolbarItemIdentifier,
		QuitToolbarItemIdentifier,
		nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar 
{
	return [NSArray arrayWithObjects:
		GeneralToolbarItemIdentifier,
		PluginsToolbarItemIdentifier,
		AboutToolbarItemIdentifier,
		ExpandBreakawayToolbarItemIdentifier,
		DonateToolbarItemIdentifier,
		QuitToolbarItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
		GeneralToolbarItemIdentifier,
		PluginsToolbarItemIdentifier,
		DonateToolbarItemIdentifier,
		ExpandBreakawayToolbarItemIdentifier,
		/*AboutToolbarItemIdentifier,
		QuitToolbarItemIdentifier,*/
		nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
	
	if ([identifier isEqualToString:GeneralToolbarItemIdentifier])
	{
		[item setLabel:GeneralToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"General Preferences"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	}
	else if ([identifier isEqualToString:PluginsToolbarItemIdentifier])
	{
		[item setLabel:PluginsToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"plugins"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	}
	else if ([identifier isEqualToString:ExpandBreakawayToolbarItemIdentifier])
	{
		[item setLabel:ExpandBreakawayToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"Network Utility"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	} 
	else if ([identifier isEqualToString:DonateToolbarItemIdentifier])
	{
		[item setLabel:DonateToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"Users"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	} 
	else if ([identifier isEqualToString:AboutToolbarItemIdentifier])
	{
		[item setLabel:AboutToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"Get Info"]];
		[item setTarget:[NSApplication sharedApplication]];
		[item setAction:@selector(orderFrontStandardAboutPanel:)];
	} 
	else if ([identifier isEqualToString:QuitToolbarItemIdentifier])
	{
		[item setLabel:QuitToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"Power"]];
		[item setTarget:[NSApplication sharedApplication]];
		[item setAction:@selector(terminate:)];
	} 
	else if (![identifier isEqualToString:NSToolbarSeparatorItemIdentifier] ||
			 ![identifier isEqualToString:NSToolbarSpaceItemIdentifier] ||
			 ![identifier isEqualToString:NSToolbarFlexibleSpaceItemIdentifier])
		item = nil;
	return item; 
}
//}}}

#pragma mark View Manipulation
- (void)toggleActivePreferenceView:(id)sender
{
	NSView *view;
	
	if ([[sender itemIdentifier] isEqualToString:GeneralToolbarItemIdentifier])
		view = generalPreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:PluginsToolbarItemIdentifier])
		view = pluginsPreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:ExpandBreakawayToolbarItemIdentifier])
		view = expandBreakawayPreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:DonateToolbarItemIdentifier])
		view = donatePreferenceView;
	
	if (view != pluginsPreferenceView) [pluginPreferenceDrawer close:self];
	
	[self setActiveView:view animate:YES];
	[[self window] setTitle:[sender itemIdentifier]];
}

- (void)setActiveView:(NSView *)view animate:(BOOL)flag
{
	// set the new frame and animate the change
	NSRect windowFrame = [[self window] frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TITLE_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([[self window] frame]) - ([view frame].size.height + WINDOW_TITLE_HEIGHT);
	
	if ([[activeContentView subviews] count] != 0)
		[[[activeContentView subviews] objectAtIndex:0] removeFromSuperview];
	[[self window] setFrame:windowFrame display:YES animate:flag];
	
	[activeContentView setFrame:[view frame]];
	[activeContentView addSubview:view];
}

#pragma mark Accessors (external)
/* List of other files accessing this function and why
FileAccessorCalledFrom.m - Reason of accessing (-functionCalledUsingAccessor:)

PreferencesController.m (self) - Placed in -toggleActivePreferenceView: to save triggers on view change (-exportToArray)
AppController.m - Placed in the main proc function to execute triggers (-triggersArrayFetching: with:)

 */
- (id)preferenceHandler
{
	return preferenceHandler;
}
@end

