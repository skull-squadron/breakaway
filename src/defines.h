/*
 * defines.h
 * Breakaway
 * Created by Kevin Nygaard on 8/16/07.
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

extern NSString * const donateAddress;
extern NSString * const emailAddress;
extern NSString * const emailSubject;
extern NSString * const resultsEmailAddress;
extern NSString * const resultsEmailSubject;


enum {
    BATriggerEnabledMask = 1 << 0,
    BANormalModeMask = 1 << 1,
    BAHeadphonesModeMask = 1 << 2,
    BAMuteMask = 1 << 3,
    BAUnmuteMask = 1 << 4,
    BAHeadphonesJackInMask = 1 << 5,
    BAHeadphonesJackOutMask = 1 << 6
};

// Defines
#define APP_WORKING_ROW 0
#define APP_BROKEN_ROW 1

#define BASE_FADE_IN_DELAY 10000

#define HEADPHONES_MODE 0
#define NORMAL_MODE 1

#define MUTE 0
#define UNMUTE 1
#define HEADPHONES_IN 2
#define HEADPHONES_OUT 3

#define WINDOW_TITLE_HEIGHT 78
