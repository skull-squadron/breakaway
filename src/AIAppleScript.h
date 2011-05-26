//
//  AIAppleScript.h
//  Breakaway
//
//  Created by Kevin Nygaard on 5/19/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AITriggerMasks.h";


@interface AIAppleScript : NSManagedObject
{
}

- (void)activate:(kTriggerMask)triggerMask;
- (void)prepareForEditing;
- (void)setupAndCompileScript;

@end
