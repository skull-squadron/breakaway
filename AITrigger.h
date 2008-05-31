/*
 * AITrigger.h
 * Breakaway
 * Created by Kevin Nygaard on 8/15/07.
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


@interface AITrigger : NSObject
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

-(id)initFromDictionary:(NSDictionary*)attributes;
-(NSDictionary*)export;

-(void)compile;
-(void)execute;

-(NSString*)name;
-(BOOL)nmode;
-(BOOL)hpmode;
-(BOOL)mute;
-(BOOL)unmute;
-(BOOL)hin;
-(BOOL)hout;
-(int)familyCode;
-(int)lod;
-(NSString*)script;
-(BOOL)enabled;
-(BOOL)valid;
-(BOOL)modeSelected;

-(void)setName:(NSString*)var;
-(void)setnMode:(bool)var;
-(void)sethpMode:(bool)var;
-(void)setMute:(bool)var;
-(void)setUnmute:(bool)var;
-(void)setHin:(bool)var;
-(void)setHout:(bool)var;
-(void)setFamilyCode;
-(void)setLod:(int)var;
-(void)setScript:(NSString*)var;
-(void)setEnabled:(BOOL)var;
-(void)setValid:(BOOL)var;
-(void)setModeSelected:(BOOL)var;

@end
