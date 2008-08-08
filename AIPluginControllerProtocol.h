/*
 * AIPluginControllerProtocol.h
 * Breakaway
 *
 * Created by Kevin Nygaard on 8/8/08.
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

@protocol AIPluginControllerProtocol

// Required: if your plugin is designed to be copied more than once (like an AppleScript plugin), return TRUE. Otherwise
// if you have a single shot plugin that does not need multiple instantiations, return FALSE.
- (bool)isInstantiable;

// Required: an array controller with instancesArray as its content
// !!IMPORTANT NOTE!! 
// THIS MUST RETURN SOMETHING FOR "NAME" AND "ENABLED" IN KVC FASHION
//
// - (void)setName:(NSString*)var
// - (NSString*)name;
// - (void)setEnabled:(bool)var;
// - (BOOL)enabled;
// 
// If your isInstantiable == FALSE, you don't have to include setName: if you don't want it
//
// !!ANOTHER IMPORTANT NOTE!!
// BREAKAWAY MAKES USE OF arrayController's add: AND remove: METHODS
- (NSArrayController*)arrayController;

// Required: name of the plugin type (ie. AppleScript trigger, VLC manager)
// Do not confuse this with "name". Name is the unique name of the plugin (ie. Sleep on mute). 
// For example, a plugin may have a pluginTypeName of "AppleScriptTrigger" and a name of "Sleep on mute".
// If you don't plan on having your plugin instantiated more than once, they will probably be the same though
- (NSString*)pluginTypeName;

// Required: NSView containing the options to this plugin
- (NSView*)preferenceView;

@end
