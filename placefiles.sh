#!/bin/bash

BASEDIR=/opt/northscale
TDFDIR=$BASEDIR/tdf

# copy all of the files into the right place in /opt
mkdir -p $TDFDIR
cp -R tdf/* $TDFDIR


