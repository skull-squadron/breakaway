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

// Required: name of unique plugin
- (NSString*)name;

// Required: TRUE allows the plugin to activate. FALSE and the plugin cannot activate
- (BOOL)enabled;

// Required: Allows the user to enable/disable your plugin
- (void)setEnabled:(BOOL)var;

// Required: sends the interrupt mask (jack/mute status)
- (void)activate:(kTriggerMask)triggerMask;

@end
