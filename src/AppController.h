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
#import "iTunesBridge.h"

@class iTunesApplication;

// our proc method; this is the main workhorse of the app
inline OSStatus AHPropertyListenerProc(AudioDeviceID           inDevice,
									   UInt32                  inChannel,
									   Boolean                 isInput,
									   AudioDevicePropertyID   inPropertyID,
									   void*                   inClientData);
BOOL isPlaying;
BOOL isActive;
BOOL hpMode;
BOOL enableAppHit;
BOOL appHit;
NSThread *fadeInThread;

@interface AppController : NSObject
{
    iTunesApplication *iTunes;
    	
	// NSStatusItem stuff
	NSStatusItem *statusItem;
	NSImage *conn;
	NSImage *disconn;
	NSImage *disabled;
	IBOutlet id statusItemMenu;
	IBOutlet id disableMI;
	
	
	// Preferenes (in actual order)
	IBOutlet id prefsWindow; // the NSWindow in which the preferences reside
		
	// Other Objects
	IBOutlet id growlNotifier;
	IBOutlet id sparkleController;
	NSUserDefaults* userDefaults;
}

+ (void)initialize;
+ (AppController*)appController;
- (void)dealloc;
- (void)awakeFromNib;

// Startup Functions
- (void)loadListeners;
- (void)loadiTunesObservers;

// Status item
- (void)setupStatusItem;
- (void)killStatusItem;
- (void)disable;

// IB Button Actions
- (IBAction)showInMenuBarAct:(id)sender;
- (IBAction)openPrefs:(id)sender;
- (IBAction)sendEmail:(id)sender;
- (IBAction)openInfo:(id)sender;
- (IBAction)openUpdater:(id)sender;

// Accessor (external)
-(id)sparkle;

// Accessor Functions
- (IBAction)disable:(id)sender;
- (void)growlNotify:(NSString *)title andDescription:(NSString *)description;

// iTunes
- (BOOL)iTunesActive;
- (BOOL)iTunesPlaying;
- (void)iTunesPlayPause;
- (void)iTunesVolumeFadeIn;
- (void)iTunesThreadedFadeIn;

// iTunes launch/quit
- (void)handleAppLaunch:(NSNotification *)notification;
- (void)handleAppQuit:(NSNotification *)notification;

// CoreAudio Queries
- (void)attachListener:(AudioDevicePropertyID)adProp;
- (void)removeListener:(AudioDevicePropertyID)adProp;
- (BOOL)jackConnected;

// Delegate Fns
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
- (void)songChanged:(NSNotification *)aNotification ;
@end
