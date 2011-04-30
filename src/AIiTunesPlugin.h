//
//  AIiTunesPlugin.h
//  Breakaway
//
//  Created by Kevin Nygaard on 4/30/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "AIPluginProtocol.h"
@class iTunesApplication;



@interface AIiTunesPlugin : NSObject<AIPluginProtocol, GrowlApplicationBridgeDelegate> {

    BOOL enabled;

    BOOL inFadeIn;
    BOOL isPlaying;
    BOOL isActive;

    BOOL hpMode;
    BOOL appHit;

    iTunesApplication *iTunes;
	NSUserDefaults *userDefaults;

}
@property (assign) BOOL enabled;

- (void)loadObservers;
- (void)removeObservers;
- (void)songChanged:(NSNotification *)aNotification ;
- (BOOL)iTunesActive;
- (BOOL)iTunesPlaying;
- (void)iTunesPlayPause;
- (void)fadeInUsingTimer:(NSTimer*)timer;
- (void)iTunesThreadedFadeIn;


@end
