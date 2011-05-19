//
//  AIiTunesPlugin.h
//  Breakaway
//
//  Created by Kevin Nygaard on 4/30/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#ifndef __AIITUNESPLUGIN_H__
#define __AIITUNESPLUGIN_H__

#import <Cocoa/Cocoa.h>
#import "AIPluginProtocol.h"

@class iTunesApplication;
@class AppController;


@interface AIiTunesPlugin : NSObject <AIPluginProtocol> {

    BOOL enabled;

    BOOL inFadeIn;
    BOOL isPlaying;
    BOOL isActive;

    BOOL hpMode;

    iTunesApplication *iTunes;
	AppController *appController;
    
    IBOutlet NSView *prefView;
}
@property (assign) BOOL enabled;

- (void)dealloc;
// iTunes Observers
- (void)loadObservers;
- (void)removeObservers;
- (void)songChanged:(NSNotification *)aNotification ;
- (void)handleAppLaunch:(NSNotification *)notification;
- (void)handleAppQuit:(NSNotification *)notification;
// iTunes Control
- (BOOL)iTunesActive;
- (BOOL)iTunesPlaying;
- (void)iTunesPlayPause;
- (void)fadeInUsingTimer:(NSTimer*)timer;
- (void)iTunesThreadedFadeIn;
- (IBAction)testFadeIn:(id)sender;

@end

#endif /* __AIITUNESPLUGIN_H__ */

