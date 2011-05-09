/*
 * AIPluginProtocol.h
 * Breakaway
 *
 * Created by Kevin Nygaard on 7/6/08.
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

typedef enum {
    kTriggerMute = 1 << 0, // 1 for mute on, 0 for mute off
    kTriggerJackStatus = 1 << 1, // 1 for heaphones, 0 for ispk
    kTriggerInt = 1 << 2, // 1 for source change, 0 for mute
} kTriggerMask;

@protocol AIPluginProtocol

/******************************************************************************
 * initWithController:
 *
 * Required
 * Initializer for the plugin. Called upon instantiation.
 * Sets up global variables
 * The controller is the main Breakaway instance (AppController). You can call
 * Growl functions, and operate call CA functions
 *****************************************************************************/
- (id)initWithController:(id)controller;

/******************************************************************************
 * name
 *
 * Required
 * The name of the plugin
 *****************************************************************************/
- (NSString*)name;

/******************************************************************************
 * image
 *
 * Required by protocol
 * The icon of the plugin
 *****************************************************************************/
- (NSImage*)image;

/******************************************************************************
 * enabled
 *
 * Required
 * TRUE allows the plugin to activate. FALSE otherwise
 *****************************************************************************/
- (BOOL)enabled;

/******************************************************************************
 * setEnabled
 *
 * Required
 * Allows the user to enable/disable your plugin
 *****************************************************************************/
- (void)setEnabled:(BOOL)var;

/******************************************************************************
 * activate:
 *
 * Required by the protocol
 * Called during a CoreAudio interrupt. triggerMask contains the interrupt mask,
 * which is the jack status, mute status, and reason for interrupt (either mute
 * or data source change)
 *****************************************************************************/
- (void)activate:(kTriggerMask)triggerMask;

/******************************************************************************
 * acceptedGrowlNotes
 *
 * Not required, unless you want to use Growl notifications
 * An array which specifies all the messages your plugin can send to Growl
 *****************************************************************************/
- (NSArray*)acceptedGrowlNotes;

/******************************************************************************
 * defaultGrowlNotes
 *
 * Not required, unless you want to use Growl notifications
 * An array which specifies the default Growl messages you want to show the user
 *****************************************************************************/
- (NSArray*)defaultGrowlNotes;

@end
