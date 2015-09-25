//
//  ImageHelper.cpp
//  demoPC
//
//  Created by Patrick Cusack on 10/24/12.
//  Copyright (c) 2012 Personal. All rights reserved.
//


#include "ImageHelper.h"
#include "GL/glew.h"
#include <Cocoa/Cocoa.h>
#include <CoreVideo/CoreVideo.h>

char * createDataForImage(const char * s, int * width, int * height, int * components, int * eformat){
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithCString:s encoding:NSASCIIStringEncoding]];
    
    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    
    *height = [image size].height;
    *width = [image size].width;    
    
    //this is not robust
    *components = 1;
    *eformat = 1;
    
    if ([rep samplesPerPixel] == 3) {
        *components = GL_RGB;
        *eformat = GL_RGB;
    } else if ([rep samplesPerPixel] == 4 && [rep hasAlpha]){
        *components = GL_RGBA;
        *eformat = GL_RGBA;
    }
    
    
    char * returnPtr = (char*)malloc([rep numberOfPlanes] * [rep bytesPerPlane]);
    memcpy(returnPtr, [rep bitmapData], [rep numberOfPlanes] * [rep bytesPerPlane]);
    
    [image release];
    
    return returnPtr;
}

char * createImageDataForRoundedRect(int width, int height, float radius, int * components, int * eformat){
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    
    [image lockFocus];
    [[NSColor redColor] set];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, width, height)] fill];
    [[NSColor blueColor] set];
    [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, width, height) 
                                    xRadius:radius 
                                    yRadius:radius] fill];
    
    [image unlockFocus];
    
    
    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    
    height = [image size].height;
    width = [image size].width;    
    
    //this is not robust
    *components = 1;
    *eformat = 1;
    
    if ([rep samplesPerPixel] == 3) {
        *components = GL_RGB;
        *eformat = GL_RGB;
    } else if ([rep samplesPerPixel] == 4 && [rep hasAlpha]){
        *components = GL_RGBA;
        *eformat = GL_RGBA;
    }
    
    char * returnPtr = (char*)malloc([rep numberOfPlanes] * [rep bytesPerPlane]);
    memcpy(returnPtr, [rep bitmapData], [rep numberOfPlanes] * [rep bytesPerPlane]);
    
    [image release];
    
    return returnPtr;
}


char * pathForImage(const char *imageName)
{
    NSString *imageNameStr = [NSString stringWithCString:imageName encoding:NSUTF8StringEncoding];
    
    NSString *baseImageName = [imageNameStr stringByDeletingPathExtension];
    NSString *imageExtension = [imageNameStr pathExtension];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:baseImageName ofType:imageExtension];
    
    char *cPath = (char*)[path UTF8String];
    
    NSLog(@"Path for %@", path);
    
    return cPath;
}

char * pathForResource(const char *resourceName)
{
    NSString *imageNameStr = [NSString stringWithCString:resourceName encoding:NSUTF8StringEncoding];
    
    NSString *baseImageName = [imageNameStr stringByDeletingPathExtension];
    NSString *imageExtension = [imageNameStr pathExtension];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:baseImageName ofType:imageExtension];
    
    char *cPath = (char*)[path UTF8String];
    
    NSLog(@"Path for %@", path);
    
    return cPath;
}

/*
 
 */