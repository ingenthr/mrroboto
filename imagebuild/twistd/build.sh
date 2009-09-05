#!/bin/ksh

# $1 should be install location, $2 should be type`

set -xe

INSTLOC=$1
INSTTYPE=$2
 
SCRIPTDIR=$(cd $(dirname "$0"); pwd)
cd $SCRIPTDIR

if [[ $INSTLOC == "" || $INSTTYPE == "" ]]; then
  echo "usage: build <location> {VA|EC2}"
  exit -1
fi

if [[ -n $INSTLOC ]]; then 
  if ! mkdir -p $INSTLOC; then
    echo "error: install location does not exist and could not create"
    exit -1
  fi
fi

if [[ $INSTTYPE != "VA" && $INSTTYPE != "EC2" ]]; then
  echo "usage: build <location> {VA|EC2}"
  echo "location must be either VA or EC2"
  exit -1
fi

env INSTLOC=$INSTLOC $SCRIPTDIR/twistd-setup.sh
