/*
 *  device.c
 *
 *  DESCRIPTION:
 *
 *  This code is based on the following sample source code (unfortunately
 *  seems to be removed from the original web page):
 *
 *    https://linuxtv.org/downloads/v4l-dvb-apis/capture-example.html 
 *
 *  It initiatlizes the V4L2 device and captures video frame data from the
 *  device.
 *
 *  PROCESS:
 *
 *  int   device_initialize(char *devname, int width, int height, char *format);
 *  int   device_initialize_keep_format(char *devname);
 *  int   device_get_format(int *width, int *height, char *format);
 *  int   device_start_capturing();
 *  void *device_get_next_frame(int timeout_in_msec);
 *  void  device_free_frame(void *p);
 *  void  device_stop_capturing();
 *  extern void  device_cleanup();
 *
 *  Note: User must call device_free_frame() to return used frame pointer
 *  to this device module. Otherwisede the device stops working after all
 *  mmap buffers (usally 4~32 buffers depending on the V4L2 driver
 *  implementation) are used.
 *
 *  GLOBALS: none
 *
 *  REFERENCE: V4L2 specification, https://linuxtv.org/downloads/v4l-dvb-apis/
 *
 *  LIMITATIONS: (or TO-DO)
 *
 *  1. This device module can open only 1 V4L2 device at a time.
 *  2. Error-exits would be better replaced by error-returns. But then we'd
 *     need to define error codes and re-define the API fucntions.
 *  3. mmap buffer count is hard-coded as 4 here.
 *
 *  REVISION HISTORY:
 *
 *    Date             Description                                   Author
 *    2016-08-02       initial coding                                jkjung
 *    2016-08-10       added UYVY support                            jkjung
 *    2016-08-22       added keep-format support                     jkjung
 *    2016-08-23       fixed memcpy bug                              jkjung
 *    2016-08-26       added YUYV support                            jkjung
 *
 *  TARGET: Linux C
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <fcntl.h>              /* low-level i/o */
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include <linux/videodev2.h>

//#define DEBUG_DEVICE 1

#define CLEAR(x) memset(&(x), 0, sizeof(x))

enum io_method {
        IO_METHOD_READ,
        IO_METHOD_MMAP,
        IO_METHOD_USERPTR,
};

struct buffer {
        void   *start;
        size_t  length;
        struct v4l2_buffer v4l2buf;  /* saved context */
};

static char            *dev_name;
static enum io_method   io = IO_METHOD_MMAP;
static int              fd = -1;
struct buffer          *buffers;
static unsigned int     n_buffers;
static __u32            pix_width;
static __u32            pix_height;
static __u32            pix_format;
static enum v4l2_field  pix_field;

static void errno_exit(const char *s)
{
        fprintf(stderr, "%s error %d, %s\n", s, errno, strerror(errno));
        exit(EXIT_FAILURE);
}

static int xioctl(int fh, int request, void *arg)
{
        int r;

        do {
                r = ioctl(fh, request, arg);
        } while (-1 == r && EINTR == errno);

        return r;
}

static void *read_frame(void)
{
        struct v4l2_buffer buf;

        switch (io) {
        case IO_METHOD_MMAP:
                CLEAR(buf);
                buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                buf.memory = V4L2_MEMORY_MMAP;

                if (-1 == xioctl(fd, VIDIOC_DQBUF, &buf)) {
                        switch (errno) {
                        case EAGAIN:
                                return NULL;

                        case EIO:
                                /* Could ignore EIO, see spec. */

                                /* fall through */

                        default:
                                errno_exit("VIDIOC_DQBUF");
                        }
                }

                assert(buf.index < n_buffers);
                memcpy(&buffers[buf.index].v4l2buf, &buf, sizeof(struct v4l2_buffer));
                return (void *) buffers[buf.index].start;

        case IO_METHOD_READ:
        case IO_METHOD_USERPTR:
                /* Code removed */
                break;
        }
        return NULL;
}

static void free_frame(void *p)
{
        unsigned int i;

        switch (io) {
        case IO_METHOD_MMAP:
                for (i = 0; i < n_buffers; ++i)
                        if (p == buffers[i].start)
                                break;
                assert(i < n_buffers);
                if (-1 == xioctl(fd, VIDIOC_QBUF, &buffers[i].v4l2buf))
                        errno_exit("VIDIOC_QBUF");
                break;

        case IO_METHOD_READ:
        case IO_METHOD_USERPTR:
                /* Code removed */
                break;
        }
}

static void stop_capturing(void)
{
        enum v4l2_buf_type type;

        switch (io) {
        case IO_METHOD_MMAP:
                type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                if (-1 == xioctl(fd, VIDIOC_STREAMOFF, &type))
                        errno_exit("VIDIOC_STREAMOFF");
                break;

        case IO_METHOD_READ:
        case IO_METHOD_USERPTR:
                /* Code removed */
                break;
        }
}

static void init_mmap(void)
{
        struct v4l2_requestbuffers req;

        CLEAR(req);

        req.count = 4;
        req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        req.memory = V4L2_MEMORY_MMAP;

        if (-1 == xioctl(fd, VIDIOC_REQBUFS, &req)) {
                if (EINVAL == errno) {
                        fprintf(stderr, "%s does not support "
                                 "memory mapping\n", dev_name);
                        exit(EXIT_FAILURE);
                } else {
                        errno_exit("VIDIOC_REQBUFS");
                }
        }

        if (req.count < 2) {
                fprintf(stderr, "Insufficient buffer memory on %s\n",
                         dev_name);
                fprintf(stderr, "You probably need to manually set video width/height once "
                                "to get the device intto working state. For example,\n"
                                "  $ v4l2-ctl --device %s --set-fmt-video=width=%d,height=%d\n"
                                "  $ ./canny -d %s -x %d -y %d\n",
                                dev_name, pix_width, pix_height,
                                dev_name, pix_width, pix_height);
                exit(EXIT_FAILURE);
        }

        buffers = (struct buffer *) calloc(req.count, sizeof(*buffers));

        if (!buffers) {
                fprintf(stderr, "Out of memory\n");
                exit(EXIT_FAILURE);
        }

        for (n_buffers = 0; n_buffers < req.count; ++n_buffers) {
                struct v4l2_buffer buf;

                CLEAR(buf);

                buf.type        = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                buf.memory      = V4L2_MEMORY_MMAP;
                buf.index       = n_buffers;

                if (-1 == xioctl(fd, VIDIOC_QUERYBUF, &buf))
                        errno_exit("VIDIOC_QUERYBUF");

                buffers[n_buffers].length = buf.length;
                buffers[n_buffers].start =
                        mmap(NULL /* start anywhere */,
                              buf.length,
                              PROT_READ | PROT_WRITE /* required */,
                              MAP_SHARED /* recommended */,
                              fd, buf.m.offset);

                if (MAP_FAILED == buffers[n_buffers].start)
                        errno_exit("mmap");
        }
}

static int start_capturing(void)
{
        unsigned int i;
        enum v4l2_buf_type type;

        switch (io) {
        case IO_METHOD_MMAP:
                init_mmap();
                for (i = 0; i < n_buffers; ++i) {
                        struct v4l2_buffer buf;

                        CLEAR(buf);
                        buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                        buf.memory = V4L2_MEMORY_MMAP;
                        buf.index = i;

                        if (-1 == xioctl(fd, VIDIOC_QBUF, &buf)) {
                                fprintf(stderr, "%s error %d, %s\n", "VIDIOC_QBUF", errno, strerror(errno));
                                return -1;
                        }
                }
                type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                if (-1 == xioctl(fd, VIDIOC_STREAMON, &type)) {
                        fprintf(stderr, "%s error %d, %s\n", "VIDIOC_STREAMON", errno, strerror(errno));
                        return -1;
                }
                break;

        case IO_METHOD_READ:
        case IO_METHOD_USERPTR:
                /* Code removed */
                return -1;
        }
        return 0;
}

static void uninit_device(void)
{
        unsigned int i;

        switch (io) {
        case IO_METHOD_MMAP:
                for (i = 0; i < n_buffers; ++i)
                        if (-1 == munmap(buffers[i].start, buffers[i].length))
                                errno_exit("munmap");
                break;

        case IO_METHOD_READ:
        case IO_METHOD_USERPTR:
                /* Code removed */
                break;
        }

        free(buffers);
}

static int get_current_format()
{
        struct v4l2_format fmt;

        CLEAR(fmt);
        fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        if (-1 == xioctl(fd, VIDIOC_G_FMT, &fmt))
                errno_exit("VIDIOC_G_FMT");
        pix_width  = fmt.fmt.pix.width;
        pix_height = fmt.fmt.pix.height;
        pix_format = fmt.fmt.pix.pixelformat;
#ifdef DEBUG_DEVICE
        printf("get_format(): width=%d, height=%d, format=0x%x\n",
                pix_width, pix_height, pix_format);
#endif /* DEBUG_DEVICE */
        return 0;
}

static int init_device(int do_setfmt)
{
        struct v4l2_capability cap;
        struct v4l2_cropcap cropcap;
        struct v4l2_crop crop;
        struct v4l2_format fmt;
        unsigned int min;

        if (-1 == xioctl(fd, VIDIOC_QUERYCAP, &cap)) {
                if (EINVAL == errno) {
                        fprintf(stderr, "%s is no V4L2 device\n",
                                 dev_name);
                        exit(EXIT_FAILURE);
                } else {
                        errno_exit("VIDIOC_QUERYCAP");
                }
        }

        if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
                fprintf(stderr, "%s is no video capture device\n",
                         dev_name);
                exit(EXIT_FAILURE);
        }

        switch (io) {
        case IO_METHOD_MMAP:
                if (!(cap.capabilities & V4L2_CAP_STREAMING)) {
                        fprintf(stderr, "%s does not support streaming i/o\n",
                                 dev_name);
                        exit(EXIT_FAILURE);
                }
                break;

        case IO_METHOD_READ:
        case IO_METHOD_USERPTR:
                fprintf(stderr, "IO READ/USERPTR is not supported\n");
                exit(EXIT_FAILURE);
        }

        /*
         * Select video input, video standard and tune here.
         */

        CLEAR(cropcap);

        cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

        if (0 == xioctl(fd, VIDIOC_CROPCAP, &cropcap)) {
                crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                crop.c = cropcap.defrect; /* reset to default */

                if (-1 == xioctl(fd, VIDIOC_S_CROP, &crop)) {
                        switch (errno) {
                        case EINVAL:
                                /* Cropping not supported. */
                                break;
                        default:
                                /* Errors ignored. */
                                break;
                        }
                }
        } else {
                /* Errors ignored. */
        }

        if (do_setfmt) {
                CLEAR(fmt);

                fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                fmt.fmt.pix.width       = pix_width;
                fmt.fmt.pix.height      = pix_height;
                fmt.fmt.pix.pixelformat = pix_format;
                fmt.fmt.pix.field       = pix_field;
                /* Note VIDIOC_S_FMT may change width and height. */
                if (-1 == xioctl(fd, VIDIOC_S_FMT, &fmt))
                        errno_exit("VIDIOC_S_FMT");

                if (fmt.fmt.pix.width != pix_width || fmt.fmt.pix.height != pix_height) {
                        fprintf(stderr, "%s insists width=%d, height=%d!\n",
                                dev_name, fmt.fmt.pix.width, fmt.fmt.pix.height);
                        return -1;
                }

                /* Buggy driver paranoia. */
                min = fmt.fmt.pix.width * 2;
                if (fmt.fmt.pix.bytesperline < min)
                        fmt.fmt.pix.bytesperline = min;
                min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
                if (fmt.fmt.pix.sizeimage < min)
                fmt.fmt.pix.sizeimage = min;
        }

        switch (io) {
        case IO_METHOD_MMAP:

                break;

        case IO_METHOD_READ:
        case IO_METHOD_USERPTR:
                /* Code removed */
                break;
        }
        return 0;
}

static void close_device(void)
{
        if (-1 == close(fd))
                errno_exit("close");

        fd = -1;
}

static void open_device(void)
{
        struct stat st;

        if (-1 == stat(dev_name, &st)) {
                fprintf(stderr, "Cannot identify '%s': %d, %s\n",
                         dev_name, errno, strerror(errno));
                exit(EXIT_FAILURE);
        }

        if (!S_ISCHR(st.st_mode)) {
                fprintf(stderr, "%s is no device\n", dev_name);
                exit(EXIT_FAILURE);
        }

        fd = open(dev_name, O_RDWR /* required */ | O_NONBLOCK, 0);

        if (-1 == fd) {
                fprintf(stderr, "Cannot open '%s': %d, %s\n",
                         dev_name, errno, strerror(errno));
                exit(EXIT_FAILURE);
        }
}

int device_initialize(char *devname, int width, int height, char *format)
{
        if (fd >= 0) {
                fprintf(stderr, "device_initialize(): fd is already opened\n");
                return -1;
        }
        dev_name = (char *) malloc(strlen(devname) + 1);
        if (!dev_name)  errno_exit("MALLOC");
        strcpy(dev_name, devname);
        pix_width  = width;
        pix_height = height;
        if (strncmp(format, "YV12", 4) == 0) {
                pix_format = V4L2_PIX_FMT_YVU420;  /* YV12 */
                pix_field  = V4L2_FIELD_NONE;      /* progressive */
        } else
        if (strncmp(format, "UYVY", 4) == 0) {
                pix_format = V4L2_PIX_FMT_UYVY;
                //pix_field  = V4L2_FIELD_INTERLACED;
                pix_field  = V4L2_FIELD_NONE;      /* progressive */
        } else
        if (strncmp(format, "YUYV", 4) == 0) {
                pix_format = V4L2_PIX_FMT_YUYV;
                pix_field  = V4L2_FIELD_NONE;      /* progressive */
        } else {
                return -1;
        }

        open_device();
        if (init_device(1) < 0) {
                fprintf(stderr, "device_initialize(): init_device() failed\n");
                close_device();
                return -1;
        }
        return fd;
}

int device_initialize_keep_format(char *devname)
{
        if (fd >= 0) {
                fprintf(stderr, "device_initialize_keep_format(): fd is already opened\n");
                return -1;
        }
        dev_name = (char *) malloc(strlen(devname) + 1);
        if (!dev_name)  errno_exit("MALLOC");
        strcpy(dev_name, devname);

        open_device();
        if (init_device(0) < 0) {
                fprintf(stderr, "device_initialize_keep_format(): init_device() failed\n");
                close_device();
                return -1;
        }
        if (get_current_format() < 0) {
                fprintf(stderr, "device_initialize_keep_format(): get_current_format() failed\n");
                close_device();
                return -1;
        }
        if (pix_format != V4L2_PIX_FMT_YVU420 &&
            pix_format != V4L2_PIX_FMT_UYVY &&
            pix_format != V4L2_PIX_FMT_YUYV) {
                fprintf(stderr, "device_initialize_keep_format(): unsupported pixel format (%d)\n", pix_format);
                close_device();
                return -1;
        }
        return fd;
}

int device_get_format(int *width, int *height, char *format)
{
        if (fd < 0)
                return -1;
        *width  = pix_width;
        *height = pix_height;
        if (pix_format == V4L2_PIX_FMT_YVU420) {
                strcpy(format, "YV12");
        } else
        if (pix_format == V4L2_PIX_FMT_UYVY) {
                strcpy(format, "UYVY");
        } else
        if (pix_format == V4L2_PIX_FMT_YUYV) {
                strcpy(format, "YUYV");
        } else {  /* unsupported format */
                return -1;
        }
        return 0;
}

int device_start_capturing()
{
        if (fd < 0)
                return -1;
        return start_capturing();
}

void *device_get_next_frame(int timeout)
{
        void *ret;

        if (fd < 0)
                return NULL;
        if (timeout < 0)
                timeout = 2000000;  /* 2 seconds */

        while (1) {
                fd_set fds;
                struct timeval tv;
                int r;

                FD_ZERO(&fds);
                FD_SET(fd, &fds);

                /* Timeout. */
                tv.tv_sec = timeout / 1000000;
                tv.tv_usec = timeout % 1000000;

                r = select(fd + 1, &fds, NULL, NULL, &tv);

                if (-1 == r) {
                        if (EINTR == errno)
                                continue;
                        errno_exit("select");
                }
                if (0 == r) {
                        //fprintf(stderr, "select timeout\n");
                        return NULL;
                }

                ret = read_frame();
                if (ret)
                        return ret;
                /* EAGAIN - continue select loop. */
        }
}

void device_free_frame(void *p)
{
        if (fd < 0)
                return;
        free_frame(p);
}

void device_stop_capturing()
{
        if (fd < 0)
                return;
        stop_capturing();
}

void device_cleanup()
{
        if (fd < 0)
                return;
        uninit_device();
        close_device();
        fd = -1;
}

