//
//  PCScrubber.h
//  IOSurfaceTest
//
//  Created by Patrick Cusack on 4/29/15.
//  Copyright (c) 2015 Paolo Manna. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PCScrubberProxy <NSObject>
- (void)setRate:(id)sender;
@end

@protocol PCScrubberCellProxy <NSObject>
- (void)mouseWasUnclicked;
- (void)markCurrentRate:(float)nValue;
@end

@interface PCScrubberCell : NSSliderCell{
    id <PCScrubberCellProxy> parent;
}

@property (nonatomic, assign) id <PCScrubberCellProxy> parent;

@end

@interface PCScrubber : NSSlider <PCScrubberCellProxy> {
    id <PCScrubberProxy> delegate;
}

@property (nonatomic, assign) id <PCScrubberProxy> delegate;

@end
