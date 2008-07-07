/*
 * PreferenceHandler.h
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
#import "AIPluginInterface.h"

NSString* osTypeToFourCharCode(OSType inType);
@interface PreferenceHandler : NSObject
{
	int done;
	IBOutlet id triggerArrayController;
	IBOutlet id drawer;
	IBOutlet id scriptField;
	IBOutlet id triggerTable;
	IBOutlet id mute;
	IBOutlet id unmute;
	IBOutlet id fadeInSlider;
	
	IBOutlet id log;

	NSMutableArray* triggersArray;
	
	// Plugin stuff
	NSMutableArray* pluginClasses;			//	an array of all plug-in classes
	NSMutableArray* pluginInstances;		//	an array of all plug-in instances
}
- (id)scriptField;
- (id)triggerArrayController;
- (NSMutableArray*)triggersArray;

- (void)executeTriggers:(int)prototype;
- (void)loadTriggers;
- (void)exportToArray;

- (IBAction)donate:(id)sender;
- (IBAction)showInMenuBar:(id)sender;
- (IBAction)muteKeyEnable:(id)sender;
- (IBAction)showInDock:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)updateCheck:(id)sender;
- (IBAction)modeCheck:(id)sender;
- (IBAction)testFadeIn:(id)sender;

- (IBAction)sendResults:(id)sender;
- (IBAction)startTest:(id)sender;

- (IBAction)forceSave:(id)sender;

- (IBAction)locateScript:(id)sender;
- (IBAction)revealScript:(id)sender;
- (IBAction)openScript:(id)sender;

#pragma mark 
#pragma mark Plugin Stuff
- (void)activatePlugin:(NSString*)path;
- (void)instantiatePlugins:(Class)pluginClass;
@end
