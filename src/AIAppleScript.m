//
//  AIAppleScript.m
//  Breakaway
//
//  Created by Kevin Nygaard on 5/19/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#import "AIAppleScript.h"


@implementation AIAppleScript

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    [self prepareForEditing];
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    [self prepareForEditing];
}

- (void)prepareForEditing
{
    [self addObserver:self forKeyPath:@"scriptPath" options:0 context:nil];
    [self setupAndCompileScript];
}

- (void)prepareForDeletion
{
    if ([self valueForKey:@"applescript"]) [[self valueForKey:@"applescript"] release];
    [self removeObserver:self forKeyPath:@"scriptPath"];
}

- (void)setupAndCompileScript
{
    NSAppleScript *script = nil;
    NSDictionary *errorInfo = [NSDictionary dictionary];
    NSString *scriptPath = nil;
    
    script = [self valueForKey:@"applescript"];
    if (script) [script release];
    
    scriptPath = [self valueForKey:@"scriptPath"];
    
    // Can't do much good without a string
    if (!scriptPath) return;
    scriptPath = [[NSString stringWithString:scriptPath] stringByExpandingTildeInPath];
    
    // If we have a bad path
	if(![[NSFileManager defaultManager] fileExistsAtPath:scriptPath])
    {
        [self setValue:FALSE forKey:@"enabled"];
        return;
    }
    
    script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorInfo];
    // Had issues generating script
    if ([errorInfo count])
    {
        NSAlert *alert = [NSAlert init];
        [alert setMessageText:[errorInfo description]];
        [alert runModal];
        script = nil;
        return;
    }
    
    [script performSelectorOnMainThread:@selector(compileAndReturnError:) withObject:nil waitUntilDone:YES];
    
    if ([errorInfo count])
    {
        NSAlert *alert = [NSAlert init];
        [alert setMessageText:[errorInfo description]];
        [alert runModal];
        [script release];
    }
    [self setValue:script forKey:@"applescript"];
}

- (BOOL)enabled
{
    return ([self valueForKey:@"applescript"]) ? [[self primitiveValueForKey:@"enabled"] boolValue] : FALSE;
}

- (void)activate:(kTriggerMask)triggerMask
{
    BOOL jConnect, muteOn, headphonesTrigger;
    
    jConnect = triggerMask & kTriggerJackStatus;
    muteOn = triggerMask & kTriggerMute;
    headphonesTrigger = triggerMask & kTriggerInt; // TRUE for headphones trigger, FALSE for mute trigger
    
    // What are we triggering off (headphones/mute)?
    // Based on that result, what is the jack/mute status respectively?
    // Based on that result, do we care?
    // Activate if we do, do nothing if we don't
    if ([(headphonesTrigger ?
          (jConnect ? [self valueForKey:@"plugged"] : [self valueForKey:@"unplugged"]) :
          (muteOn ? [self valueForKey:@"mute"] : [self valueForKey:@"unmute"])) boolValue])
    {
        [[self valueForKey:@"applescript"] performSelectorOnMainThread:@selector(executeAndReturnError:) withObject:nil waitUntilDone:NO];
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"scriptPath"])
    {
        [self setupAndCompileScript];
    }
}

@end
