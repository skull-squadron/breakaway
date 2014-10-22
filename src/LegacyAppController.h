/*
 * LegacyAppController.h
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
#ifndef __LEGACYAPPCONTROLLER_H__
#define __LEGACYAPPCONTROLLER_H__

#import "AppController.h"

@interface LegacyAppController : AppController

// implemented by subclasses of AppController
- (void)setEnabled:(BOOL)enable;
- (void)attachListener:(AudioDevicePropertyID)adProp;
- (void)removeListener:(AudioDevicePropertyID)adProp;
- (BOOL)jackConnected;

@end

#endif /* __LEGACYAPPCONTROLLER_H__ */
