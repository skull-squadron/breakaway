/*
 * AITriggerTable.m
 * Breakaway
 * Created by Kevin Nygaard on 8/15/07.
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

#import "AITriggerTable.h"
#import "AITrigger.h"
#import "PreferenceHandler.h"

@implementation AITriggerTable

-(void)awakeFromNib
{
	[self setDelegate:self];
	
}

#pragma mark Delegate

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([self selectedRow] != -1)
	{
		id plugin = [[parentController pluginInstances]objectAtIndex:[self selectedRow]];
		[[parentController drawer] setContentView:[plugin preferenceView]];
	}
	else [[parentController drawer] setContentView:optionsDrawerView];
}

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
				[[[[parentController triggerArrayController] selectedObjects]objectAtIndex:0] setScript:[files objectAtIndex:i]];
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
