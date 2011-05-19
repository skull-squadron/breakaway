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
#import "AITriggerMasks.h"

@protocol AIPluginProtocol

/******************************************************************************
 * initializeClass:
 *
 * Required
 * Someone is using the plugin's principle class. It is your responsibility to
 * hand onto the pluginBundle. Simply retain the bundle, and release it on
 * terminateClass
 * Return TRUE on good return, and FALSE on error
 *****************************************************************************/
+ (BOOL)initializeClass:(NSBundle*)pluginBundle;

/******************************************************************************
 * terminateClass
 *
 * Required
 * Someone is not using your class anymore. Release the bundle object, as we
 * don't need it anymore
 * Return TRUE on good return, and FALSE on error
 *****************************************************************************/
+ (void)terminateClass;

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
 * prefView
 *
 * Required by protocol
 * Returns the view to load when the preference is selected
 * Should be 443px x 336px
 *****************************************************************************/
- (NSView*)prefView;

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
