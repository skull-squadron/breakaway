//
//  AIToolbarItem.h
//  Breakaway
//
//  Created by Kevin Nygaard on 5/7/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIToolbarItem : NSToolbarItem {
    IBOutlet NSView *preferenceView;
}
@property (readonly) NSView *preferenceView;
@end
