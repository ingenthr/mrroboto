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
export EC2_KEYID=AKIAJ3BZHH4WP3ZD3RBQ
export EC2_KEY=vFkeaVabtCV2R9j/U+EF7QJRNAfeBS57cFZQ7zgJ
export EC2_ACCT_NUM=7860-1448-3886
export DIRECTORY=/mnt 
if [[ `isalist | cut -f 1 -d " "` == "amd64" ]]; then
  export IMAGE=community-memcached-1.4.0+instrumentation-x86_64
else
  export IMAGE=community-memcached-1.4.0+instrumentation-i386
fi
export BUCKET=northscale


if [[ ! -f $EC2_PRIVATE_KEY || ! -f $EC2_CERT ]]; then
  echo keys required for rebundling and password required to get git
  exit -1
fi

cd $DIRECTORY/parts 
ec2-upload-bundle -b $BUCKET  -m $IMAGE.manifest.xml -a $EC2_KEYID -s $EC2_KEY --url http://s3.amazonaws.com --retry
