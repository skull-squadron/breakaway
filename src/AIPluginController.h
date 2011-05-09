//
//  AIPluginController.h
//  Breakaway
//
//  Created by Kevin Nygaard on 5/8/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIPluginProtocol.h"

@interface AIPluginController : NSObject {

    // Plugins
	NSMutableArray *pluginInstances;		//	an array of all plug-in instances 
    
}

@property (copy) NSMutableArray *pluginInstances;

- (void)loadAllBundles;
- (NSMutableArray*)allBundles;
- (void)executeTriggers:(kTriggerMask)triggerMask;

@end
