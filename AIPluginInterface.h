/*
 * AIPluginInterface.h
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

@protocol AITriggerPluginProtocol

- (id)initMain;
- (NSMutableArray*)instancesArray;
- (void)addInstance;
- (void)removeInstance;

// Required: name of the plugin type (ie. AppleScript trigger, VLC manager)
- (NSString*)pluginTypeName;

// Required: Unique name of the plugin (ie. Sleep on mute). Do not confuse this with pluginTypeName.
// For example, a plugin may have a pluginTypeName of "AppleScriptTrigger" and a pluginUniqueName of "Sleep on mute".
// If you don't plan on having your plugin instantiated more than once, just make this the same as pluginTypeName
- (NSString*)pluginUniqueName;

// Required: a bitfield represented as a number containing the trigger activation paramaters
/* 
 Bit num:  7 6 5 4   3 2 1 0
 Bits   :  0 1 1 0   0 1 1 1
 
 Bit 0: Trigger Enabled (1 for TRUE, 0 for FALSE)
 Bit 1: Normal Mode
 Bit 2: Headphones Mode
 Bit 3: Mute
 
 Bit 4: Unmute
 Bit 5: Headphones jack in
 Bit 6: Headphones jack out
 Bit 7: **NOT USED**
 
 In this example, our family code would be 0110 0111, which is 103 in decimal. Our trigger would be called when
 in headphones mode, and when the jack is pulled or connected.
 
 Take note, that impossible situations (ie. 0110 0011) are not accounted for. If you make that your family code, your trigger
 will never be activated, so be careful of how Breakaway handles different modes. If in doubt, you can always just have both
 modes on; that is legal.
 
 Code will be supplied for you to easily generate this family code if you are unfamiliar with bit level manipulation
 */
- (int)familyCode;

// Required: NSView containing the options to this plugin
- (NSView*)preferenceView;

// Required: this will house whatever it is you want executed as a trigger. You will also be sent the prototype code, that is,
// the current paramaters that allowed your code to execute. So, if you had a family code of 0110 0011, possible prototype codes
// could be 0100 0011 and 0010 0011. If your plugin is setup to handle multiple situations (such as different actions for headphones
// in/out) you would use this prototype code to decern the circumstance as to why your code is being executed.
// Here is the actual code that gets called so you can see how the prototype works with the family code:
// if (([tmpTrigger familyCode] & prototype) == prototype) [tmpTrigger activate:prototype];
- (void)activate:(int)prototype;

@end
