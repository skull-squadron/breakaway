//
//  AIDropWell.m
//  Breakaway
//
//  Created by Kevin Nygaard on 8/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AIDropWell.h"

#import "AIAppleScriptPlugin.h"
#import "AIPluginControllerProtocol.h"


@implementation AIDropWell

-(void)awakeFromNib
{
	//[self setDelegate:self];
	[self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	originalColor = [scriptField textColor];
}

#pragma mark Script Actions

- (IBAction)revealScript:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile: [[[[parentController arrayController] selectedObjects]objectAtIndex:0] script] inFileViewerRootedAtPath:nil];
}


#pragma mark Delegate Fns

#pragma mark Dragging
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
	if ( [[pboard types] containsObject:NSFilenamesPboardType] )
	{
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
        if (sourceDragMask & NSDragOperationLink)
		{
			int i;
			for (i=0;[files count]>i;i++)
			{
				[[[[parentController arrayController] selectedObjects]objectAtIndex:0] setScript:[files objectAtIndex:i]];
				
				if ([[[[parentController arrayController] selectedObjects]objectAtIndex:0]valid])
				{
					[scriptField setTextColor:[NSColor blackColor]];
				}
				else
				{
					[scriptField setTextColor:[NSColor redColor]];
				}
				
			}
			
        }
    }
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

@end
