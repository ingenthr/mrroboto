#!/bin/ksh

echo This is just notes at this point
exit -1

export JAVA_HOME=/usr/jdk/latest
export EC2_HOME=/opt/ec2
export BUCKET=northscale
export PATH=$PATH:$EC2_HOME/bin 
export RUBYLIB=$EC2_HOME/lib 
export EC2_URL=https://ec2.amazonaws.com 
export EC2_PRIVATE_KEY=/mnt/keys/blah
export EC2_CERT=/mnt/keys/blah
#export EC2_KEYID=<KEY ID> 
#export EC2_KEY=<KEY> 
export DIRECTORY=/mnt 
export IMAGE=mrroboto.img


if [[ ! -f $EC2_PRIVATE_KEY || ! -f $EC2_CERT || ! -f pass ]]; then
  echo keys required for rebundling and password required to get git
  exit -1
fi

pkg refresh
# stick to 101 due to a conflict with the latest, fix when fixed in the repo
pkg install pkg:/sunstudioexpress@0.2009.3.1,5.11-0.101
pkg install SUNWlighttpd14 SUNWlibevent

# get the memcached upstream source for now, replace with pkg later
cd /tmp
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
scpuser=ingenthr
scphost=24.152.131.52
for i in $(pkg contents -r SUNWgit); 
do 
  scp $scpuser@$scphost:/$i /$i; 
done

# check out mrroboto
git clone git@github.com:northscale/mrroboto.git

# copy the scripts and content into the right place

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

