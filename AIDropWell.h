//
//  AIDropWell.h
//  Breakaway
//
//  Created by Kevin Nygaard on 8/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIDropWell : NSImageView {
	IBOutlet id parentController;
	IBOutlet id scriptField;
	NSColor *originalColor;
}

@end
