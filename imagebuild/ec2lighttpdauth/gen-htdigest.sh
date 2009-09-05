#!/bin/bash

user=memcached
realm="memcached AMI tools"
pass=`curl http://169.254.169.254/2009-04-04/meta-data/instance-id`

hash=`echo -n "$user:$realm:$pass" | md5sum | cut -b -32`

echo "$user:$realm:$hash" > /var/lighttpd/1.4/lighttpd-htdigest.user
chown webservd:webservd /var/lighttpd/1.4/lighttpd-htdigest.user
chmod 600 /var/lighttpd/1.4/lighttpd-htdigest.user
