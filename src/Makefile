# Makefile for rxgzlib - REXX to gzip library

MAKE = dmake
CC = gcc -Zomf -s

CFLAGS = -O6 -Wall -Zso -Zsys -Zdll -lz

#
# The objects for the different methods and
# some common aliases
#

OBJS=	rxgzlib.obj

.c.obj:
	$(CC) -c $(CFLAGS) $<

all:	rxgzlib.dll

rxgzlib.dll:	
	$(MAKE) $(OBJS)
	$(CC) -o rxgzlib.dll rxgzlib.def -g -s $(CFLAGS) $(OBJS) $(LIBS)
	
clean:
	rm -f ./rxgzlib.dll
	rm -f ./*.obj

$(OBJS):	Makefile zlib.h
