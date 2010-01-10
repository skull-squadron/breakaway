/*
 * AIAppleScriptPlugin.h
 * Breakaway
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
#import "AIPluginProtocol.h"

@interface AIAppleScriptPlugin : NSObject<AIPluginProtocol>
{
	int isCompiled;
    NSAppleScript* applescript;
	NSImage* notFoundImage;
	
    NSString* name;
    BOOL nmode;
	BOOL hpmode;
	BOOL mute;
	BOOL unmute;
	BOOL hin;
	BOOL hout;
    int lod;
	int familyCode;
    NSString* script;
	BOOL enabled;
	BOOL valid;
	BOOL modeSelected;
	
}

- (id)initFromDictionary:(NSDictionary*)attributes;
- (NSDictionary*)export;
- (void)compile;

- (BOOL)modeSelected;
- (NSColor*)scriptTextColor;
- (NSImage*)image;

// KVC stuff
- (BOOL)enabled;
- (BOOL)hin;
- (BOOL)hout;
- (BOOL)hpmode;
- (BOOL)mute;
- (BOOL)nmode;
- (BOOL)unmute;
- (BOOL)valid;
- (NSString*)name;
- (NSString*)script;
- (int)familyCode;
- (int)lod;

- (void)setEnabled:(BOOL)var;
- (void)setFamilyCode;
- (void)setHin:(BOOL)var;
- (void)setHout:(BOOL)var;
- (void)setLod:(int)var;
- (void)setMute:(BOOL)var;
- (void)setName:(NSString*)var;
- (void)setScript:(NSString*)var;
- (void)setUnmute:(BOOL)var;
- (void)setValid:(BOOL)var;
- (void)sethpMode:(BOOL)var;
- (void)setnMode:(BOOL)var;

@end
