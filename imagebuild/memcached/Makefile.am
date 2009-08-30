# project for building the 32 and 64-bit memcached and the isaexec

VER = memcached-1.4.0
VER64 = $(VER)-64

CFLAGS += -mt -x05 -xtarget=generic -xstrconst
CFLAGS64 += -mt -x05 -xtarget=generic64 -xstrconst

CONFIGURE_OPTIONS += --enable-dtrace
CONFIGURE_OPTIONS += --localstatedir=/var

CONFIGURE_OPTIONS32 = $(CONFIGURE_OPTIONS)
CONFIGURE_OPTIONS32 = --with-libevent=/usr

CONFIGURE_OPTIONS64 = $(CONFIGURE_OPTIONS)
CONFIGURE_OPTIONS64 += --with-libevent=/usr/lib/amd64

# not the real memcached, just the isaexec
bin_PROGRAMS = memcached
memcached_SOURCES = memcached.c

fetch-memcached:
cd /tmp/src
if [[ ! -f memcached-1.4.0.tar.gz ]]; then
  wget http://memcached.googlecode.com/files/memcached-1.4.0.tar.gz
fi
tar -zxf memcached-1.4.0.tar.gz
cd memcached-1.4.0
configopts="--enable-dtrace"
PATH=$PATH:/opt/SunStudioExpress/bin
CC=/opt/SunStudioExpress/bin/cc
CXX=/opt/SunStudioExpress/bin/CC
CFLAGS="-fast -mt"
if [[ `isalist | cut -f 1 -d " "` == "amd64" ]]; then
  configopts="$configopts --enable-64bit"
fi
LIBS="-lumem"
if [[ ! -f Makefile ]]; then
./configure $configopts
fi

if [[ ! -f /usr/local/bin/memcached ]]; then
dmake install
fi

