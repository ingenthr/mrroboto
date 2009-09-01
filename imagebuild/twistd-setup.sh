#!/usr/bin/ksh 

# get easy install and then twistd and simplejson
PATH=/opt/SunStudioExpress/bin:/usr/gnu/bin:/usr/bin
CC=/opt/SunStudioExpress/bin/cc
CXX=/opt/SunStudioExpress/bin/CC
NSCALEPREFIX=/opt/northscale
PYTHONPATH=$NSCALEPREFIX/lib/python2.5/site-packages

# depends on SUNWPython25
#get easy install
if [[ ! -f setuptools-0.6c9-py2.5.egg ]]; then
  wget http://pypi.python.org/packages/2.5/s/setuptools/setuptools-0.6c9-py2.5.egg#md5=fe67c3e5a17b12c0e7c541b7ea43a8e6
fi

mkdir -p /opt/northscale/lib/python2.5/site-packages
env PATH=$PATH CC=$CC CXX=$CXX PYTHONPATH=$PYTHONPATH \
  /usr/gnu/bin/sh setuptools-0.6c9-py2.5.egg --prefix=$NSCALEPREFIX
env PYTHONPATH=$PYTHONPATH $NSCALEPREFIX/bin/easy_install Twisted
env PYTHONPATH=$PYTHONPATH $NSCALEPREFIX/bin/easy_install simplejson

cp -R tdf /opt/northscale
rm -rf /opt/northscale/tdf/.git
