/*
 * AIAppleScriptPlugin.m
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

#import "AIAppleScriptPlugin.h"
@implementation AIAppleScriptPlugin

// this is how we load our instances. exactly how it was done in old trigger days
-(id)initFromDictionary:(NSDictionary*)attributes
{	
	if (!(self = [super init])) return nil;
	
	//if ([attributes count] < 10) { NSLog(@"Not enough attributes to pop. Returning NULL."); return NULL; }
	
    [self setName:[attributes objectForKey:@"name"]];
	
	// Modes
    [self setnMode:[[attributes objectForKey:@"nmode"]boolValue]];
	[self sethpMode:[[attributes objectForKey:@"hpmode"]boolValue]];
	
	// Triggers
	[self setMute:[[attributes objectForKey:@"mute"]boolValue]];
	[self setUnmute:[[attributes objectForKey:@"unmute"]boolValue]];
	[self setHin:[[attributes objectForKey:@"hin"]boolValue]];
	[self setHout:[[attributes objectForKey:@"hout"]boolValue]];
	
    [self setLod:[[attributes objectForKey:@"lod"]intValue]];
	[self setScript:[attributes objectForKey:@"script"]];
	[self setEnabled:[[attributes objectForKey:@"enabled"]boolValue]];
	
	[self setFamilyCode];
	
	// if we aren't loading on demand, compile now and be done with it
	if (!lod) [self compile];
	
	return self;
}

- (NSColor*)scriptTextColor
{
	if ([self valid]) return [NSColor blackColor];
	else  return [NSColor redColor];
}

#pragma mark Script Functions

-(void)compile
{
	if([applescript source]== nil) [self setScript:nil];
	[applescript compileAndReturnError:nil];
}

- (void)activate:(int)prototype
{
	NSLog(@"::Launching Script::\n::%@::\n::%@::",[applescript source],[applescript isCompiled]?@"COMPILED":@"NOT COMPILED");
	if (![applescript isCompiled]) [applescript performSelectorOnMainThread:@selector(compileAndReturnError:) withObject:nil waitUntilDone:NO];
	[applescript performSelectorOnMainThread:@selector(executeAndReturnError:) withObject:nil waitUntilDone:NO];
}


#pragma mark KVC Accessors
//{{{ KVC Functions

-(bool)valid
{
	if([[NSFileManager defaultManager]fileExistsAtPath:script])
	{
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}

-(bool)modeSelected
{
	int tmp = (hpmode||nmode)?1:0;
	return tmp;
}

-(NSString*)name
{
	return name;
}

-(bool)nmode
{
	return nmode;
}

-(bool)hpmode
{
	return hpmode;
}

-(bool)mute
{
	return mute;
}

-(bool)unmute
{
	return unmute;
}

-(bool)hin
{
	return hin;
}

-(bool)hout
{
	return hout;
}

-(NSString*)script
{
	return script;
}

-(int)lod
{
	return lod;
}

-(bool)enabled
{
	return enabled;
}

- (int)familyCode
{
	return familyCode;
}

-(void)setModeSelected:(bool)var
{
	modeSelected = var;
}

//}}}

#pragma mark KVC sets
//{{{

-(void)setScript:(NSString*)var
{
	// If we pass a null string, just run through our stuff, as we probably just want to reset up our scripts
	if(var)
	{
		[script release];
		script = [var retain];
	}
	
    if(applescript) [applescript release];
	
	// If the script we are given is a path
	if([[NSFileManager defaultManager]fileExistsAtPath:script])
	{
		applescript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath: script] error:nil];
		[self setValid:TRUE];
		[self compile];
	}
	else
	{
		[self setEnabled:FALSE];
		[self setValid:FALSE];
	}
}

-(void)setEnabled:(bool)var
{	
	if([[NSFileManager defaultManager]fileExistsAtPath:script])
	{
		[self setValid:TRUE];
		enabled = var;
		[self setFamilyCode];
	}
	else
	{
		enabled = FALSE;
		[self setValid:FALSE];
		[self setFamilyCode];
	}
}

-(void)setFamilyCode
{	
	int tmp = 0;
	
	if (hout) { tmp++; tmp<<=1; }
	else tmp<<=1;
	if (hin) { tmp++; tmp<<=1; }
	else tmp<<=1;
	if (unmute) { tmp++; tmp<<=1; }
	else tmp<<=1;
	if (mute) { tmp++; tmp<<=1; }
	else tmp<<=1;
	if (hpmode) { tmp++; tmp<<=1; }
	else tmp<<=1;
	if (nmode) { tmp++; tmp<<=1; }
	else tmp<<=1;
	if (enabled) { tmp++; }
	//else tmp<<=1;
	familyCode = tmp;
}

-(void)setName:(NSString*)var
{
	[name release];
	name = [var retain];
}

-(void)setnMode:(bool)var
{
	nmode = var;
	[self setFamilyCode];
}

-(void)sethpMode:(bool)var
{
	hpmode = var;
	[self setFamilyCode];
}

-(void)setMute:(bool)var
{
	mute = var;
	[self setFamilyCode];
}

-(void)setUnmute:(bool)var
{
	unmute = var;
	[self setFamilyCode];
}

-(void)setHin:(bool)var
{
	hin = var;
	[self setFamilyCode];
}

-(void)setHout:(bool)var
{
	hout = var;
	[self setFamilyCode];
}

-(void)setLod:(int)var
{
	lod = var;
}

-(void)setValid:(bool)var
{
	valid = var;
}

#pragma mark End Operations
-(NSDictionary*)export
{
	//NSLog(@"%@,%i,%i,%i,%@, %i",name,mode,trigger,lod,script,enabled);
	NSDictionary* tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:
							 name, @"name",
							 [NSNumber numberWithBool:nmode], @"nmode",
							 [NSNumber numberWithBool:hpmode], @"hpmode",
							 [NSNumber numberWithBool:mute], @"mute",
							 [NSNumber numberWithBool:unmute], @"unmute",
							 [NSNumber numberWithBool:hin], @"hin",
							 [NSNumber numberWithBool:hout], @"hout",
							 [NSNumber numberWithInt:lod], @"lod",
							 script,@"script",
							 [NSNumber numberWithBool:enabled], @"enabled",
							 nil];
	return tmpDict;
}

-(void)dealloc
{
    if (applescript) [applescript release];
    if (name) [name release];
    if (script) [script release];
    [super dealloc];
}

@end
