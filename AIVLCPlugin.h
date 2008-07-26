//
//  AIVLCPlugin.h
//  Breakaway
//
//  Created by Kevin Nygaard on 7/22/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIPluginInterface.h"

@interface AIVLCPlugin : NSObject<AITriggerPluginProtocol>
{
    IBOutlet id preferences;
	NSArrayController* arrayController;
	
	bool enabled;
	bool isPlaying;
	bool appHit;
	
	NSMutableString* currentStringValue;
	NSMutableArray* instancesArray;
}

-(void)playMusic;
-(void)pauseMusic;
-(BOOL)isPlaying;
@end
