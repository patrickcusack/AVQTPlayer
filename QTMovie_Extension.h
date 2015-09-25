#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface QTMovie (QTMovie_Extension)
- (QTTrack *)firstVideoTrack;
- (void)updateMovieTimeScaleToMatchFirstVideTrackTimeScale;
@end
