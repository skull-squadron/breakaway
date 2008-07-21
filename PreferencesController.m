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

#import "PreferenceHandler.h"

#define WINDOW_TITLE_HEIGHT 78

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
	AdvancedToolbarItemIdentifier				= NSLocalizedString(@"Advanced",nil);
	TriggersToolbarItemIdentifier				= NSLocalizedString(@"Triggers",nil);
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
	[triggerDrawer setContentSize:content]; 
}

- (IBAction)showWindow:(id)sender 
{
	if (![[self window] isVisible]) [[self window] center];
	
	[triggerDrawer close:nil];
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
		TriggersToolbarItemIdentifier,
		AdvancedToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		ExpandBreakawayToolbarItemIdentifier,
		AboutToolbarItemIdentifier,
		QuitToolbarItemIdentifier,
		nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar 
{
	return [NSArray arrayWithObjects:
		GeneralToolbarItemIdentifier,
		TriggersToolbarItemIdentifier,
		AdvancedToolbarItemIdentifier,
		AboutToolbarItemIdentifier,
		ExpandBreakawayToolbarItemIdentifier,
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
		TriggersToolbarItemIdentifier,
		AdvancedToolbarItemIdentifier,
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
	else if ([identifier isEqualToString:TriggersToolbarItemIdentifier])
	{
		[item setLabel:TriggersToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"flag"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	}
	else if ([identifier isEqualToString:AdvancedToolbarItemIdentifier])
	{
		[item setLabel:AdvancedToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"Terminal"]];
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
	else if ([[sender itemIdentifier] isEqualToString:TriggersToolbarItemIdentifier])
		view = triggersPreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:AdvancedToolbarItemIdentifier])
		view = advancedPreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:ExpandBreakawayToolbarItemIdentifier])
		view = expandBreakawayPreferenceView;
	
	if (view != triggersPreferenceView) [triggerDrawer close:self];
	
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

