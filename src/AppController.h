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
#ifndef __APPCONTROLLER_H__
#define __APPCONTROLLER_H__

#import <CoreAudio/CoreAudio.h>
#import "iTunesBridge.h"
#import "VLCBridge.h"

@class AppController,PreferencesController,AIPluginController,GrowlNotifier;

bool multichanMute;

NSThread *fadeInThread;

// From->To
typedef enum {
    kPluggedUnknown = -1,
    kPluggedUnplugged,
    kPluggedDisabled,
    kUnpluggedDisabled
} tImageAnimation;

typedef enum {
    kUnknownImage = -1,
    kPlugged,
    kPU1,
    kPU2,
    kPU3,
    kPU4,
    kPU5,
    kPU6,
    kUnplugged,
    kUD1,
    kUD2,
    kUD3,
    kUD4,
    kUD5,
    kUD6,
    kDisabled,
    kPD1,
    kPD2,
    kPD3,
    kPD4,
    kPD5,
    kPD6
} tImageType;

@interface AppController : NSObject
{
    GrowlNotifier *_growlNotifier;
    PreferencesController *_preferencesController;
    AIPluginController *_pluginController;
    NSUserDefaults* _userDefaults;
    BOOL _inAnimation;
    
    NSEnumerator *_curAnimationEnumerator;
    
    // NSStatusItem stuff
    NSStatusItem *_statusItem;
    NSArray *_images;
    
    
	IBOutlet id statusItemMenu;
	IBOutlet id disableMI;
	
	// Preferenes (in actual order)
	IBOutlet id prefsWindow; // the NSWindow in which the preferences reside
}

@property (nonatomic, readonly) NSArray *images;
@property (nonatomic) BOOL statusItemVisible;
@property (nonatomic, retain, readonly) NSStatusItem *statusItem; // modified by statusItemVisible
@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL inAnimation;
@property (assign, readonly) NSUserDefaults *userDefaults;
@property (assign, readonly) GrowlNotifier *growlNotifier;
@property (assign, readonly) PreferencesController *preferencesController;
@property (assign, readonly) AIPluginController *pluginController;

- (void)animateUsingTimer:(NSTimer*)timer;
- (void)updateStatusItem;
- (IBAction)showInMenuBarAct:(id)sender;
- (IBAction)openPrefs:(id)sender;
- (IBAction)openInfo:(id)sender;
- (IBAction)openUpdater:(id)sender;
- (IBAction)disable:(id)sender;
- (void)growlNotify:(NSString *)title andDescription:(NSString *)description;
- (BOOL)enabled;

// implemented by subclasses
- (void)setEnabled:(BOOL)enable;
- (void)attachListener:(AudioDevicePropertyID)adProp;
- (void)removeListener:(AudioDevicePropertyID)adProp;
- (BOOL)jackConnected;

@end

#endif /* __APPCONTROLLER_H__ */
