### kubler/webhook:20170318

Built: Sat Mar 18 08:51:31 CET 2017
Image Size: 132 MB

#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r7 | `-static -static-libs`
app-crypt/gnupg-2.1.18 | `bzip2 gnutls nls readline smartcard -doc -ldap (-selinux) -tofu -tools -usb -wks-server`
app-crypt/pinentry-0.9.7-r1 | `ncurses -caps -emacs -gnome-keyring -gtk -qt4 -qt5 -static`
app-eselect/eselect-lib-bin-symlink-0.1.1 | ``
app-eselect/eselect-pinentry-0.7 | ``
app-eselect/eselect-python-20160516 | ``
app-misc/mime-types-9 | ``
dev-lang/python-2.7.12 | `hardened readline ssl (threads) (wide-unicode) xml (-berkdb) -build -doc -examples -gdbm -ipv6 (-libressl) -ncurses -sqlite -tk -wininst`
dev-lang/python-exec-2.4.4 | ` `
dev-libs/expat-2.2.0-r1 | `unicode -examples -static-libs`
dev-libs/gmp-6.1.0 | `asm cxx -doc -pgo -static-libs`
dev-libs/libassuan-2.4.3 | `-static-libs`
dev-libs/libffi-3.2.1 | `pax`
dev-libs/libgcrypt-1.7.3 | `-doc -static-libs`
dev-libs/libgpg-error-1.24 | `nls -common-lisp -static-libs`
dev-libs/libksba-1.3.5 | `-static-libs`
dev-libs/libltdl-2.4.6 | `-static-libs`
dev-libs/libpcre-8.39 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/libtasn1-4.10 | `-doc -static-libs -valgrind`
dev-libs/libxml2-2.9.4-r1 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-libs/nettle-3.2-r1 | `gmp -doc (-neon) -static-libs {-test}`
dev-libs/npth-1.2 | `-static-libs`
dev-scheme/guile-1.8.8-r3 | `deprecated nls readline regex threads -debug -debug-freelist -debug-malloc -discouraged -emacs -networking`
dev-vcs/git-2.10.2 | `blksha1 curl gpg iconv nls pcre python threads webdav -cgi -cvs -doc -emacs -gnome-keyring -gtk -highlight (-libressl) -mediawiki -mediawiki-experimental -perl (-ppcsha1) -subversion {-test} -tk -xinetd`
net-dns/libidn-1.33 | `nls -doc -emacs -java -mono -static-libs`
net-libs/gnutls-3.3.26 | `crywrap cxx nls openssl zlib -dane -doc -examples -guile -pkcs11 -static-libs {-test}`
sys-devel/autogen-5.18.4 | `-libopts -static-libs`
sys-devel/gettext-0.19.7 | `acl cxx nls openmp -cvs -doc -emacs -git -java -ncurses -static-libs`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/bash** |
app-admin/eselect-1.4.5 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.62 | `nls -static`
app-shells/bash-4.3_p48-r1 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.53.0 | `ssl threads -adns -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.25 | `acl nls (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static -vanilla`
sys-apps/file-5.29 | `zlib -python -static-libs`
sys-apps/sed-4.2.2 | `acl nls (-selinux) -static`
sys-libs/ncurses-6.0-r1 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-6.3_p8-r3 | `-static-libs -utils`
**FROM kubler/openssl** |
app-misc/ca-certificates-20161102.3.27.2-r2 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2k | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.7 | `-static`
sys-libs/zlib-1.2.11 | `-minizip -static-libs`
**FROM kubler/s6** |
dev-lang/execline-2.2.0.0 | `-static -static-libs`
dev-libs/skalibs-2.4.0.2 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.4.0.0 | `-static -static-libs`
*manual install*: entr-3.6 | http://entrproject.org/
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.23-r3 | `hardened rpc -audit -caps -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2016h | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.25.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
