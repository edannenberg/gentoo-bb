### kubler/nginx-php5.6:20170318

Built: Sat Mar 18 07:41:51 CET 2017
Image Size: 110 MB

#### Installed
Package | USE Flags
--------|----------
app-admin/eselect-1.4.5 | `-doc -emacs -vim-syntax`
app-admin/metalog-3-r1 | `unicode`
app-eselect/eselect-php-0.9.2 | `fpm -apache2`
dev-lang/php-5.6.30 | `acl bcmath berkdb bzip2 calendar cli crypt ctype curl fileinfo filter fpm gd hash iconv json mhash mysql mysqli nls opcache pcntl pdo phar posix readline session simplexml soap sockets ssl threads tokenizer unicode xml xmlreader xmlrpc xmlwriter xpm xslt zip zlib -apache2 -cdb -cgi -cjk -coverage -debug -embed -enchant -exif (-firebird) -flatfile -ftp -gdbm -gmp -imap -inifile -intl -iodbc -ipv6 -kerberos -ldap -ldap-sasl -libedit -libmysqlclient (-libressl) -mssql -oci8-instant-client -odbc -postgres -qdbm -recode (-selinux) -sharedmem -snmp -spell -sqlite -sybase-ct -systemd -sysvipc -tidy -truetype -vpx -wddx`
dev-libs/expat-2.2.0-r1 | `unicode -examples -static-libs`
dev-libs/gmp-6.1.0 | `asm cxx -doc -pgo -static-libs`
dev-libs/libbsd-0.8.3 | `-static-libs`
dev-libs/libgcrypt-1.7.3 | `-doc -static-libs`
dev-libs/libgpg-error-1.24 | `nls -common-lisp -static-libs`
dev-libs/libltdl-2.4.6 | `-static-libs`
dev-libs/libmcrypt-2.5.8-r4 | ``
dev-libs/libpthread-stubs-0.3-r1 | `-static-libs`
dev-libs/libtasn1-4.10 | `-doc -static-libs -valgrind`
dev-libs/libxml2-2.9.4-r1 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-libs/libxslt-1.1.29-r1 | `crypt -debug -examples -python -static-libs`
dev-libs/nettle-3.2-r1 | `gmp -doc (-neon) -static-libs {-test}`
dev-libs/oniguruma-5.9.5 | `-combination-explosion-check -crnl-as-line-terminator -static-libs`
dev-php/pecl-apcu-4.0.11 | `lock`
dev-php/pecl-apcu-5.1.8 | `lock`
dev-php/pecl-imagick-3.4.1 | `-examples {-test}`
dev-php/pecl-memcache-3.0.8-r1 | `session`
dev-php/pecl-redis-2.2.7-r1 | `-igbinary`
dev-php/xdebug-2.4.1 | ` `
dev-php/xdebug-client-2.4.1 | `-libedit`
mail-mta/nullmailer-1.13-r5 | `ssl`
media-gfx/imagemagick-6.9.7.4 | `bzip2 cxx zlib -`
media-libs/libjpeg-turbo-1.5.0 | `-java -static-libs`
media-libs/libpng-1.6.27 | `-apng (-neon) -static-libs`
net-dns/libidn-1.33 | `nls -doc -emacs -java -mono -static-libs`
net-libs/gnutls-3.3.26 | `crywrap cxx nls openssl zlib -dane -doc -examples -guile -pkcs11 -static-libs {-test}`
net-misc/curl-7.53.0 | `ssl threads -adns -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.25 | `acl nls (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static -vanilla`
sys-apps/file-5.29 | `zlib -python -static-libs`
sys-apps/sed-4.2.2 | `acl nls (-selinux) -static`
sys-apps/shadow-4.4-r2 | `acl cracklib nls xattr -audit -pam (-selinux) -skey`
sys-apps/util-linux-2.28.2 | `cramfs nls readline suid unicode -build -caps -fdformat -kill -ncurses -pam -python (-selinux) -slang -static-libs -systemd {-test} -tty-helpers -udev`
sys-devel/gettext-0.19.7 | `acl cxx nls openmp -cvs -doc -emacs -git -java -ncurses -static-libs`
sys-libs/cracklib-2.9.6-r1 | `nls zlib -python -static-libs {-test}`
sys-libs/db-5.3.28-r2 | `cxx -doc -examples -java -tcl {-test}`
sys-libs/ncurses-6.0-r1 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-6.3_p8-r3 | `-static-libs -utils`
x11-libs/libICE-1.0.9-r1 | `-doc -ipv6 -static-libs`
x11-libs/libSM-1.2.2-r1 | `uuid -doc -ipv6 -static-libs`
x11-libs/libX11-1.6.5 | `-doc -ipv6 -static-libs {-test}`
x11-libs/libXau-1.0.8 | `-static-libs`
x11-libs/libxcb-1.12-r2 | `-doc (-selinux) -static-libs {-test} -xkb`
x11-libs/libXdmcp-1.1.2-r1 | `-doc -static-libs`
x11-libs/libXext-1.3.3 | `-doc -static-libs`
x11-libs/libXpm-3.5.12 | `-static-libs`
x11-libs/libXt-1.1.5 | `-static-libs {-test}`
x11-libs/xtrans-1.3.5 | `-doc`
x11-proto/inputproto-2.3.2 | ``
x11-proto/kbproto-1.0.7 | ``
x11-proto/xextproto-7.3.0 | `-doc`
x11-proto/xf86bigfontproto-1.2.0-r1 | ``
x11-proto/xproto-7.0.31 | `-doc`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/nginx** |
app-arch/bzip2-1.0.6-r7 | `-static -static-libs`
dev-libs/libpcre-8.39 | `bzip2 cxx recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -readline -static-libs`
www-servers/nginx-1.11.10 | `http http-cache http2 pcre ssl threads -aio -debug -ipv6 -libatomic -luajit -mail -pam -pcre-jit -perftools -rrd (-selinux) -stream -vim-syntax`
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
