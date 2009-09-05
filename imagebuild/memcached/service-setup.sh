#!/bin/ksh

MANIFESTDIR=/opt/northscale/var/svc/manifest
mkdir -p $MANIFESTDIR

cp memcached.xml $MANIFESTDIR
