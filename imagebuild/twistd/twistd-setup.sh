#!/usr/bin/ksh 

set -xe

# get easy install and then twistd and simplejson
# path vars should come from execution environment
#PATH=/opt/SunStudioExpress/bin:/usr/gnu/bin:/usr/bin
#CC=/opt/SunStudioExpress/bin/cc
#CXX=/opt/SunStudioExpress/bin/CC
#INSTLOC=/opt/northscale
PYTHONPATH=$INSTLOC/lib/python2.5/site-packages

if [[ -n $PYTHONPATH ]]; then
  if ! mkdir -p $PYTHONPATH; then
    echo $PYTHONPATH does not exist and could not create it
    exit -1
  fi
fi

# depends on SUNWPython25
#get easy install
if [[ ! -f setuptools-0.6c9-py2.5.egg ]]; then
  wget http://pypi.python.org/packages/2.5/s/setuptools/setuptools-0.6c9-py2.5.egg#md5=fe67c3e5a17b12c0e7c541b7ea43a8e6
fi

mkdir -p /opt/northscale/lib/python2.5/site-packages
env PATH=$PATH CC=$CC CXX=$CXX PYTHONPATH=$PYTHONPATH \
  /usr/gnu/bin/sh setuptools-0.6c9-py2.5.egg --prefix=$INSTLOC
env PYTHONPATH=$PYTHONPATH $INSTLOC/bin/easy_install --prefix=$INSTLOC Twisted
env PYTHONPATH=$PYTHONPATH $INSTLOC/bin/easy_install --prefix=$INSTLOC simplejson

#cp -R tdf /opt/northscale
#rm -rf /opt/northscale/tdf/.git
