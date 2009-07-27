#!/bin/ksh

echo $PWD
. $PWD/deps.env

ssh -i $YSSHCERT root@$1 mkdir -p /mnt/keys
scp -i $YSSHCERT \
  $PCERTDIR/*.pem root@$1:/mnt/keys

scp -i $YSSHCERT $YSSHGITKEY \
  root@$1:/tmp
