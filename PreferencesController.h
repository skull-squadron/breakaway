/*
 * PreferencesController.h
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

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController
{
	NSString *GeneralToolbarItemIdentifier	;
	NSString *AdvancedToolbarItemIdentifier;
	NSString *PluginsToolbarItemIdentifier;
	NSString *AboutToolbarItemIdentifier  	;
	NSString *QuitToolbarItemIdentifier    ;
	NSString *ExpandBreakawayToolbarItemIdentifier    ;
	NSString *DonateToolbarItemIdentifier    ;
	
    IBOutlet id activeContentView;
    IBOutlet id advancedPreferenceView;
    IBOutlet id chatStatusRollout;
    IBOutlet id generalPreferenceView;
    IBOutlet id pluginsPreferenceView;
	IBOutlet id donatePreferenceView;
	IBOutlet id expandBreakawayPreferenceView;
	
	IBOutlet id preferenceHandler;
	IBOutlet id pluginPreferenceDrawer;
	
	bool loadedNib;
}

+ (PreferencesController *)sharedPreferencesController;

- (void)toggleActivePreferenceView:(id)sender;
- (void)setActiveView:(NSView *)view animate:(BOOL)flag;
- (id)preferenceHandler;
- (BOOL)loadedNib;
@end
