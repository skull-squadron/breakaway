/*
 * AppController.m
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

#import "AppController.h"
#import "LegacyAppController.h"
#import "NewAppController.h"

#import "defines.h"

#import "GrowlNotifier.h"
#import "PreferencesController.h"
#import "AIPluginController.h"

#import "DebugUtils.h"

#import "AIPluginSelector.h"
#import "AIPluginProtocol.h"
#import "PreferenceHandler.h"

#import <CoreAudio/CoreAudio.h>
#import <Sparkle/SUUpdater.h>

//#define ANIMATION_SPEED 0.01666666 /* 60 Hz */
#define ANIMATION_SPEED 0.03333333 /* 30 Hz */

@implementation AppController

@synthesize growlNotifier = _growlNotifier;
@synthesize preferencesController = _preferencesController;
@synthesize pluginController = _pluginController;
@synthesize userDefaults = _userDefaults;
@synthesize inAnimation = _inAnimation;
@synthesize statusItem = _statusItem;
@synthesize images = _images;

+ (BOOL)shouldRegisterNewAPI
{
    return NSAppKitVersionNumber >= NSAppKitVersionNumber10_9;
}

- (void)setInAnimation:(BOOL)inAnimation
{
    NSLog(@"inAnimation %d -> %d", _inAnimation, inAnimation);
    _inAnimation = inAnimation;
}

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    
    // replace myself with the correct subclass
    if ([self.className isEqualToString:@"AppController"]) {
        id newSelf = (self.class.shouldRegisterNewAPI)
                ? [[NewAppController alloc] init]
                : [[LegacyAppController alloc] init];
        [self release];
        self = newSelf;
        NSLog(@"app ctrlr: %@", self);
        setSharedBreakaway(self);
    }
    
    return self;
}
/*
+(BOOL)darkMenuStyle
{
    Class nsAppearanceClass = NSClassFromString(@"NSAppearance");
    if ([nsAppearanceClass respondsToSelector:@selector(appearanceNamed:)])
    {
        [nsAppearanceClass appearanceNamed:NSAppearanceNameVibrantDark];
        return [[self effectiveAppearance] isEqual:darkAppearance];
    }
}
*/
- (void)awakeFromNib
{
    // Sync UI from preferences
    [self setStatusItemVisible:self.statusItemVisible];
    [self setEnabled:self.enabled];
    
    // calls our controller to load our preference window, including all our plugins
    DEBUG_OUTPUT(@"finished setting up and loading prefs");
}

- (void)dealloc
{
    self.statusItemVisible = NO;
    self.enabled = NO;
    [super dealloc];
}

+ (NSArray *)animations
{
    static NSArray *animations = nil;
    if (!animations) {
        animations = [
                      @[
                        @[@(kPlugged), @(kPU1), @(kPU2), @(kPU3), @(kPU4), @(kPU5), @(kPU6), @(kUnplugged)],
                        @[@(kPlugged), @(kPD1), @(kPD2), @(kPD3), @(kPD4), @(kPD5), @(kPD6), @(kDisabled)],
                        @[@(kUnplugged), @(kUD1), @(kUD2), @(kUD3), @(kUD4), @(kUD5), @(kUD6), @(kDisabled)]
                        ] retain];
    }
    return animations;
}

- (NSUserDefaults *)userDefaults
{
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        // Setting up our defaults here
        NSDictionary *defaults = @{
                                   // General
                                   @"showInMenuBar": @YES,
                                   @"enableBreakaway": @YES,
                                   
                                   @"showIcon": @NO,
                                   @"SUUpdate": @2,
                                   
                                   @"fadeInTime": @2.0,
                                   
                                   @"iTunesPluginEnabled": @YES, // FIXME: this shouldn't be hardcoded
                                   
                                   @"keepVol": @YES,
                                   };
        [_userDefaults registerDefaults:defaults];
        DEBUG_OUTPUT1(@"Registered Defaults: %@",defaults);
    }
    return _userDefaults;
}

- (GrowlNotifier *)growlNotifier
{
    if (!_growlNotifier) {
        _growlNotifier = [[GrowlNotifier alloc] init];
    }
    return _growlNotifier;
}

- (AIPluginController *)pluginController
{
    if (!_pluginController) {
        _pluginController = [[AIPluginController alloc] init];
    }
    return _pluginController;
}



#pragma mark 
#pragma mark Status item

/*- (BOOL)statusItem
{
    return [self.userDefaults boolForKey:@"showInMenuBar"];
}
 */

- (NSArray *)images
{
    if (!_images) {
        // Access these images using the enums
        // Therefore, order is important. Do not change
        _images = [[NSArray arrayWithObjects:
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"plugged" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu1" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu2" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu3" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu4" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu5" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pu6" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"unplugged" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud1" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud2" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud3" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud4" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud5" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ud6" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"disabled" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd1" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd2" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd3" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd4" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd5" ofType:@"tiff"]] autorelease],
                    [[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"pd6" ofType:@"tiff"]] autorelease],
                    nil] retain];
        
        // get the images for the status item set up
        for (NSImage *img in _images) {
            if (!img) continue; // if we don't have an image to work with, don't fret
            [img setSize:NSMakeSize(15,15)];
        }
    }
    return _images;
}

- (BOOL)statusItemVisible
{
    BOOL result = [self.userDefaults boolForKey:@"showInMenuBar"];
    NSLog(@"statusItemVisible: %d", result);
    return result;
}

- (void)setStatusItemVisible:(BOOL)visible
{
    NSLog(@"setStatusItem:%d", visible);
    if (visible) {
        
        // Status bar stuff
        if (_statusItem) {
            [_statusItem release];
            _statusItem = nil;
        }
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        [_statusItem retain];
        
        [_statusItem setMenu:statusItemMenu];
        [_statusItem setEnabled:YES];
        [_statusItem setHighlightMode:YES];
        
        // run this so we can get a correct state on our menu extra
        [self updateStatusItem];
    } else {
        // Release our status item
        if (_statusItem)
        {
            [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
            [_statusItem release];
            _statusItem = nil;
        }

        if (_images) {
            [_images release];
            _images  = nil;
        }
    }
}

/******************************************************************************
 * fadeInUsingTimer:
 *
 * Change the status icon. Very cool
 * To make it faster/slower, change the #define ANIMATION_SPEED
 * With the current implementation, it's kind of a pain to make more frames
 * All state transitions are 8 frames long
 *****************************************************************************/
- (void)animateUsingTimer:(NSTimer*)timer
{
    NSNumber *nextFrame = [_curAnimationEnumerator nextObject];
    
    if (nextFrame) {
        NSLog(@"animateUsingTimer: next");
        self.statusItem.image = self.images[nextFrame.intValue];
    } else { // no next frame
        NSLog(@"animateUsingTimer: done");
        [timer invalidate]; // base case
        self.inAnimation = FALSE;
        [_curAnimationEnumerator release];
    }
    
}

/******************************************************************************
 * updateStatusItem
 *
 * Creates a thread which runs animateUsingTimer:
 * This function is essentially mutex'd, so you don't need to worry about
 * calling it too often, as successive calls will be thrown away
 *****************************************************************************/
- (void)updateStatusItem
{
    DEBUG_OUTPUT(@"updateStatusItem");
    static tImageType prevImage = kUnknownImage;
    
    if (self.inAnimation) {
        DEBUG_OUTPUT(@"updateStatusItem stop: in animation");
        return;
    }
    if (!self.statusItem) {
        DEBUG_OUTPUT(@"updateStatusItem stop: no status item");
        return;
    }
    
    tImageAnimation animation = kPluggedUnknown;
    BOOL reverse = FALSE;
        
    
    if (!self.enabled) // Disabled
    {
        reverse = FALSE;
        if (prevImage == kPlugged) {
            NSLog(@"plugged -> disabled");
            animation = kPluggedDisabled;
        } else if (prevImage == kUnplugged) {
            NSLog(@"unplugged -> disabled");
            animation = kUnpluggedDisabled;
        } else {
            DEBUG_OUTPUT1(@"disabled but not from plugged or unplugged: %d", prevImage);
        }
        prevImage = kDisabled;
        
        [disableMI setTitle:NSLocalizedString(@"Enable",nil)];
    } else { // Enabled
        if (self.jackConnected) { // plugged
            reverse = TRUE;
            if (prevImage == kUnplugged) {
                NSLog(@"unplugged -> plugged");
                animation = kPluggedUnplugged;
            } else if (prevImage == kDisabled) {
                NSLog(@"disabled -> plugged");
                animation = kPluggedDisabled;
            } else {
                DEBUG_OUTPUT1(@"plugged but not from unplugged or disabled: %i", prevImage);
            }
            prevImage = kPlugged;
        } else { // unplugged
            if (prevImage == kPlugged) {
                NSLog(@"plugged -> unplugged");
                animation = kPluggedUnplugged;
            } else if (prevImage == kDisabled) {
                NSLog(@"disabled -> unplugged");
                animation = kUnpluggedDisabled;
                reverse = TRUE;
            }  else {
                DEBUG_OUTPUT1(@"unplugged but not from plugged or disabled: %i", prevImage);
            }
            prevImage = kUnplugged;
        }
        [disableMI setTitle:NSLocalizedString(@"Disable",nil)];
    }
    
    if (animation == kPluggedUnknown) {
        DEBUG_OUTPUT(@"updateStatusItem: set image due to unknown plugged status");
        self.statusItem.image = self.images[prevImage];
    } else {
        _curAnimationEnumerator = (!reverse) ? [self.class.animations[animation] objectEnumerator]
                                            : [self.class.animations[animation] reverseObjectEnumerator];
        
        [_curAnimationEnumerator retain];
        
        self.inAnimation = TRUE;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            DEBUG_OUTPUT(@"updateStatusItem: scheduling animateUsingTimer:");
            [NSTimer scheduledTimerWithTimeInterval:ANIMATION_SPEED
                                             target:self
                                           selector:@selector(animateUsingTimer:)
                                           userInfo:nil
                                            repeats:YES];
        });
    }
}


#pragma mark 
#pragma mark IB Button Actions
- (IBAction)showInMenuBarAct:(id)sender
{
    self.statusItemVisible = self.statusItemVisible;
}

- (PreferencesController *)preferencesController
{
    if (!_preferencesController) {
        _preferencesController = [[PreferencesController alloc] init];
    }
    return _preferencesController;
}

- (IBAction)openPrefs:(id)sender
{
	[self.preferencesController showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)openInfo:(id)sender
{
	[NSApp orderFrontStandardAboutPanel:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)openUpdater:(id)sender
{
	[[SUUpdater sharedUpdater] checkForUpdates:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

#pragma mark
#pragma mark Accessor Functions
- (IBAction)disable:(id)sender
{
    BOOL disable = [[disableMI title] isEqual: NSLocalizedString(@"Disable",nil)];
    [self setEnabled:!disable];
}

- (void)growlNotify:(NSString *)title andDescription:(NSString *)description
{
    [self.growlNotifier growlNotify:title andDescription:description];
}

#pragma mark - Delegate Fns

// pretty much when the app is open and someone double clicks the icon in the finder
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if (!flag) [self openPrefs:self];
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
}

- (BOOL)enabled
{
    BOOL result = [self.userDefaults boolForKey:@"enableBreakaway"];
    DEBUG_OUTPUT1(@"breakaway is %@", (result) ? @"enabled" : @"disabled");
    return result;
}

#pragma mark - Virtual methods (to be implemented by subclasses)

- (BOOL)jackConnected
{
    NSLog(@"jackConnected virtual method called");
    return NO;
}

- (void)attachListener:(AudioDevicePropertyID)adProp
{
    NSLog(@"attachListener: virtual method called");
}

- (void)setEnabled:(BOOL)enable
{
    NSLog(@"setEnabled: virtual method called");
}

- (void)removeListener:(AudioDevicePropertyID)adProp
{
    NSLog(@"removeListener: virtual method called");
}

@end


