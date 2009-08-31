# project for building the 32 and 64-bit memcached and the isaexec

VER = memcached-1.4.1
VER64 = $(VER)-64

BUILD_PATH = /opt/SunStudioExpress/bin:/usr/gnu/bin:/usr/bin
CCSMAKE = /usr/bin/gmake

NSCALEPREFIX = /opt/northscale

CFLAGS += -mt -xO5 -xtarget=generic -xstrconst
CFLAGS64 = -mt -xO5 -xtarget=generic64 -xstrconst

LIBS = -lumem

CONFIGURE_OPTIONS = --enable-dtrace
CONFIGURE_OPTIONS += --localstatedir=/var

CONFIGURE_OPTIONS32 = $(CONFIGURE_OPTIONS)
CONFIGURE_OPTIONS32 += --prefix=$(NSCALEPREFIX)/bin/i86
CONFIGURE_OPTIONS32 += --with-libevent=/usr

CONFIGURE_OPTIONS64 = $(CONFIGURE_OPTIONS)
CONFIGURE_OPTIONS64 += --prefix=$(NSCALEPREFIX)/bin/amd64
CONFIGURE_OPTIONS64 += --with-libevent=/usr/lib/amd64

# not the real memcached, just the isaexec
bin_PROGRAMS = memcached
memcached_SOURCES = memcached.c

fetch-memcached:
	tar -zxf $VER.tar.gz
	cd $VER

build-memcached-32: fetch-memcached

$(VER)/config.status: $(VER)/configure
	(cd $(VER); env \
	CC=$(CC) "CFLAGS=$(CFLAGS)" "LDFLAGS=-mt -lnsl" \
	PATH=$(BUILD_PATH) \
	MAKE=$(CCSMAKE) \
	./configure $(CONFIGURE_OPTIONS32))

$(VER64)/config.status: $(VER64)/configure
	(cd $(VER64); env \
	CC=$(CC64) "CFLAGS=$(CFLAGS64)" "LDFLAGS=-mt -lnsl" \
	PATH=$(BUILD_PATH)
	MAKE=$(CCSMAKE) \
	./configure $(CONFIGURE_OPTIONS64))

$(VER)/configure: $(VER).tar.gz
	gzip -dc $(VER).tar.gz | tar xopf -
	touch $(VER)/configure

$(VER64)/configure: $(VER).tar.gz
	mkdir -p tmp
	gzip -dc $(VER).tar.gz | (cd tmp; tar xopf -)
	rm -rf $(VER64)
	mv tmp/$(VER) $(VER64); rmdir tmp
	touch $(VER64)/configure

        (cd $(VER); env \
        PATH=$(BUILD_PATH) \
        MAKE=$(CCSMAKE) \
        ./gmake)

build32: $(VER)/config.status
	(cd $(VER); env \
	"CFLAGS=$(CFLAGS)" "LDFLAGS=-mt -L$(NSCALEPREFIX)/lib -lnsl" \
	PATH=$(BUILD_PATH) \
	MAKE=$(CCSMAKE) \
	$(CCSMAKE))

build64: $(VER64)/config.status
	(cd $(VER64); env \
	"CFLAGS=$(CFLAGS64)" "LDFLAGS=-mt -L$(NSCALEPREFIX)/lib/amd64} -lnsl" \
	PATH=$(BUILD_PATH) \
	MAKE=$(CCSMAKE) \
	$(CCSMAKE))

$(VER)/build: $(VER)/config.status
	(cd $(VER); env \
        PATH=$(BUILD_PATH) \
        $(CCSMAKE))

$(VER64)/build: $(VER64)/config.status
        (cd $(VER64); env \
        PATH=$(BUILD_PATH) \
        $(CCSMAKE))
