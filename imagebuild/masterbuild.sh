#!/bin/ksh

set -xe

CC=/opt/SunStudioExpress/bin/cc
CXX=/opt/SunStudioExpress/bin/CC
PATH=/opt/SunStudioExpress/bin:/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin

echo Building memcached...
env CC=$CC PATH=$PATH memcached/build.sh $@

echo Building twistd...
env CC=$CC CXX=$CXX PATH=$PATH twistd/build.sh $@
