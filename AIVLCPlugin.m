//
//  AIVLCPlugin.m
//  Breakaway
//
//  Created by Kevin Nygaard on 7/22/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AIVLCPlugin.h"


@implementation AIVLCPlugin
#pragma mark Some Required Plugin Info

- (NSString*)pluginTypeName
{
	return @"VLC Plugin";
}

- (void)setName:(NSString*)var
{
}

- (NSString*)name
{
	return @"VLC Plugin";
}

- (BOOL)instantiate 
{
	return FALSE;
}

-(BOOL)enabled
{
	return enabled;
}

- (int)familyCode
{
	return 127;
}

- (NSArrayController*)arrayController
{
	return arrayController;
}

-(void)setEnabled:(bool)var
{
	enabled = var;
}

- (NSView*)preferenceView
{
	// link up your NSView in IB and return that outlet here. Breakaway handles loading your plugin nib for you
	return preferences;
}

#pragma mark 
-(id)init
{
	if (!(self = [super init])) return nil;
	
	// if our array, hasn't been made yet, make it and fill it up
	if (!instancesArray)
	{
		instancesArray = [[NSMutableArray alloc]init];
		arrayController = [[NSArrayController alloc]init];
		[instancesArray addObject:self];
		[arrayController setContent: instancesArray];
	}
	return self;
}

- (void)activate:(int)prototype
{	
	if (enabled)
	{
		
		if ([self isPlaying])
		{
			// mute/hout
			if(((prototype & 79)==prototype)) { [self pauseMusic]; appHit = 1;}
		}
		// unmute/hin
		else if(((prototype & 55)==prototype) && appHit) { [self pauseMusic]; appHit = 0;}
	}
}

-(void)playMusic
{
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/curl" arguments:[NSArray arrayWithObjects:@"http://localhost:8080/requests/status.xml?command=pl_play", nil]];
}

-(void)pauseMusic
{
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/curl" arguments:[NSArray arrayWithObjects:@"http://localhost:8080/requests/status.xml?command=pl_pause", nil]];
}

-(BOOL)isPlaying
{
	NSTask *statusTask = [[NSTask alloc]init];
	NSData *data;	
	NSArray *args = [NSArray arrayWithObjects:@"http://localhost:8080/requests/status.xml", nil];
	
	[statusTask setLaunchPath:@"/usr/bin/curl"];
	[statusTask setArguments: args];
	[statusTask setStandardOutput: [NSPipe pipe]];
	
	[statusTask launch];
	
	data = [[[statusTask standardOutput] fileHandleForReading] readDataToEndOfFile];
	
	NSXMLParser *parser = [[NSXMLParser alloc]initWithData:data];
	[parser setDelegate:self];
	[parser parse];
	
	return isPlaying;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ([elementName isEqualToString:@"state"]) {
		isPlaying = ([currentStringValue isEqualToString:@"\n  playing"])?1:0;
	}
	currentStringValue = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!currentStringValue) {
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    }
    [currentStringValue appendString:string];
}

@end
