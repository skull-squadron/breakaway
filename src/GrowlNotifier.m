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

@synthesize registrationDictionaryForGrowl;

/******************************************************************************
 * init
 *
 * Sets up environment variables
 *****************************************************************************/
- (id)init
{
	if (!(self = [super init])) return nil;
    
    NSArray *acceptedNotifications = [NSArray arrayWithObjects:
                                      NSLocalizedString(@"Jack Connected", @""),
                                      NSLocalizedString(@"Jack Disconnected", @""),
                                      NSLocalizedString(@"Breakaway Enabled",@""),
                                      NSLocalizedString(@"Breakaway Disabled", @""),
                                      nil];
	
	NSArray *defaultNotifications = [NSArray arrayWithObjects:
                                     NSLocalizedString(@"Jack Connected", @""),
                                     NSLocalizedString(@"Jack Disconnected", @""),
                                     NSLocalizedString(@"Breakaway Disabled", @""),
                                     nil];
	
	self.registrationDictionaryForGrowl = [NSDictionary dictionaryWithObjectsAndKeys:
                                           acceptedNotifications, GROWL_NOTIFICATIONS_ALL,
                                           defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
                                           @"Breakaway", GROWL_APP_NAME,
                                           [NSNumber numberWithInt:1], GROWL_TICKET_VERSION,
                                           nil];
    return self;
}

- (NSDictionary *) registrationDictionaryForGrowl
{
    return registrationDictionaryForGrowl;
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

- (NSString *)applicationNameForGrowl
{
	return @"Breakaway";
}

@end
