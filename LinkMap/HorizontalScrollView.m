//
//  HorizontalScrollView.m
//  LinkMap
//
//  Created by YLCHUN on 2020/10/13.
//

#import "HorizontalScrollView.h"

@implementation HorizontalScrollView

- (void)scrollWheel:(NSEvent *)theEvent {
    [super scrollWheel:theEvent];
    if ([theEvent deltaY] != 0.0) {
        [[self nextResponder] scrollWheel:theEvent];
    }
}

@end
