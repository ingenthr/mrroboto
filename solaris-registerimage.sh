#!/bin/ksh

set -xe

# source needed envrionmentals
SCRIPTDIR=$(cd $(dirname "$0"); pwd)
. $SCRIPTDIR/solaris-image.env

if [[ ! -f $EC2_PRIVATE_KEY || ! -f $EC2_CERT ]]; then
  echo EC2 keys required for rebundling
  exit 1
fi

if [[ ! -f $EC2_HOME/bin/ec2-bundle-image ]]
  echo EC2_HOME is not set or is set incorrectly
  exit 1
fi

ec2reg -C $EC2_CERT -K $EC2_PRIVATE_KEY $BUCKET/$IMAGE.manifest.xml 
