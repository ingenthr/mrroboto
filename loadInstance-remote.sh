#!/bin/ksh
eval `ssh-agent`

ssh-add /tmp/id_dsa-northscale

pkg refresh
pkg install SUNWgit

mkdir -p /tmp/src
cd /tmp/src
git clone git@github.com:northscale/mrroboto.git
cd mrroboto
git submodule init
git submodule update

