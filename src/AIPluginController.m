//
//  AIPluginController.m
//  Breakaway
//
//  Created by Kevin Nygaard on 5/8/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#import "AIPluginController.h"
#import "GrowlNotifier.h"
#import "AIPluginProtocol.h"

@implementation AIPluginController

@synthesize pluginInstances;

/******************************************************************************
 * init
 *
 * Sets up environment variables
 *****************************************************************************/
- (id)init
{
	if (!(self = [super init])) return nil;
        
	// Setting up these for plugin stuff
	pluginInstances = [[NSMutableArray alloc] init];
    
    // load all our bundles, init them, and put them in pluginInstances
	[self loadAllBundles];
    
    // tell growl we are good to go
    [GrowlApplicationBridge setGrowlDelegate:breakaway.growlNotifier];
    
    return self;
}

#pragma mark 
#pragma mark Plugin Loading

/******************************************************************************
 * loadAllBundles
 *
 * Finds and loads all plugins and instantiates them
 * The instantiated plugin objects are held in an mutable array instance variable
 * In addition, it configures the growl notification dictionary, should the
 * plugin choose to use growl notifications
 *****************************************************************************/
- (void)loadAllBundles
{                                        
    NSDictionary *previousDict = nil;
    NSMutableArray *acceptedNotesAdditions = nil;
    NSMutableArray *defaultNotesAdditions = nil;
    NSBundle *curBundle;
    Class curPrincipalClass;
    id curInstance;
    
    for (NSString *curPath in [self allBundles])
    {
        curBundle = [NSBundle bundleWithPath:curPath];               
        if (!curBundle) continue;
        [curBundle load];
        
        curPrincipalClass = [curBundle principalClass];
        if (!curPrincipalClass 
            || ![curPrincipalClass conformsToProtocol:@protocol(AIPluginProtocol)] 
            || ![curPrincipalClass initializeClass:curBundle]) continue;
        
        curInstance = [[curPrincipalClass alloc] initWithController:breakaway]; 
        if (!curInstance) continue;
        
        // Prepare growl data
        if ([curInstance respondsToSelector:@selector(acceptedGrowlNotes)] && [curInstance respondsToSelector:@selector(defaultGrowlNotes)])
        {
            if (!acceptedNotesAdditions) acceptedNotesAdditions = [NSMutableArray array];
            if (!defaultNotesAdditions) defaultNotesAdditions = [NSMutableArray array];
            [acceptedNotesAdditions addObjectsFromArray: [curInstance acceptedGrowlNotes]];
            [defaultNotesAdditions addObjectsFromArray: [curInstance defaultGrowlNotes]];
        }
        
        [pluginInstances addObject:[curInstance autorelease]];
    }
    
    // We are done if we don't have any notifications definitions to add
    if (!(acceptedNotesAdditions && defaultNotesAdditions && ([acceptedNotesAdditions count] || [defaultNotesAdditions count]))) return;
    
    // update growl dictionary
    previousDict = breakaway.growlNotifier.registrationDictionaryForGrowl;
	breakaway.growlNotifier.registrationDictionaryForGrowl = [NSDictionary dictionaryWithObjectsAndKeys:
                                                              [[previousDict objectForKey:GROWL_NOTIFICATIONS_ALL] arrayByAddingObjectsFromArray: acceptedNotesAdditions], GROWL_NOTIFICATIONS_ALL,
                                                              [[previousDict objectForKey:GROWL_NOTIFICATIONS_DEFAULT] arrayByAddingObjectsFromArray: defaultNotesAdditions], GROWL_NOTIFICATIONS_DEFAULT,
                                                              @"Breakaway", GROWL_APP_NAME,
                                                              [NSNumber numberWithInt:1], GROWL_TICKET_VERSION,
                                                              nil];
}

/******************************************************************************
 * allBundles
 *
 * Returns an array with paths you want to search for bundles (pluigns)
 * Currently, this only searches the builtInPlugins path for simplicity
 *****************************************************************************/
- (NSMutableArray*)allBundles
{
    NSMutableArray *allBundles = [NSMutableArray array];
    NSString *curPath = [[NSBundle mainBundle] builtInPlugInsPath];
    
    for (NSString *curBundlePath in [[NSFileManager defaultManager] enumeratorAtPath:curPath])
    {
        if([[curBundlePath pathExtension] isEqualToString:@"plugin"])
            [allBundles addObject:[curPath stringByAppendingPathComponent:curBundlePath]];
    }
    
    return allBundles;
}

#pragma mark 
#pragma mark Plugin Management
/******************************************************************************
 * executeTriggers:
 *
 * When a trigger occurs (AHPropertyListenerProc), this function is called,
 * sending the activate message to all instantiated plugins
 *****************************************************************************/
- (void)executeTriggers:(kTriggerMask)triggerMask
{	
    // FIXME: Potentially dangerous passing the second param like that? But it works though...
    [pluginInstances makeObjectsPerformSelector:@selector(activate:) withObject:(id)triggerMask];
}

@end
