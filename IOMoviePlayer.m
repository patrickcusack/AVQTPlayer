//
//  IOMoviePlayer.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/26/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "IOMoviePlayer.h"
#import "ADRToolBoxLogger.h"

@interface IOMoviePlayer(){
    NSString *inputRemainder;
    BOOL _moviePlaying;
}

@property (nonatomic, readwrite, retain) NSString *inputRemainder;

@end

@implementation IOMoviePlayer
@synthesize movieProxy;
@synthesize surfaceLayer;
@synthesize movieSizeForView;
@synthesize inputRemainder;
@synthesize helperIsReady;
@synthesize maxTimeValue;
@synthesize nextInterestingDuration;
@synthesize nominalFrameRate;
@synthesize isPlaying;

+ (NSString*)uuid{
    CFUUIDRef uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString *uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return [uuidString autorelease];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _moviePlaying = NO;
        [self setInputRemainder:@""];
        [self setHelperIsReady:NO];
        [self setIsPlaying:NO];
        
        [self setMaxTimeValue:0];
        [self setNextInterestingDuration:0];
        [self setNominalFrameRate:0.0];
    }
    return self;
}

- (void)dealloc{
    [ADRToolBoxLogger addString:[NSString stringWithFormat:@"%@ %@", [self class], NSStringFromSelector(_cmd)]];
    
    [self setInputRemainder:nil];
    
    @try {
        [[self movieProxy] quitHelperTool];
    }
    @catch (NSException *exception) {
        [ADRToolBoxLogger addString:@"LogToFile [[self movieProxy] quitHelperTool] exception"];
    }
    
    [moviePlayer stopProcess];

    
    [self setMovieProxy:nil];
    [super dealloc];
}

- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL withCallBack:(PCMovieReadyToPlayBlock)callback{
    [[self movieProxy] addAudioFileToCurrentMovie:audioURL];
    
    NSTimeInterval countdown = 5.0;
    
    while ([[self movieProxy] audioHasLoaded] == NO) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        countdown -= 0.2;
        
        if (countdown <= 0.0) {
            callback(NO);
            return;
        }
    }
    
    [self getMovieInfo];
    
    callback(YES);
}

- (void)loadMovieFileWithURL:(NSURL*)url withReadyBlock:(PCMovieReadyToPlayBlock)block{
    [[self movieProxy] addMovieURL:url];
    
    __block IOMoviePlayer * weakSelf = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0UL), ^{
        
        NSInteger microseconds = 5 * 1000000;
        while ([[weakSelf movieProxy] hasMovie] == NO) {
            usleep(200000);
            microseconds -= 200000;
            
            if (microseconds <= 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(NO);
                });
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf getMovieInfo];
            block(YES);
        });
        
    });
    
//    NSTimeInterval countdown = 5.0;
//    while ([[self movieProxy] hasMovie] == NO) {
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
//        countdown -= 0.2;
//        
//        if (countdown <= 0.0) {
//            block(NO);
//            return;
//        }
//    }
//    
//    [self getMovieInfo];
//
//    block(YES);
}

- (NSString*)proxyMoviePath{
    if ([[self movieProxy] hasMovie]) {
        return [[self movieProxy] proxyMoviePath];
    }
    return nil;
}

- (void)getMovieInfo{
    if ([[self movieProxy] hasMovie]) {
        [self setMovieSizeForView:[[[self movieProxy] movieSize] sizeValue]];
        [[self surfaceLayer] setMovieSize:[self movieSizeForView]];
        [self setMaxTimeValue:[[self movieProxy] maxTimeValue]];
        [self setNextInterestingDuration:[[self movieProxy] nextInterestingDuration]];
        [self setNominalFrameRate:[[self movieProxy] nominalFrameRate]];
    }
}

- (void)play{
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] setMovieRate:1.0];
        [self setIsPlaying:YES];
    }
}

- (void)pause{
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] setMovieRate:0.0];
        [self setIsPlaying:NO];
    }
}

- (oneway void)setMovieIsPlaying:(BOOL)flag{
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] setMovieIsPlaying:flag];
    }
}

- (void)goToBeginning{
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] goToBeginning];
    }
}

- (void)goToEnd{
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] goToEnd];
    }
}

- (void)stepForward{
    if ([[self movieProxy] hasMovie]) {
        if ([[self movieProxy] isMoviePlaying] == YES) {
            [(id <PCProxyProtocol>)[self movieProxy] pause];
        }
        [[self movieProxy] stepForward];
    }
}

- (void)stepBackward{
    if ([[self movieProxy] hasMovie]) {
        if ([[self movieProxy] isMoviePlaying] == YES) {
            [(id <PCProxyProtocol>)[self movieProxy] pause];
        }
        [[self movieProxy] stepBackward];
    }
}

- (void)goToPercentage:(float)percentage{
    if ([[self movieProxy] hasMovie]) {
        unsigned long long nTimeValue = [self maxTimeValue] * percentage;
        [[self movieProxy] goToTimeValue:nTimeValue];
    }
}

- (oneway void)goToTimeValue:(long)timeValue{
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] goToTimeValue:timeValue];
    }
}

- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart{
    
    long long currentTime = [[self movieProxy] currentTimeValue];
    long long duration = [[self movieProxy] maxTimeValue];
    long timeScale = [[self movieProxy] timeScale];
    
    float actualFrameRate = (1.0 * timeScale/[self nextInterestingDuration]);
    int effectiveFrameRate = ceil(actualFrameRate);
    unsigned long long totalFrames;
    
    long long newTime = currentTime;
    
    switch (effectiveFrameRate) {
        case 24:
            totalFrames = ([time unsignedLongLongValue] - [pictureStart unsignedLongLongValue]) / 2000;
            break;
        case 25:
            totalFrames = ([time unsignedLongLongValue] - [pictureStart unsignedLongLongValue]) / 1920;
            break;
        default:
            totalFrames = ([time unsignedLongLongValue] - [pictureStart unsignedLongLongValue]) / 1600;
    }
    
    
    newTime = totalFrames * [self nextInterestingDuration];
    
    if(newTime > duration){newTime = duration;}
    
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] goToTimeValue:newTime];
    }
}

- (unsigned long long)getTime{
    
    long timeScale = [[self movieProxy] timeScale];
    float actualFrameRate = (1.0 * timeScale/[self nextInterestingDuration]);
    int effectiveFrameRate = ceil(actualFrameRate);

    switch (effectiveFrameRate) {
        case 24:
            return [self currentFrame] * 2000;
            break;
        case 25:
            return [self currentFrame] * 1920;
            break;
        default:
            return [self currentFrame] * 1600;
    }
    
    return 0;
}

- (oneway void)setMovieRate:(float)nRate{
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] setMovieRate:nRate];
    }
}

- (void)goToFrame:(NSNumber*)frameNumber{
    if ([[self movieProxy]hasMovie]) {
        [[self movieProxy] goToTimeValue:[frameNumber integerValue] * [self nextInterestingDuration]];
    }
}

- (unsigned long long)currentTimeValue{
    if ([[self movieProxy] hasMovie]) {
        return [[self movieProxy] currentTimeValue];
    }
    
    return 0;
}

- (NSString*)currenTimeInfo{
    
    if ([self nextInterestingDuration] == 0) {
        [self setNextInterestingDuration:1];
    }
    
    int frames = (int)[self currentTimeValue] / (int)[self nextInterestingDuration];
    return [NSString stringWithFormat:@"%d %llu %llu %d %f", frames, [self currentTimeValue], [self maxTimeValue], (int)[self nextInterestingDuration], [self nominalFrameRate]];
}

- (NSUInteger)currentFrame{
    
    NSUInteger nInterestingDuration = [self nextInterestingDuration];
    if (nInterestingDuration == 0) {
        nInterestingDuration = 1;
    }
    
    return (int)[self currentTimeValue] / nInterestingDuration;
}

#pragma mark -
#pragma mark Command Line Helper
#pragma mark -

- (void)launchHelper{
    
    NSString	*cliPath	= [[NSBundle mainBundle] pathForResource: @"IOSurfaceCLI" ofType: @""];
    NSString    *taskUUIDForDOServer = [IOMoviePlayer uuid];
    
    if (!cliPath || !taskUUIDForDOServer) {
        NSLog(@"Error");
    }
    
    NSArray *args = [NSArray arrayWithObjects:cliPath,taskUUIDForDOServer, nil];
    
    moviePlayer = [[TaskWrapper alloc] initWithController:self arguments:args userInfo:nil];
    
    if (moviePlayer){
        [moviePlayer startProcess];
    }  else {
        NSLog(@"Error: Can't launch %@!", cliPath);
    }
    
    NSConnection * taskConnection = nil;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    while(taskConnection == nil){
        taskConnection = [NSConnection connectionWithRegisteredName:[NSString stringWithFormat:@"info.proxyplayer.movierenderer-%@", taskUUIDForDOServer, nil] host:nil];
    }
    
    // now that we have a valid connection...
    // movieProxy = [[taskConnection rootProxy] retain];
    [self setMovieProxy:[taskConnection rootProxy]];
    
    if(taskConnection == nil || movieProxy == nil){
        [moviePlayer stopProcess];
        moviePlayer = nil;
    }
    
    //[self movieProxy]
    [(NSDistantObject*)movieProxy setProtocolForProxy:@protocol(PCProxyProtocol)];
}

- (void)launchHelperAsyncWithCallback:(PCMovieReadyToPlayBlock)block{
    
    NSString	*cliPath	= [[NSBundle mainBundle] pathForResource: @"IOSurfaceCLI" ofType: @""];
    NSString    *taskUUIDForDOServer = [IOMoviePlayer uuid];
    
    if (!cliPath || !taskUUIDForDOServer) {
        [self setHelperIsReady:NO];
        block(NO);
        return;
    }
    
    NSArray *args = [NSArray arrayWithObjects:cliPath,taskUUIDForDOServer, nil];
    
    moviePlayer = [[TaskWrapper alloc] initWithController:self arguments:args userInfo:nil];
    
    if (moviePlayer){
        [moviePlayer startProcess];
    }  else {
        [self setHelperIsReady:NO];
        block(NO);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0UL), ^{
        
        NSConnection * taskConnection = nil;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        while(taskConnection == nil){
            taskConnection = [NSConnection connectionWithRegisteredName:[NSString stringWithFormat:@"info.proxyplayer.movierenderer-%@", taskUUIDForDOServer, nil] host:nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // now that we have a valid connection...
            [self setMovieProxy:[taskConnection rootProxy]];
            
            if(taskConnection == nil || movieProxy == nil){
                [moviePlayer stopProcess];
                moviePlayer = nil;
                [self setHelperIsReady:NO];
                block(NO);
                return;
            }
            
            //[self movieProxy]
            [(NSDistantObject*)movieProxy setProtocolForProxy:@protocol(PCProxyProtocol)];
            [self setHelperIsReady:YES];
            
            block(YES);
        });
        
    });

}

- (void)appendOutput:(NSString *)output fromProcess: (TaskWrapper *)aTask {
    
    NSArray			*outComps	= [[[self inputRemainder] stringByAppendingString: output] componentsSeparatedByString: @"\n"];
    NSEnumerator	*enumCmds	= [outComps objectEnumerator];
    NSString		*cmdStr;
    
    while ((cmdStr = [enumCmds nextObject]) != nil) {
        if (([cmdStr length] > 3) && [[cmdStr substringToIndex: 3] isEqualToString: @"ID#"]) {
            long surfaceID = 0;
            sscanf([cmdStr UTF8String], "ID#%ld#", &surfaceID);
            if (surfaceID) {
                [[self surfaceLayer] setSurfaceID: (IOSurfaceID)surfaceID];
                [[self surfaceLayer] setNeedsDisplay];
            }
        
        }
    }
    
    cmdStr	= [outComps lastObject];
    if (([cmdStr length] > 0) && ([cmdStr characterAtIndex: [cmdStr length] - 1] != '#')) {
        [self setInputRemainder:cmdStr];
    }
}

- (void)processStarted: (TaskWrapper *)aTask{
    _moviePlaying	= YES;
}

- (void)processFinished: (TaskWrapper *)aTask withStatus: (int)statusCode{
    _moviePlaying	= NO;
    
    [moviePlayer setController:nil];
    [moviePlayer autorelease];
    moviePlayer		= nil;
}


@end
