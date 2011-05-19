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
#import "AIToolbarItem.h"

@implementation PreferencesController

#pragma mark -

- (id)init
{
	if (!(self = [super init])) return nil;
    [NSBundle loadNibNamed:@"Preferences" owner:self];
	return self;
}

- (void)awakeFromNib
{	
    [[defaultToolbarItemSelection toolbar] setSelectedItemIdentifier:[defaultToolbarItemSelection itemIdentifier]];
    [self toggleActivePreferenceView: defaultToolbarItemSelection];
}

- (IBAction)showWindow:(id)sender 
{
	if (![[self window] isVisible]) [[self window] center];
	
	[super showWindow:sender];
	[[self window] makeKeyAndOrderFront:self];
}

#pragma mark View Manipulation
- (void)toggleActivePreferenceView:(id)sender
{
	if (![sender isKindOfClass:[AIToolbarItem class]]) return;
    
    [self setActiveView:[sender preferenceView] animate:YES];
    [[self window] setTitle:[sender label]];
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

