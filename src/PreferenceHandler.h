/*
 * PreferenceHandler.h
 * Breakaway
 * Created by Kevin Nygaard on 6/14/06.
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
@class SUUpdater, SUAppcast;
NSString* osTypeToFourCharCode(OSType inType);

@interface PreferenceHandler : NSObject
{
    IBOutlet id loginItem;
   	IBOutlet id drawer;
    // Sparkle
    IBOutlet id lastCheck;
    // Test
	BOOL done;
	IBOutlet id testResultBox;
    IBOutlet id userConcernRadioButton;
}

- (IBAction)addAsLoginItem:(id)sender;
- (BOOL)isLoginItem;
- (IBAction)showInDock:(id)sender;
- (BOOL)isUIElement;
- (IBAction)showInMenuBar:(id)sender;
- (IBAction)viewReadme:(id)sender;
- (IBAction)sendEmail:(id)sender;
- (IBAction)enableBreakaway:(id)sender;
- (void)updater:(SUUpdater *)updater didFinishLoadingAppcast:(SUAppcast *)appcast;
- (IBAction)checkForUpdates:(id)sender;
- (void)setAutomaticallyDownloadsUpdates:(BOOL)automaticallyDownloadsUpdates;
- (void)setAutomaticallyChecksForUpdates:(BOOL)automaticallyChecks;
- (BOOL)automaticallyDownloadsUpdates;
- (BOOL)automaticallyChecksForUpdates;
- (void)logTestResultForProperty:(NSString *)property withReturn:(OSStatus)returnStatus andData:(UInt32)dataSource;
- (IBAction)startTest:(id)sender;
- (IBAction)sendResults:(id)sender;

@end
