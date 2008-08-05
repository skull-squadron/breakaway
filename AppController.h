/*
 * AppController.h
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
#import <CoreAudio/CoreAudio.h>

// our proc method; this is the main workhorse of the app
inline OSStatus AHPropertyListenerProc(AudioDeviceID           inDevice,
									   UInt32                  inChannel,
									   Boolean                 isInput,
									   AudioDevicePropertyID   inPropertyID,
									   void*                   inClientData);

@interface AppController : NSObject
{
	// Our scripts for controlling iTunes
	NSAppleScript *stopstart;
	NSAppleScript *playerState;
	NSAppleScript *fadeIn;
	BOOL isPlaying;
	BOOL isActive;
	BOOL isCompiled;
	
	
	// NSStatusItem stuff
	NSStatusItem *statusItem;
	NSImage *conn;
	NSImage *disconn;
	NSImage *disabled;
	IBOutlet id statusItemMenu;
	IBOutlet id disableMI;
	
	
	// Preferenes (in actual order)
	IBOutlet id prefsWindow; // the NSWindow in which the preferences reside
	
	// Splash
	IBOutlet id splash; // the NSView which our splash looks like
	NSWindow *splashWind; // what holds the NSView mentioned above
	IBOutlet id progressWheel;
	IBOutlet id versionString;
	
	// Other Objects
	IBOutlet id growlNotifier;
	IBOutlet id sparkleController;
	NSUserDefaults* userDefaults;
	NSDate *then;
}
+ (AppController*)appController;
- (id)sparkle;
- (void)awakeFromNib;
- (void)loadListeners;
- (void)loadiTunesObservers;
- (void)disable;
- (void)executeFadeIn;
- (void)recompileFadeIn;

#pragma mark-
#pragma mark Splash
- (void)startSplash;
- (void)stopSplash;

#pragma mark 
#pragma mark Menu Extra
- (void)setupStatusItem;
- (void)killStatusItem;

#pragma mark 
#pragma mark IB Button Actions
- (IBAction)muteKeyEnableAct:(id)sender;
- (IBAction)showInMenuBarAct:(id)sender;
- (IBAction)openPrefs:(id)sender;
- (IBAction)sendemail:(id)sender;
- (IBAction)openDonate:(id)sender;

- (void)updateThen;

- (IBAction)openInfo:(id)sender;
- (IBAction)openUpdater:(id)sender;

#pragma mark
#pragma mark Accessor Functions
- (NSDate *)then;
- (IBAction)disable:(id)sender;
- (void)growlNotify:(NSString *)title andDescription:(NSString *)description;

#pragma mark 
#pragma mark Queries
-(BOOL)iTunesActive;
-(BOOL)iTunesPlaying;
- (void) handleAppLaunch:(NSNotification *)notification;
- (void) handleAppQuit:(NSNotification *)notification;
	
#pragma mark 
#pragma mark Script Manipulation
- (void)compileScript;
- (void)executeScript;

#pragma mark 
#pragma mark CoreAudio Queries
- (void)attachListener:(AudioDevicePropertyID)adProp;
- (void)removeListener:(AudioDevicePropertyID)adProp;
- (BOOL)jackConnected;
- (BOOL)audioFlowing;

#pragma mark 
#pragma mark Delegate Fns
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag;
- (void)songChanged:(NSNotification *)aNotification;
@end
