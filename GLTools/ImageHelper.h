//
//  ImageHelper.h
//  demoPC
//
//  Created by Patrick Cusack on 10/24/12.
//  Copyright (c) 2012 Personal. All rights reserved.
//

#ifndef demoPC_ImageHelper_h
#define demoPC_ImageHelper_h


char * createDataForImage(const char * s, int * width, int * height, int * components, int * eformat);
char * createImageDataForRoundedRect(int width, int height, float radius, int * components, int * eformat);
char * pathForImage(const char *imageName);
char * pathForResource(const char *resourceName);

#endif
