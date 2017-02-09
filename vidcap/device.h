/*
 * device.h
 */

#ifdef __cplusplus
extern "C" {
#endif

extern int   device_initialize(char *devname, int width, int height, char *format);
extern int   device_initialize_keep_format(char *devname);
extern int   device_get_format(int *width, int *height, char *format);
extern int   device_start_capturing();
extern void *device_get_next_frame(int timeout);  /* microseconds */
extern void  device_free_frame(void *p);
extern void  device_stop_capturing();
extern void  device_cleanup();

#ifdef __cplusplus
}
#endif
