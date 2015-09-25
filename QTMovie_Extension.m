#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "QTMovie_Extension.h"
#include <fcntl.h>

@implementation QTMovie (QTMovie_Extension)

-(QTTrack *)firstVideoTrack
{
	QTTrack *track = nil;
	NSEnumerator *enumerator = [[self tracks] objectEnumerator];
	while ((track = [enumerator nextObject]) != nil)
	{
		if ([track isEnabled])
		{
			QTMedia *media = [track media];
			NSString *mediaType;
			mediaType = [media attributeForKey:QTMediaTypeAttribute];
			if ([mediaType isEqualToString:QTMediaTypeVideo] || [mediaType isEqualToString:QTMediaTypeMPEG])
			{
				if ([media hasCharacteristic:QTMediaCharacteristicHasVideoFrameRate])
					break; // found first video track
			}
		}
	}
	
	return track;
}


- (void)updateMovieTimeScaleToMatchFirstVideTrackTimeScale{
    Movie myMovie = [self quickTimeMovie];
    Media myMedia = [[[self firstVideoTrack] media] quickTimeMedia];	
    SetMovieTimeScale(myMovie,GetMediaTimeScale(myMedia));
}

@end
