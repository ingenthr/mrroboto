#!/bin/ksh

set -xe

mkdir tmp
INSTPATH=`pwd`/tmp
echo Temporary Install Directory:
echo $INSTPATH
cd $INSTPATH

# get the memcached upstream source
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

# create temp package structure
mkdir northscale-tdf
mkdir northscale-mrroboto
mkdir northscale-memcached

# copy the files into place

