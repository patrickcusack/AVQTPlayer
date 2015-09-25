//
//  PCOpenGLDiffController.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 7/1/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCOpenGLDiffController.h"
#import "PCOpenGLDiffPixelBuffer.h"
#import "PCPixelBufferConsumerProtocol.h"
#import "PCOpenGLScreen.h"
#import "PCOpenGLOpenCVScreen.h"

@interface PCOpenGLDiffController(){
    CATextLayer * infoDisplayLayer;
    id slider;
    id textField;
}

@property (nonatomic, retain, readwrite) CATextLayer * infoDisplayLayer;
@property (nonatomic, assign, readwrite) id slider;
@property (nonatomic, assign, readwrite) id textField;

@end

@implementation PCOpenGLDiffController
@synthesize layerA;
@synthesize layerB;
@synthesize diffLayer;
@synthesize infoDisplayLayer;
@synthesize useOpenCV;
@synthesize shouldSynchronize;
@synthesize slider;
@synthesize textField;


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setDiffLayer:[self layer]];
        [[self diffLayer] setDelegate:self];
        
        CATextLayer * nTextLayer = [self constructTextLayer];
        [self setInfoDisplayLayer:nTextLayer];
        [[self diffLayer] addSublayer:nTextLayer];
        [self setUseOpenCV:NO];
        [self setShouldSynchronize:NO];
    }
    return self;
}

- (PCOpenGLLayer*)layer{
    PCOpenGLLayer* nLayer = [[[PCOpenGLLayer alloc] init] autorelease];
    [nLayer setBounds:CGRectMake(0, 0, 100, 100)];
    return nLayer;
}

- (void)dealloc{
    if ([self slider]) { [[self slider] setTarget:nil];}
    
    [self setLayerA:nil];
    [self setLayerB:nil];
    [self setDiffLayer:nil];
    [super dealloc];
}

- (void)addPixelBuffer:(PCVideoTapStruct)bufferStruct fromObject:(id)nDelegate{
    

    if([self shouldSynchronize] == NO){
        
        if (nDelegate == [self layerA]) {
            [(id <PCPixelBufferConsumerProtocol>)[[self diffLayer] screen] setBufferA:[PCOpenGLDiffPixelBuffer bufferWithBufferStruct:bufferStruct]];
        } else if (nDelegate == [self layerB]){
            [(id <PCPixelBufferConsumerProtocol>)[[self diffLayer] screen] setBufferB:[PCOpenGLDiffPixelBuffer bufferWithBufferStruct:bufferStruct]];
        }
        
    } else {
        
        if (nDelegate == [self layerA]) {
            [(id <PCPixelBufferConsumerProtocol>)[[self diffLayer] screen] addBufferToBuffersA:[PCOpenGLDiffPixelBuffer bufferWithBufferStruct:bufferStruct]];
        } else if (nDelegate == [self layerB]){
            [(id <PCPixelBufferConsumerProtocol>)[[self diffLayer] screen] addBufferToBuffersB:[PCOpenGLDiffPixelBuffer bufferWithBufferStruct:bufferStruct]];
        }
        
    }
}

- (void)layerWillDrawInContextInLayer:(CALayer *)layer{
    if (![[self diffLayer] screen]) {
        [self buildScreen];
    }
}

- (void)buildScreen{
    if ([self useOpenCV] == YES) {
        PCOpenGLOpenCVScreen * nScreen =[[[PCOpenGLOpenCVScreen alloc] init] autorelease];
         [nScreen setDelegate:self];
        [[self diffLayer] setScreen:nScreen];
    } else {
        [[self diffLayer] setScreen:[[[PCOpenGLScreen alloc] init] autorelease]];
        [self drawCurrentInfo:@" "];
        [(PCOpenGLScreen*)[[self diffLayer] screen] setScaleDifferenceMultiplier:[[self slider] floatValue]];
    }
    
    if (shouldSynchronize == YES) {
        [(id <PCOpenGLScreenProviderProtocol>)[[self diffLayer] screen] setShouldSynchronize:shouldSynchronize];
    }
}

- (void)setShouldSynchronize:(BOOL)nShouldSynchronize{
    [(id <PCOpenGLScreenProviderProtocol>)[[self diffLayer] screen] setShouldSynchronize:nShouldSynchronize];
    shouldSynchronize = nShouldSynchronize;
}

- (void)setUseOpenCV:(BOOL)nUseOpenCV{
    useOpenCV = nUseOpenCV;
    [[self diffLayer] setScreen:nil]; //we have to make the screen nil, so that it will be redrawn in the next update
}

- (void)addDifferenceScaleSlider:(id)aSlider{
    
    if ([self slider]) {
        [[self slider] setTarget:nil];
    }
    
    [self setSlider:aSlider];
    [[self slider] setTarget:self];
    [[self slider] setAction:@selector(sliderChanged:)];
}

- (void)addDifferenceTextField:(id)nTexfield{
    textField = nTexfield;
}

- (IBAction)sliderChanged:(id)sender{
    if ([self useOpenCV] == NO) {
        [(PCOpenGLScreen*)[[self diffLayer] screen] setScaleDifferenceMultiplier:[sender floatValue]];
        [(NSTextField*)textField setStringValue:[NSString stringWithFormat:@"%0.3f", [[self slider] doubleValue]]];
    }
}

- (void)screenHasInfoAvailable:(NSString *)info{
    [self drawCurrentInfo:info];
}

- (void)setMovieSize:(NSSize)mSize{
    
}

- (void)drawCurrentInfo:(NSString*)timeString{
    
    if (timeString == nil) {
        timeString = @"99:99:99:99 9999+99";
    }
    
    [CATransaction begin];
    [self sizeTextLayer:[self infoDisplayLayer] forString:timeString];
    [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
    [[self infoDisplayLayer] setString:timeString];
    [CATransaction commit];
}

- (CATextLayer*)constructTextLayer{
    
    CGColorRef clearColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
    CGColorRef whiteColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    CGColorRef shadowColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0,1.0);
    CGColorRef redColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    CGColorRef blueColor = CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1.0);
    
    CATextLayer * nTextLayer = [CATextLayer layer];
    [nTextLayer setBackgroundColor:clearColor];
    [nTextLayer setForegroundColor:whiteColor];
    [nTextLayer setShadowColor:shadowColor];
    
    [nTextLayer setShadowOffset:CGSizeMake(1, 1)];
    [nTextLayer setShadowOpacity:1.0];
    [nTextLayer setPosition:CGPointMake(0, 0)];
    [nTextLayer setBounds:CGRectMake(0, 0, [[self diffLayer] bounds].size.width, 40)];
    [nTextLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
    [nTextLayer setContentsGravity:kCAGravityBottom];//kCAGravityBottomLeft
    [nTextLayer setAutoresizingMask: kCALayerWidthSizable];
    [nTextLayer setAlignmentMode:kCAAlignmentCenter];
    [nTextLayer setContentsScale:2.0];
    
    CFRelease(clearColor);
    CFRelease(whiteColor);
    CFRelease(shadowColor);
    CFRelease(redColor);
    CFRelease(blueColor);
    
    return nTextLayer;
}

- (void)sizeTextLayer:(CATextLayer*)nLayer forString:(NSString*)nString{
    
    NSSize size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:[nLayer fontSize]]}];
    CGFloat currentFontSize = [nLayer fontSize];
    
    if (size.width < ([nLayer bounds].size.width * 0.8)) {
        while (size.width < ([nLayer bounds].size.width * 0.8)) {
            currentFontSize += 1.0;
            size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:currentFontSize]}];
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
            [nLayer setFontSize:currentFontSize];
            [CATransaction commit];
        }
        
        return;
    }
    
    if (size.width > [nLayer bounds].size.width * 0.9) {
        while (size.width > [nLayer bounds].size.width * 0.9) {
            currentFontSize -= 1.0;
            size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:currentFontSize]}];
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
            [nLayer setFontSize:currentFontSize];
            [CATransaction commit];
        }
        
        return;
    }
    
}


@end
