/*
 * AIDropWell.m
 * Breakaway
 * Created by Kevin Nygaard on 8/8/08.
 * Copyright 2008 Kevin Nygaard.
 *
 * This file is part of Breakaway.
 *
 * Breakaway is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Breakaway is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Breakaway.  If not, see <http://www.gnu.org/licenses/>.
 */

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
					[self setImage: [[NSWorkspace sharedWorkspace] iconForFile:[files objectAtIndex:i]]];
				}
				else
				{
					[scriptField setTextColor:[NSColor redColor]];
					[self setImage:@"notfoundover.png"];
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

- (void)mouseDown:(NSEvent *)theEvent
{
	if ([[[[parentController arrayController] selectedObjects]objectAtIndex:0]valid]) [self revealScript:nil];
}

@end
