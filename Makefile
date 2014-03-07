# makedumpfile

VERSION=1.5.5
DATE=18 Dec 2013

# Honour the environment variable CC
ifeq ($(strip $CC),)
CC	= gcc
endif

CFLAGS = -g -O2 -Wall -D_FILE_OFFSET_BITS=64 \
	  -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE \
	  -DVERSION='"$(VERSION)"' -DRELEASE_DATE='"$(DATE)"'
CFLAGS_ARCH	= -g -O2 -Wall -D_FILE_OFFSET_BITS=64 \
		    -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
# LDFLAGS = -L/usr/local/lib -I/usr/local/include

# Use TARGET as the target architecture if specified.
# Defaults to uname -m
ifeq ($(strip($TARGET)),)
TARGET := $(shell uname -m)
endif

ARCH := $(shell echo ${TARGET}  | sed -e s/i.86/x86/ -e s/sun4u/sparc64/ \
			       -e s/arm.*/arm/ -e s/sa110/arm/ \
			       -e s/s390x/s390/ -e s/parisc64/parisc/ \
			       -e s/ppc64/powerpc64/ -e s/ppc/powerpc32/)

CFLAGS += -D__$(ARCH)__
CFLAGS_ARCH += -D__$(ARCH)__

ifeq ($(ARCH), powerpc64)
CFLAGS += -m64
CFLAGS_ARCH += -m64
endif

ifeq ($(ARCH), powerpc32)
CFLAGS += -m32
CFLAGS_ARCH += -m32
endif

SRC	= makedumpfile.c makedumpfile.h diskdump_mod.h sadump_mod.h sadump_info.h
SRC_PART = print_info.c dwarf_info.c elf_info.c erase_info.c sadump_info.c cache.c
OBJ_PART=$(patsubst %.c,%.o,$(SRC_PART))
SRC_ARCH = arch/arm.c arch/x86.c arch/x86_64.c arch/ia64.c arch/ppc64.c arch/s390x.c arch/ppc.c
OBJ_ARCH=$(patsubst %.c,%.o,$(SRC_ARCH))

LIBS = -ldw -lbz2 -lebl -ldl -lelf -lz
ifneq ($(LINKTYPE), dynamic)
LIBS := -static $(LIBS)
endif

ifeq ($(USELZO), on)
LIBS := -llzo2 $(LIBS)
CFLAGS += -DUSELZO
endif

ifeq ($(USESNAPPY), on)
LIBS := -lsnappy $(LIBS)
CFLAGS += -DUSESNAPPY
endif

all: makedumpfile

$(OBJ_PART): $(SRC_PART)
	$(CC) $(CFLAGS) -c -o ./$@ ./$(@:.o=.c) 

$(OBJ_ARCH): $(SRC_ARCH)
	$(CC) $(CFLAGS_ARCH) -c -o ./$@ ./$(@:.o=.c) 

makedumpfile: $(SRC) $(OBJ_PART) $(OBJ_ARCH)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJ_PART) $(OBJ_ARCH) -rdynamic -o $@ $< $(LIBS)
	echo .TH MAKEDUMPFILE 8 \"$(DATE)\" \"makedumpfile v$(VERSION)\" \"Linux System Administrator\'s Manual\" > temp.8
	grep -v "^.TH MAKEDUMPFILE 8" makedumpfile.8 >> temp.8
	mv temp.8 makedumpfile.8
	gzip -c ./makedumpfile.8 > ./makedumpfile.8.gz
	echo .TH MAKEDUMPFILE.CONF 5 \"$(DATE)\" \"makedumpfile v$(VERSION)\" \"Linux System Administrator\'s Manual\" > temp.5
	grep -v "^.TH MAKEDUMPFILE.CONF 5" makedumpfile.conf.5 >> temp.5
	mv temp.5 makedumpfile.conf.5
	gzip -c ./makedumpfile.conf.5 > ./makedumpfile.conf.5.gz

eppic_makedumpfile.so: extension_eppic.c
	$(CC) $(CFLAGS) -shared -rdynamic -o $@ extension_eppic.c -fPIC -leppic -ltinfo

clean:
	rm -f $(OBJ) $(OBJ_PART) $(OBJ_ARCH) makedumpfile makedumpfile.8.gz makedumpfile.conf.5.gz

install:
	install -m 755 -d ${DESTDIR}/usr/sbin ${DESTDIR}/usr/share/man/man5 ${DESTDIR}/usr/share/man/man8 ${DESTDIR}/etc
	install -m 755 -t ${DESTDIR}/usr/sbin makedumpfile makedumpfile-R.pl
	install -m 644 -t ${DESTDIR}/usr/share/man/man8 makedumpfile.8.gz
	install -m 644 -t ${DESTDIR}/usr/share/man/man5 makedumpfile.conf.5.gz
	install -m 644 -D makedumpfile.conf ${DESTDIR}/etc/makedumpfile.conf.sample
	mkdir -p ${DESTDIR}/usr/share/makedumpfile-${VERSION}/eppic_scripts
	install -m 644 -t ${DESTDIR}/usr/share/makedumpfile-${VERSION}/eppic_scripts/ eppic_scripts/*
