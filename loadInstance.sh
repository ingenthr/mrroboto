#!/bin/ksh

if [[ $1 == "" ]] then;
  echo "usage: loadInstance.sh <instance hostname>"
  exit 1
fi

# source needed envrionmentals
SCRIPTDIR=$(cd $(dirname "$0"); pwd)
. $SCRIPTDIR/deps.env

ssh -i $YSSHCERT root@$1 mkdir -p /mnt/keys
scp -i $YSSHCERT \
  $PCERTDIR/*.pem root@$1:/mnt/keys

scp -i $YSSHCERT $YSSHGITKEY \
  root@$1:/tmp

scp -i $YSSHCERT loadInstance-remote.sh root@$1:/tmp

scp -i $YSSHCERT solaris-image.env root@$1:/tmp
