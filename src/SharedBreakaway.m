//
//  SharedBreakaway.m
//  Breakaway
//
//  Created by Kevin Nygaard on 5/7/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

// Modeled after `AISharedAdium.m' from OSX Adium chat client

#import "SharedBreakaway.h"

#import "DebugUtils.h"

AppController *breakaway = nil;

void setSharedBreakaway(AppController *shared)
{
    NSCAssert(breakaway == nil, @"Shared `breakaway' instance already set");
    NSCParameterAssert(shared != nil);
    breakaway = [shared retain];
    DEBUG_OUTPUT1(@"set shared breakway: %@", breakaway);
}
