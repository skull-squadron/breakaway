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

@class AppController;

@interface AIAppleScriptPlugin : NSObject <AIPluginProtocol>
{
	BOOL enabled;	
    AppController *appController;
    IBOutlet NSView *prefView;   
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}
@property (assign) BOOL enabled;
@property (assign,readonly) NSView *prefView;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (id)initFromDictionary:(NSDictionary*)attributes;
- (NSDictionary*)export;
- (void)compile;

- (BOOL)modeSelected;
- (NSColor*)scriptTextColor;
- (NSImage*)image;
- (IBAction) saveAction:(id)sender;

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
