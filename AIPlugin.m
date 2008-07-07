/*
 * DebugUtils.h
 * Breakaway
 * Created by Kevin Nygaard on 7/6/08.
 * Copyright 2008 Kevin Nygaard.
 * Plugin design/template sample code from Rainer Brockerhoff, MacHack 2002.
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

#import "AIPlugin.h"

static NSBundle* pluginBundle = nil;

@implementation AIPlugin

+ (BOOL)initializeClass:(NSBundle*)theBundle {
	if (pluginBundle) {
		return NO;
	}
	pluginBundle = [theBundle retain];
	return YES;
}

+ (void)terminateClass {
	if (pluginBundle) {
		[pluginBundle release];
		pluginBundle = nil;
	}
}

- (void)dealloc {
	[theViewName release];
	[theObject release];
	[super dealloc];
}

+ (NSString*)message {
	return @"This is a message from the bundle.";
}

- (NSView*)theView {
	return nil;
}


- (NSString*)theViewName {
	return theViewName;
}

@end
