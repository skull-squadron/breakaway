/*
 * GrowlNotifier.m
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

#import "GrowlNotifier.h"
#import "DebugUtils.h"
#import <Growl/Growl.h>

@implementation GrowlNotifier

-(void) awakeFromNib
{
//	NSBundle *myBundle = [NSBundle bundleForClass:[GrowlNotifier class]];
//	NSString *growlPath = [[myBundle privateFrameworksPath]
//	stringByAppendingPathComponent:@"Growl.framework"];
//	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
//	if (growlBundle && [growlBundle load]) {
//		// Register ourselves as a Growl delegate
//		[GrowlApplicationBridge setGrowlDelegate:self];
//	} else {
//		DEBUG_OUTPUT(@"Could not load Growl.framework");
//	}
	[GrowlApplicationBridge setGrowlDelegate:self];
}

- (void)growlNotify:(NSString *)title andDescription:(NSString *)description
{
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:title
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	NSArray *acceptedNotifications = [NSArray arrayWithObjects:
		NSLocalizedString(@"Jack Connected", @""),
		NSLocalizedString(@"Jack Disconnected", @""),
		NSLocalizedString(@"Disabled", @""),
		NSLocalizedString(@"Enabled",@""),
		nil];
	
	NSArray *defaultNotifications = [NSArray arrayWithObjects:
		NSLocalizedString(@"Jack Connected", @""),
		NSLocalizedString(@"Jack Disconnected", @""),
		NSLocalizedString(@"Disabled", @""),
		nil];
	
	NSDictionary *myDict = [NSDictionary dictionaryWithObjectsAndKeys:
		acceptedNotifications, GROWL_NOTIFICATIONS_ALL,
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		 @"Breakaway", GROWL_APP_NAME,
		nil];
	return myDict;
}

- (NSString *) applicationNameForGrowl
{
	return @"Breakaway";
}
@end
