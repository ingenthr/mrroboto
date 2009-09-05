#!/bin/bash

if [[ $1 == "" ]]; then
  echo "usage: gen-htdigest-va.sh <password>"
  exit -1
fi

user=memcached
realm="memcached tools"
pass=$1

hash=`echo -n "$user:$realm:$pass" | md5sum | cut -b -32`

echo "$user:$realm:$hash" > /var/lighttpd/1.4/lighttpd-htdigest.user
chown webservd:webservd /var/lighttpd/1.4/lighttpd-htdigest.user
chmod 600 /var/lighttpd/1.4/lighttpd-htdigest.user
