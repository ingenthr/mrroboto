#!/bin/bash
# Version 2009.6.2.00 Updated by Jignesh Shah added  SUNWahci tested for OpenSolaris 2009.06 with VirtualBox 2.2.4
# Version 2008.12.16.20  by Jignesh Shah based on Alex Eremin's blog entry and some more cutomization
# Significant updates by Matt Ingenthron for NorthScale
# Portions Copyright 2009 NorthScale
TIMEZONE="TZ=UTC"
HOSTNAME=memcached-appliance

INSTALLDISK=c8t0d0
PKG_IMAGE=/a; export PKG_IMAGE

# this install method is a hack for now, reuse variable later
IPKG_HOST=10.0.2.15
HUSERNAME=ingenthr

set -x

fdisk -n -B /dev/rdsk/${INSTALLDISK}p0
#echo "Note VDI Should be dynamic sized of max 16.00GB as defined in Virtualbox"
#fmthard -d 0:2:00:48195:33447330 /dev/rdsk/${INSTALLDISK}p0
vtocBegin=$(prtvtoc -h /dev/rdsk/${INSTALLDISK}p0 | grep "^[[:space:]]*8" | awk '{ print $6 }')
vtocSectors=$(prtvtoc -h /dev/rdsk/${INSTALLDISK}p0 | grep "^[[:space:]]*2" | awk '{ print $6 }')
vtocCount=$((${vtocSectors} - ${vtocBegin}))
vtocBegin=$((${vtocBegin} + 1 ))

SecCnt=$(prtvtoc /dev/rdsk/${INSTALLDISK}p0 | awk '/sectors\/cylinder/ { print $2}')
LastSect=$(prtvtoc /dev/rdsk/${INSTALLDISK}p0 | awk '$1 == "2" { print $5}')
LastSect=$((${LastSect} - ${SecCnt}))
echo fmthard -d 0:2:00:${SecCnt}:${LastSect} 

fmthard -d "0:2:00:$vtocBegin:$vtocCount" /dev/rdsk/${INSTALLDISK}p0

zpool create -f rpool ${INSTALLDISK}s0
zfs set compression=on rpool 
zfs create -o mountpoint=legacy rpool/ROOT
zfs create -o mountpoint=$PKG_IMAGE rpool/ROOT/VOSApp
#zfs create -V 128M rpool/swap
zfs create -V 16M rpool/dump
zfs create rpool/ROOT/VOSApp/opt
zfs create rpool/ROOT/VOSApp/var
zfs create rpool/export
zpool set bootfs=rpool/ROOT/VOSApp rpool

# create the basic opensolaris install image..
pkg image-create -f -F -a opensolaris.org=http://pkg.opensolaris.org/release $PKG_IMAGE
pkg refresh

# Common Virtual OpenSolaris Install
pkg install SUNWcsd 
pkg install SUNWcs 
pkg install SUNWckr SUNWcar SUNWcakr SUNWkvm SUNWos86r SUNWrmodr SUNWpsdcr \
  SUNWpsdir SUNWcnetr SUNWesu SUNWkey SUNWnfsckr SUNWnfsc SUNWgss SUNWgssc \
  SUNWbip SUNWbash SUNWloc SUNWsshcu SUNWsshd SUNWssh SUNWtoo SUNWzfskr \
  SUNWipf SUNWintgige SUNWipkg  SUNWadmr SUNWadmap SUNWPython \
  SUNWperl584core SUNWgrub SUNWxcu6 SUNWxcu4 SUNWgawk SUNWgtar \
  SUNWgnu-coreutils SUNWscp SUNWfmd SUNWxge SUNWbge SUNWnge SUNWrge \
  SUNWrtls SUNWixgb SUNWchxge SUNWzfs-auto-snapshot SUNWsolnm SUNWahci \
  SUNWpython25 SUNWlighttpd14 SUNWlibevent SUNWnetcat

# seed the initial smf repository
cp $PKG_IMAGE/lib/svc/seed/global.db $PKG_IMAGE/etc/svc/repository.db
chmod 0600 $PKG_IMAGE/etc/svc/repository.db
chown root:sys $PKG_IMAGE/etc/svc/repository.db

# Set TimeZone 
echo "$TIMEZONE" > $PKG_IMAGE/etc/TIMEZONE
echo $HOSTNAME > $PKG_IMAGE/etc/nodename


# configure our new /etc/vfstab
printf "rpool/ROOT/VOSApp -\t/\t\tzfs\t-\tno\t-\n" >> $PKG_IMAGE/etc/vfstab
#printf "/dev/zvol/dsk/rpool/swap\t-\t-\t\tswap\t-\tno\t-\n" >> $PKG_IMAGE/etc/vfstab
chmod a+r $PKG_IMAGE/etc/vfstab

# turn off root as a role
# TODO: fix this, it exits unclean at the moment
printf "/^root::::type=role;\ns/^root::::type=role;/root::::/\nw" |\
ed -s $PKG_IMAGE/etc/user_attr
# Edit etc/ssh/sshd_config to allow ssh to root account
printf "/^PermitRootLogin no\ns/^PermitRootLogin no/PermitRootLogin yes/\nw" |\
ed -s ${PKG_IMAGE}/etc/ssh/sshd_config 

# delete the "jack" user
cp $PKG_IMAGE/etc/shadow $PKG_IMAGE/etc/passwd /tmp
#printf "/^jack:/d\nw" | ed -s $PKG_IMAGE/etc/passwd
cat /tmp/passwd | grep -v jack > $PKG_IMAGE/etc/passwd
chmod u+w $PKG_IMAGE/etc/shadow
#printf "/^jack:/d\nw" | ed -s $PKG_IMAGE/etc/shadow
cat /tmp/shadow | grep -v jack > $PKG_IMAGE/etc/shadow
chmod u-w $PKG_IMAGE/etc/shadow

# Generate ssh keys
ssh-keygen -t dsa -f $PKG_IMAGE/etc/ssh/ssh_host_dsa_key -N ''
ssh-keygen -t rsa -f $PKG_IMAGE/etc/ssh/ssh_host_rsa_key -N ''

# setup smf profiles
ln -s ns_files.xml $PKG_IMAGE/var/svc/profile/name_service.xml
ln -s generic_limited_net.xml $PKG_IMAGE/var/svc/profile/generic.xml
ln -s inetd_generic.xml $PKG_IMAGE/var/svc/profile/inetd_services.xml
ln -s platform_none.xml $PKG_IMAGE/var/svc/profile/platform.xml
# Set the environment variables for svccfg.
SVCCFG_DTD=${PKG_IMAGE}/usr/share/lib/xml/dtd/service_bundle.dtd.1
SVCCFG_REPOSITORY=${PKG_IMAGE}/etc/svc/repository.db
SVCCFG=/usr/sbin/svccfg
export SVCCFG_DTD SVCCFG_REPOSITORY SVCCFG
${SVCCFG} import ${PKG_IMAGE}/var/svc/manifest/milestone/sysconfig.xml
${SVCCFG} -s network/physical:default setprop general/enabled=false
${SVCCFG} -s network/physical:nwam setprop general/enabled=true

ln -s /usr/xpg4/bin/vi $PKG_IMAGE/usr/bin/vi


# configure /dev in the new image
devfsadm -R $PKG_IMAGE
bootadm update-archive -R $PKG_IMAGE

# update to the latest version of grub (this command generated
# some errors which i ignored).
$PKG_IMAGE/boot/solaris/bin/update_grub -R $PKG_IMAGE
#bootadm update-menu -Z -R $PKG_IMAGE -o /dev/rdsk/${INSTALLDISK}s0
#installgrub $PKG_IMAGE/boot/grub/stage1 $PKG_IMAGE/boot/grub/stage2 /dev/rdsk/${INSTALLDISK}s0

echo "IGNORE ERRORS ABOVE for the time being"

# create an informational grub menu in the install image that
# points us to the real grub menu.
cat <<-EOF > $PKG_IMAGE/boot/grub/menu.lst

#########################################################################
# For zfs root, menu.lst has moved to /rpool/boot/grub/menu.lst. #
#########################################################################
EOF

# set up a default motd
cat <<-EOF > $PKG_IMAGE/etc/motd

This Virtual Appliance has been packaged by NorthScale with a tested 
release of memcached built directy from the source distribution from the
Open Source memcached community.

It is available free of charge and supports the latest features and fixes
as covered in the release notes:
<http://code.google.com/p/memcached/wiki/ReleaseNotes141>

It is backward compatible with previous releases and previous clients.
Updated clietns are recommended and may be required to take advantage of
the latest functionality.  By default, this image will run a single
memcached instance using nearly all of the memory on the system.

For more information on memcahced in general, look to the official site
<http://memcached.org/> or the wiki and faq.

For more information on this image or to track updates, please look to
<http://labs.northscale.com/memcached-virtual-appliance/>

EOF

# copy in place the files

#CUSTOMIZATION
# create the new real grub menu
cat <<-EOF > /rpool/boot/grub/menu.lst
default 0
timeout 10
splashimage /boot/grub/splash.xpm.gz

title NorthScale community memcached with tools
findroot (pool_rpool,0,a)
bootfs rpool/ROOT/VOSApp
kernel\$ /platform/i86pc/kernel/\$ISADIR/unix  -B \$ZFS-BOOTFS
module\$ /platform/i86pc/\$ISADIR/boot_archive

EOF

# make the grub menu files readable by everyone.
chmod a+r $PKG_IMAGE/boot/grub/menu.lst
chmod a+r /rpool/boot/grub/menu.lst

# setup /etc/bootsign so that grub can find this zpool
mkdir -p /rpool/etc
echo pool_rpool > /rpool/etc/bootsign
zfs set mountpoint=/ rpool/ROOT/VOSApp
#zfs set compression=off rpool
#reboot

# load up the pkgs, set up services
scp -r $HUSERNAME@$IPKG_HOST:/opt/northscale $PKG_IMAGE/opt
cp $PKG_IMAGE/opt/northscale/var/svc/manifest/* \
  $PKG_IMAGE/opt/northscale/tdf/tdf-manifest.xml $PKG_IMAGE/var/svc/manifest
scp -r $HUSERNAME@$IPKG_HOST:~ingenthr/src/mrroboto/imagebuild/lighttpd.conf.patch /tmp

# cap ZFS memory usage
# this may not work on EC2 :(
cp /etc/system /etc/system.bak
cat << STOP >> /etc/system
*
* lower the memory consumed by ZFS, since we won't be doing much FS stuff
* here
*
* http://www.solarisinternals.com/wiki/index.php/ZFS_Evil_Tuning_Guide#Limiting_the_ARC_Cache
*
set zfs:zfs_arc_max = 1073741824

STOP

# set up lighttpd
cp $PKG_IMAGE/etc/lighttpd/1.4/lighttpd.conf $PKG_IMAGE/etc/lighttpd/1.4/lighttpd.conf.orig
patch $PKG_IMAGE/etc/lighttpd/1.4/lighttpd.conf /tmp/lighttpd.conf.patch
