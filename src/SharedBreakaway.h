//
//  SharedBreakaway.h
//  Breakaway
//
//  Created by Kevin Nygaard on 5/7/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

// Modeled after `AISharedAdium.h' from OSX Adium chat client

#import <Cocoa/Cocoa.h>	

@class AppController;

extern AppController *breakaway;

void setSharedBreakaway(AppController *shared);