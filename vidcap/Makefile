# Makefile for libvidcap.so
#
# It is used to build the video capture library, which could be called from
# Lua FFI interface.

CC       = gcc
CCFLAGS  = -fPIC -std=gnu99 -O2 -g -Wall
LIBOPTS  = -shared

.PHONY: all clean

all: libvidcap.so

libvidcap.so: video0_cap.c device.c device.h
	$(CC) video0_cap.c device.c $(LIBOPTS) $(CCFLAGS) -o $@

clean :
	rm -f *.o *.so
