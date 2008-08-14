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
	
    NSString* name;
    bool nmode;
	bool hpmode;
	bool mute;
	bool unmute;
	bool hin;
	bool hout;
    int lod;
	int familyCode;
    NSString* script;
	bool enabled;
	bool valid;
	bool modeSelected;
	
}

- (id)initFromDictionary:(NSDictionary*)attributes;
- (NSDictionary*)export;
- (void)compile;

- (bool)modeSelected;
- (NSColor*)scriptTextColor;

// KVC stuff
- (bool)enabled;
- (bool)hin;
- (bool)hout;
- (bool)hpmode;
- (bool)mute;
- (bool)nmode;
- (bool)unmute;
- (bool)valid;
- (NSString*)name;
- (NSString*)script;
- (int)familyCode;
- (int)lod;

- (void)setEnabled:(bool)var;
- (void)setFamilyCode;
- (void)setHin:(bool)var;
- (void)setHout:(bool)var;
- (void)setLod:(int)var;
- (void)setMute:(bool)var;
- (void)setName:(NSString*)var;
- (void)setScript:(NSString*)var;
- (void)setUnmute:(bool)var;
- (void)setValid:(bool)var;
- (void)sethpMode:(bool)var;
- (void)setnMode:(bool)var;

@end
