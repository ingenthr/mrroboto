#!/bin/ksh

set -xe

export JAVA_HOME=/usr/jdk/latest
export EC2_HOME=/opt/ec2
export BUCKET=northscale
export PATH=$PATH:$EC2_HOME/bin 
export RUBYLIB=$EC2_HOME/lib 
export EC2_URL=https://ec2.amazonaws.com 
export EC2_PRIVATE_KEY=/mnt/keys/pk-WBDFRTOLJOOKKAESM24HXVVCW556MAYH.pem
export EC2_CERT=/mnt/keys/cert-WBDFRTOLJOOKKAESM24HXVVCW556MAYH.pem
#export EC2_KEYID=blah
#export EC2_KEY=blah
export EC2_ACCT_NUM=7860-1448-3886
export DIRECTORY=/mnt 
if [[ `isalist | cut -f 1 -d " "` == "amd64" ]]; then
  export IMAGE=community-memcached-1.4.0+instrumentation-x86_64
else
  export IMAGE=community-memcached-1.4.0+instrumentation-i386
fi

if [[ ! -f $EC2_PRIVATE_KEY || ! -f $EC2_CERT ]]; then
  echo keys required for rebundling and password required to get git
  exit -1
fi

# stick to 101 due to a conflict with the latest, fix when fixed in the repo
pkg install sunstudioexpress SUNWlighttpd14 SUNWlibevent

# get the memcached upstream source for now, replace with pkg later
cd /tmp/src
wget http://memcached.googlecode.com/files/memcached-1.4.0.tar.gz
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

if [[ ! -f memcached ]]; then
dmake install
fi


# get the python stuff
PATH=/opt/SunStudioExpress/bin:$PATH
cd /tmp
pkg install SUNWPython25
#get easy install
wget http://pypi.python.org/packages/2.5/s/setuptools/setuptools-0.6c9-py2.5.egg#md5=fe67c3e5a17b12c0e7c541b7ea43a8e6
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
svccfg import imagebuild/ec2/lighttpdauth.xml
/usr/local/tdf/gen-htdigest.sh
patch /etc/lighttpd/1.4/lighttpd.conf /tmp/src/mrroboto/imagebuild/lighttpd.conf.patch
svcadm enable http:lighttpd14


# do the rebundling itself
rm -rf /root/.ssh
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
    --kernel aki-fb3ddc92 --ramdisk ari-fd3ddc94 \
    --block-device-mapping "root=rpool/56@0,ami=0,ephemeral0=1,ephemeral1=2,ephemeral2=3,ephemeral3=4" \
    --user $EC2_ACCT_NUM --arch x86_64 \
    -i $DIRECTORY/$IMAGE -d $DIRECTORY/parts 
else
  cd $DIRECTORY
  ec2-bundle-image -c $EC2_CERT -k $EC2_PRIVATE_KEY   \
    --kernel aki-1783627e --ramdisk ari-858362ec \
    --block-device-mapping "root=rpool/56@0,ami=0,ephemeral0=1" \
    --user $EC2_ACCT_NUM --arch i386 \
    -i $DIRECTORY/$IMAGE -d $DIRECTORY/parts
fi


echo !!!!verify /etc/system !!!!
