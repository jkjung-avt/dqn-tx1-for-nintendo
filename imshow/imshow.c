/*
 *  imshow.c
 *
 *  DESCRIPTION:
 *
 *  This code encapsulates OpenCV's (2.4.x) cvShowImage with Lua FFI,
 *  so that Torch7 code could call this modele to display images/video.
 *
 *  PROCESS:
 *
 *  GLOBALS:
 *
 *  REFERENCE:
 *
 *  LIMITATIONS:
 *
 *  I only implemented displaying of 8UC1 (grayscale) images. But the
 *  code could be easily extended to also support 8UC3/8UC4 (RGB/YUV)
 *  images
 *
 *  REVISION HISTORY:
 *
 *    Date             Description                                   Author
 *    2017-03-11       initial coding                                jkjung
 *
 *  TARGET: Linux C
 *
 */

#include <stdlib.h>
#include <string.h>
#include "opencv/highgui.h"

static char imshow_name[128];

#if 0
int  imshow_init(const char *name, int len);
void imshow_display(unsigned char *buf, int w, int h);
void imshow_cleanup();
#endif /* 0 */

static void bye(void)
{
        cvDestroyAllWindows();
}

int imshow_init(const char *name, int len)
{
        atexit(bye);
        if (len > 127)  len = 127;
        strncpy(imshow_name, name, len);
        cvNamedWindow(imshow_name, CV_WINDOW_AUTOSIZE);
        return 0;
}

/* Display 1 image frame (grayscale) */
void imshow_display(unsigned char *buf, int w, int h)
{
        CvMat mat = cvMat(h, w, CV_8UC1, buf);
        cvShowImage(imshow_name, &mat);
        cvWaitKey(1);
}

void imshow_cleanup()
{
        bye();
}
