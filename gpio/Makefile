# Makefile for libgpio.so
#
# It is used to build the gpio library, which could be called from
# Lua FFI interface.

CC       = gcc
CCFLAGS  = -fPIC -std=gnu99 -O2 -g -Wall
LIBOPTS  = -shared

.PHONY: all clean

all: libgpio.so

libgpio.so: gpio.c jetsonGPIO.c jetsonGPIO.h
	$(CC) gpio.c jetsonGPIO.c $(LIBOPTS) $(CCFLAGS) -o $@

clean :
	rm -f *.o *.so
