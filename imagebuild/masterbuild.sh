#!/bin/ksh

set -xe

CC=/opt/SunStudioExpress/bin/cc
PATH=/opt/SunStudioExpress/bin:/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin

echo Building memcached...
env CC=$CC PATH=$PATH && memcached/build.sh $@
