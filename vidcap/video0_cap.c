/*
 *  video0_cap.c
 *
 *  DESCRIPTION:
 *
 *  This code implements V4L2 video capture from /dev/video0, designed for
 *  Nintendo Famicom Mini with HDMI output. This code uses Lua FFI to
 *  interface with Torch 7 code. It assumes input video to be 1280x720p60
 *  in UYVY format and converts video frame to 640x360p30 in grayscale.
 *
 *  PROCESS:
 *
 *  GLOBALS:
 *
 *  REFERENCE:
 *
 *  LIMITATIONS:
 *
 *  REVISION HISTORY:
 *
 *    Date             Description                                   Author
 *    2017-02-06       initial coding                                jkjung
 *
 *  TARGET: Linux C
 *
 */

#include <stdlib.h>
#include "device.h"

#if 0
int  vidcap_init();
void vidcap_get(unsigned char *ptrFromLua);
void vidcap_flush();
void vidcap_cleanup();
#endif /* 0 */

static void bye(void)
{
        device_stop_capturing();
        device_cleanup();
}

static void UYVY1280x720_to_GRAY640x360(const unsigned char *src, unsigned char *dst)
{
        int i, j, width = 640, height = 360;

        src += 1;  /* offset by 1 to get the 1st Y value (the byte preceding this Y is a U) */
        while (--height >= 0) {
                for (i = 0; i < width; i++) {
                        j = i * 4;  /* j = (i * 1280 / 640) * 2; */
                        *dst++ = (src[j] + src[j+2] + src[j+1280*2] + src[j+1280*2+2]) / 4;  /* take average of Y over 4 adjacent pixels */
                }
                src += 1280*2 * 2;  /* stride 2 lines, 1280*2 bytes per line */
        }
}

int vidcap_init()
{
        atexit(bye);
        if (device_initialize("/dev/video0", 1280, 720, "UYVY") < 0)
                return -1;
        if (device_start_capturing() < 0)
                return -1;
        return 0;
}

/* Get 1 video frame (grayscale 640x360) */
void vidcap_get(unsigned char *ptrFromLua)
{
        void *p;

        p = device_get_next_frame(100000);  /* timeout = 0.1 second */
        if (NULL == p)  return;  /* abort here if get image data fails */
        device_free_frame(p);    /* otherwise drop 1 frame (intentionally) */

        p = device_get_next_frame(100000);  /* timeout = 0.1 second */
        if (NULL == p)  return;  /* abort if fail, no data is written to Lua */
        UYVY1280x720_to_GRAY640x360((const unsigned char *) p, ptrFromLua);
        device_free_frame(p);
}

/*
 * Flush old video frames (so that the immediate subsequent vidcap_get()
 * call would get the latest video frame, without too much latency)
 */
void vidcap_flush()
{
        int i;

        /*
         * read and discard up to 32 frames (since the V4L2 device driver
         * might buffer up to this many frames)
         */
        for (i = 0; i < 32; i++) {
                void *p = device_get_next_frame(1000);
                if (NULL == p)  break;  /* Fail to get image data */
                device_free_frame(p);
        }
}

void vidcap_cleanup()
{
        bye();
}
