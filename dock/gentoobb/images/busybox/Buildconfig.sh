#
# build config
#
PACKAGES="sys-apps/busybox"
EMERGE_BIN="emerge-armv7a-hardfloat-linux-gnueabi"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    echo "sys-apps/busybox make-symlinks static" > /usr/armv7a-hardfloat-linux-gnueabi/etc/portage/package.use/busybox
    # mask 1.24.1 as it breaks with uclibc -> undefined reference to 'syncfs'
#    echo "=sys-apps/busybox-1.24.1" >> /usr/armv7a-hardfloat-linux-gnueabi/etc/portage/package.mask/busybox
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    # log dir, root home dir
    mkdir -p $EMERGE_ROOT/var/log $EMERGE_ROOT/root
    # busybox crond setup
    mkdir -p $EMERGE_ROOT/var/spool/cron/crontabs
    chmod 0600 $EMERGE_ROOT/var/spool/cron/crontabs
}
