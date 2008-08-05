/*
 * DebugUtils.h
 * Breakaway
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

#import "AIAppleScriptPlugin.h"

@implementation AIAppleScriptPlugin

#pragma mark Some Required Plugin Info

- (NSString*)pluginTypeName
{
	return @"AppleScript Trigger";
}

- (BOOL)instantiate 
{
	return TRUE;
}

- (NSString*)pluginUniqueName
{
	return name;
}

- (NSView*)preferenceView
{
	if(!preferences)
	{ 
		//Load our view 
		[NSBundle loadNibNamed:@"AppleScriptPlugin.nib" owner:self]; 
	}
	// link up your NSView in IB and return that outlet here. Breakaway handles loading your plugin nib for you
	return preferences;
}

#pragma mark 

/*
 this gets called when the plugin is first instantiated (re loaded)
 this is also bad programming convention, as i have made the controller and object in the same class. ideally,
 you would want to have two separate classes; one that controlls all the objects, and one soley as the object
 */
- (id)init
{
	if (!(self = [super init])) return nil;
	
	// if our array, hasn't been made yet, make it and fill it up
	if (!instancesArray)
	{
		instancesArray = [[NSMutableArray alloc]init];
		
		int i;
		NSMutableArray* tmpArray = [[NSUserDefaults standardUserDefaults]objectForKey:@"AIAppleScriptTriggers"];
		for (i=0;[tmpArray count]>i;i++)
		{
			if ([[tmpArray objectAtIndex:i]count] >= 8)
				[instancesArray addObject:[[AIAppleScriptPlugin alloc]initFromDictionary:[tmpArray objectAtIndex:i]]];
			else NSLog(@"Not enough attributes to make an AITrigger (%@). Not adding to instancesArray.",[[tmpArray objectAtIndex:i]description]);
		}
	}
	return self;
	
}

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

/*
 this fn is called when we load our nib, so this hooks in all our stuff for saving
 make sure you set the application's delegate to your file owner, or this won't be called at the right time
 */
-(void)awakeFromNib
{
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.enabled" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.name" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.nmode" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.hpmode" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.mute" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.unmute" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.hin" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.hout" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.script" options:nil context:nil];
	[arrayController addObserver:self forKeyPath:@"arrangedObjects.lod" options:nil context:nil];
	
	[arrayController setContent: instancesArray];
}

// this fn is whats the observers call from above during a change
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// if something is selected, save
	if ([[arrayController selectedObjects]count] != 0) [self exportToArray];
}

- (void)exportToArray
{
	int i;
	id instance;
	NSMutableArray* returnArray = [NSMutableArray array];
	
	for (i=0;[instancesArray count]>i;i++)
	{
		instance = [instancesArray objectAtIndex:i];
		[returnArray addObject:[instance export]];
	}
	
	NSArray* trueArray = [NSArray arrayWithArray:returnArray];
	
	[[NSUserDefaults standardUserDefaults]setObject:trueArray forKey:@"AIAppleScriptTriggers"];
	[[NSUserDefaults standardUserDefaults]synchronize];
}

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
#pragma mark Script Functions

- (void)activate:(int)prototype
{
	NSLog(@"::Launching Script::\n::%@::\n::%@::",[applescript source],[applescript isCompiled]?@"COMPILED":@"NOT COMPILED");
	if (![applescript isCompiled]) [applescript performSelectorOnMainThread:@selector(compileAndReturnError:) withObject:nil waitUntilDone:NO];
	[applescript performSelectorOnMainThread:@selector(executeAndReturnError:) withObject:nil waitUntilDone:NO];
}

-(void)compile
{
	if([applescript source]== nil) [self setScript:nil];
	[applescript compileAndReturnError:nil];
}

#pragma mark Script Actions

- (IBAction)locateScript:(id)sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	if([panel runModalForDirectory:nil file:nil types:nil] == NSOKButton)
		[[[arrayController selectedObjects]objectAtIndex:0] setScript:[[panel filenames]objectAtIndex:0]];
	
	/*[triggerTable tableViewSelectionDidChange:nil];
	 [triggerTable reloadData];*/
	
}

- (IBAction)revealScript:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile: [[[arrayController selectedObjects]objectAtIndex:0] script] inFileViewerRootedAtPath:nil];
}

- (IBAction)openScript:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[arrayController selectedObjects]objectAtIndex:0] script]];
}

- (IBAction)modeCheck:(id)sender
{
	if ([[arrayController selectedObjects]count] && [[[arrayController selectedObjects]objectAtIndex:0]modeSelected])
	{
		[mute setEnabled:TRUE];
		[unmute setEnabled:TRUE];
	}
	else
	{
		[mute setEnabled:FALSE];
		[unmute setEnabled:FALSE];
	}
}


#pragma mark KVC Accessors
//{{{ KVC Functions

-(BOOL)valid
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

-(BOOL)modeSelected
{
	int tmp = (hpmode||nmode)?1:0;
	[self setModeSelected:tmp];
	return modeSelected;
}

-(NSString*)name
{
	return name;
}

-(BOOL)nmode
{
	return nmode;
}

-(BOOL)hpmode
{
	return hpmode;
}

-(BOOL)mute
{
	return mute;
}

-(BOOL)unmute
{
	return unmute;
}

-(BOOL)hin
{
	return hin;
}

-(BOOL)hout
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

-(BOOL)enabled
{
	return enabled;
}

- (int)familyCode
{
	return familyCode;
}

-(void)setModeSelected:(BOOL)var
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

-(void)setEnabled:(BOOL)var
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

-(void)setValid:(BOOL)var
{
	valid = var;
}

#pragma mark Accessors (External)

-(NSArrayController*)arrayController
{
	return arrayController; 
}

- (NSMutableArray*)instancesArray
{
	return instancesArray;
}
@end
