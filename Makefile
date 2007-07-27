# makedumpfile

VERSION=1.1.4
DATE=08 June 2007

CC	= gcc
CFLAGS = -g -O2 -Wall -D_FILE_OFFSET_BITS=64 \
	  -DVERSION='"$(VERSION)"' -DRELEASE_DATE='"$(DATE)"'
CFLAGS_ARCH	= -g -O2 -Wall -D_FILE_OFFSET_BITS=64

ARCH := $(shell uname -m | sed -e s/i.86/x86/ -e s/sun4u/sparc64/ \
			       -e s/arm.*/arm/ -e s/sa110/arm/ \
			       -e s/s390x/s390/ -e s/parisc64/parisc/ \
			       -e s/ppc64/powerpc/ )
CFLAGS += -D__$(ARCH)__
CFLAGS_ARCH += -D__$(ARCH)__

ifeq ($(ARCH), powerpc)
CFLAGS += -m64
CFLAGS_ARCH += -m64
endif

SRC	= makedumpfile.c makedumpfile.h diskdump_mod.h
SRC_ARCH = x86.c x86_64.c ia64.c ppc64.c
OBJ_ARCH = x86.o x86_64.o ia64.o ppc64.o

all: makedumpfile

$(OBJ_ARCH): $(SRC_ARCH)
	$(CC) $(CFLAGS_ARCH) -c -o ./$@ ./$(@:.o=.c) 

makedumpfile: $(SRC) $(OBJ_ARCH)
	$(CC) $(CFLAGS) $(OBJ_ARCH) -o $@ $< -static -ldw -lelf -lz

clean:
	rm -f $(OBJ) $(OBJ_ARCH) makedumpfile makedumpfile.8.gz

install:
	zip ./makedumpfile.8.gz ./makedumpfile.8
	cp ./makedumpfile /bin
	cp ./makedumpfile-R.pl /bin
	cp ./makedumpfile.8.gz /usr/share/man/man8

