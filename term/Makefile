# Makefile for libterm.so
#
# It is used to build the term (waitkey) library, which could be called from
# Lua FFI interface.

CC       = gcc
CCFLAGS  = -fPIC -std=gnu99 -O2 -g -Wall
LIBOPTS  = -shared

.PHONY: all clean

all: libterm.so

libterm.so: term.c
	$(CC) term.c $(LIBOPTS) $(CCFLAGS) -o $@

clean :
	rm -f *.o *.so
