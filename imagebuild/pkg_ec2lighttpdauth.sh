#!/bin/ksh

#
# Load the ec2lighttpd auth service to the pkg repo
#

set -xe

# source needed environmentals
SCRIPTDIR=$(cd $(dirname "$0"); pwd)
. $SCRIPTDIR/pkg.env

eval `${pkgsendcmd} open ec2lighttpdauth@1.0-1`
${pkgsendcmd} add dir mode=0555 owner=root group=bin path=/opt/northscale
${pkgsendcmd} add file gen-htdigest.sh mode=0555 owner=root group=bin \
path=/opt/northscale/gen-htdigest.sh
${pkgsendcmd} add file ec2lighttpdauth.xml mode=055 owner=root group=bin \
path=/var/svc/manifest/application/ec2lighttpdauth.xml
${pkgsendcmd} add set restart_fmri=svc:/system/manifest-import:default 
${pkgsendcmd} close
