#/bin/ksh

echo This is just notes at this point
exit -1

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
export DIRECTORY=/mnt 
export IMAGE=mrroboto.img


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
PATH=$PATH:/opt/SunStudioExpress/bin
CC=/opt/SunStudioExpress/bin/cc
CXX=/opt/SunStudioExpress/bin/CC
CFLAGS="-fast -mt"
LIBS="-lumem"
configopts="--enable-dtrace"
if [[ ! -f Makefile ]]; then
./configure $configopts
fi

if [[ ! -f memcached ]]; then
dmake install
fi


# it's a hack, but get a working git from a 2009.06 box
#tar -czvf /var/tmp/gitfor2008.11.tar.gz `pkg contents -t file \
# -o path SUNWgit | grep -v PATH`
#cd /
#wget http://blogs.ingenthron.org/gitfor2008.11.tar.gz
#tar -zxf gitfor2008.11.tar.gz
#rm gitfor2008.11.tar.gz

# get the python stuff
PATH=/opt/SunStudioExpress/bin:$PATH
cd /tmp
pkg install SUNWPython25
#get easy install
wget http://pypi.python.org/packages/2.5/s/setuptools/setuptools-0.6c9-py2.5.egg#md5=fe67c3e5a17b12c0e7c541b7ea43a8e6
sh setuptools-0.6c9-py2.5.egg
easy_install Twisted
easy_install simplejson

#give the user DTrace privileges
usermod -K defaultpriv=basic,dtrace_user,dtrace_proc webservd

# copy the scripts and content into the right place
cd /tmp/src/mrroboto
DOCROOT=/var/lighttpd/1.4
TDFROOT=/var/tdf
mkdir -p $TDFROOT
cp -r tdf /usr/local
rm -rf /usr/local/tdf/.git
cd /tmp/src/mrroboto/imagebuild
cp -r dscripts /usr/local/tdf

# set up automatic startup and verify services start
cp imagebuild/memcached-svc /usr/local/bin

# cap ZFS memory usage
cp /etc/system /etc/system.bak
cat << STOP >> /etc/system
*
* lower the memory consumed by ZFS, since we won't be doing much FS stuff
* here
* 
* http://www.solarisinternals.com/wiki/index.php/ZFS_Evil_Tuning_Guide#Limiting_the_ARC_Cache
* 
set zfs:zfs_arc_max = 1073741824

STOP

# do the rebundling itself
rm -r /root/.ssh
rm -f /var/adm/messages.[01234]
> /var/adm/messages
> /var/adm/utmpx
> /var/adm/wtmpx
rm /root/.bash_history

cd $DIRECTORY
bundle-image -c $EC2_CERT -k $EC2_PRIVATE_KEY   \ 
   --kernel aki-6552b60c --ramdisk ari-6452b60d \ 
   --block-device-mapping "root=rpool/52@0,ami=0,ephemeral0=1" \ 
   --user <userid> --arch i386 \ 
   -i $DIRECTORY/$IMAGE -d $DIRECTORY/parts 

echo !!!!verify /etc/system !!!!
