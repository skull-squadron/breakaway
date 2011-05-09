//
//  NSTextFieldCell+VertCentering.m
//  Breakaway
//
//  Created by Kevin Nygaard on 5/8/11.
//  Copyright 2011 MutableCode. All rights reserved.
//

#import "NSTextFieldCell+VertCentering.h"

// from http://stackoverflow.com/questions/1235219/is-there-a-right-way-to-have-nstextfieldcell-draw-vertically-centered-text
@implementation NSTextFieldCell (VertCentering)
- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y = theRect.origin.y + (theRect.size.height - titleSize.height) / 2.0;
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}
@end
