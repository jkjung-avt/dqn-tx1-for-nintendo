# Makefile for libimshow.so
#
# It is used to build the imshow library, which could be called from
# Lua FFI interface.

CC       = gcc
CCFLAGS  = -fPIC -std=gnu99 -O2 -g -Wall
LIBOPTS  = -shared -lopencv_core -lopencv_highgui

.PHONY: all clean

all: libimshow.so

libimshow.so: imshow.c
	$(CC) imshow.c $(CCFLAGS) $(LIBOPTS) -o $@

clean :
	rm -f *.o *.so
