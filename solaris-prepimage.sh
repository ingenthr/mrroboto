#!/bin/ksh

set -xe

INSTTYPE=$1

if [[ $INSTTYPE == "" ||
      ( $INSTTYPE != "ami" && $INSTTYPE != "native" ) ]]; then
  echo "usage: solaris-prepimage.sh <type>"
  echo "Type 'ami' or 'native' is required."
fi

# source needed envrionmentals
SCRIPTDIR=$(cd $(dirname "$0"); pwd)
. $SCRIPTDIR/solaris-image.env

if [[ ! -f $EC2_PRIVATE_KEY || ! -f $EC2_CERT ]]; then
  echo EC2 keys required for rebundling
  exit 1
fi

if [[ ! -f $EC2_HOME/bin/ec2-bundle-image ]]; then
  echo EC2_HOME is not set or is set incorrectly
  exit 1
fi

# install packages needed later
pkg install sunstudioexpress SUNWlighttpd14 SUNWlibevent

# get the memcached upstream source for now, replace with pkg later
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


# get the python stuff
PATH=/opt/SunStudioExpress/bin:$PATH
cd /tmp/src
pkg install SUNWPython25
#get easy install
if [[ ! -f setuptools-0.6c9-py2.5.egg ]]; then
  wget http://pypi.python.org/packages/2.5/s/setuptools/setuptools-0.6c9-py2.5.egg#md5=fe67c3e5a17b12c0e7c541b7ea43a8e6
fi
sh setuptools-0.6c9-py2.5.egg
easy_install Twisted
easy_install simplejson

# give the user DTrace privileges
usermod -K defaultpriv=basic,dtrace_user,dtrace_proc webservd

# copy the scripts and content into the right place
cd /tmp/src/mrroboto
cp -r tdf /usr/local
rm -rf /usr/local/tdf/.git
cd /tmp/src/mrroboto
cp -r dscripts /usr/local/tdf
cd /tmp/src/mrroboto
cp tdf/tdf-svc /usr/local/tdf
cp /usr/local/tdf/tdf.mrroboto /usr/local/tdf/tdf.tac
svccfg import tdf/tdf-manifest.xml

# set up automatic startup and verify services start
cp imagebuild/memcached-svc /usr/local/bin
svccfg import imagebuild/memcached.xml

# cap ZFS memory usage
# this may not work on EC2 :(
#cp /etc/system /etc/system.bak
#cat << STOP >> /etc/system
#*
#* lower the memory consumed by ZFS, since we won't be doing much FS stuff
#* here
#*
#* http://www.solarisinternals.com/wiki/index.php/ZFS_Evil_Tuning_Guide#Limiting_the_ARC_Cache
#*
#set zfs:zfs_arc_max = 1073741824
#
#STOP

# set up lighttpd
cd /tmp/src/mrroboto
cp imagebuild/gen-htdigest.sh /usr/local/tdf
svccfg import imagebuild/ec2lighttpdauth.xml
/usr/local/tdf/gen-htdigest.sh
cp /etc/lighttpd/1.4/lighttpd.conf /etc/lighttpd/1.4/lighttpd.conf.orig
patch /etc/lighttpd/1.4/lighttpd.conf /tmp/src/mrroboto/imagebuild/lighttpd.conf.patch

svccfg -s svc:/network/http:lighttpd14 << STOP
addpg ec2lighttpdauth dependency
setprop ec2lighttpdauth/grouping = astring: "require_all"
setprop ec2lighttpdauth/restart_on = astring: "none"
setprop ec2lighttpdauth/type = astring: "service"
setprop ec2lighttpdauth/entities = fmri: "svc:/application/ec2lighttpdauth:default"
STOP

svcadm enable http:lighttpd14
sleep 3

if [[ 0 -ne `svcs -x | wc -l` ]]; then
  echo Services failed to start...
  exit 1
fi


# do the rebundling itself
mv /root/.ssh /tmp/old-root-ssh
rm -f /var/adm/messages.[01234]
> /var/adm/messages
> /var/adm/utmpx
> /var/adm/wtmpx
rm -f /root/.bash_history

cd /mnt 
if [[ ! -f $IMAGE ]]; then
  /opt/ec2/sbin/rebundle.sh -v -y $IMAGE
fi

mkdir -p $DIRECTORY/parts
mkdir -p $DIRECTORY/keys

if [[ `isalist | cut -f 1 -d " "` == "amd64" ]]; then
  ec2-bundle-image -c $EC2_CERT -k $EC2_PRIVATE_KEY   \
    --kernel $EC2_KERNEL_64 --ramdisk $EC2_RAMDISK_64 \
    --block-device-mapping "root=rpool/56@0,ami=0,ephemeral0=1,ephemeral1=2,ephemeral2=3,ephemeral3=4" \
    --user $EC2_ACCT_NUM --arch x86_64 \
    -i $DIRECTORY/$IMAGE -d $DIRECTORY/parts 
else
  cd $DIRECTORY
  ec2-bundle-image -c $EC2_CERT -k $EC2_PRIVATE_KEY   \
    --kernel $EC2_KERNEL_32 --ramdisk $EC2_RAMDISK_32 \
    --block-device-mapping "root=rpool/56@0,ami=0,ephemeral0=1" \
    --user $EC2_ACCT_NUM --arch i386 \
    -i $DIRECTORY/$IMAGE -d $DIRECTORY/parts
fi
