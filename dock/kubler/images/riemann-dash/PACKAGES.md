### kubler/riemann-dash:20170318

Built: Sat Mar 18 08:39:34 CET 2017
Image Size: 222 MB

#### Installed
Package | USE Flags
--------|----------
dev-libs/libgcrypt-1.7.3 | `-doc -static-libs`
dev-libs/libgpg-error-1.24 | `nls -common-lisp -static-libs`
dev-libs/libxslt-1.1.29-r1 | `crypt -debug -examples -python -static-libs`
sys-libs/zlib-1.2.11 | `-minizip -static-libs`
*gem install*: riemann-client riemann-tools riemann-dash | https://github.com/aphyr/riemann
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/ruby-gcc** |
app-arch/bzip2-1.0.6-r7 | `-static -static-libs`
app-eselect/eselect-ruby-20161226 | ``
dev-lang/ruby-2.4.0 | `berkdb rdoc ssl -debug -doc -examples -gdbm -ipv6 -jemalloc -libressl -rubytests -socks5 -tk -xemacs`
dev-libs/glib-2.48.2 | `mime xattr -dbus -debug (-fam) (-selinux) -static-libs -systemtap {-test} -utils`
dev-libs/libffi-3.2.1 | `pax`
dev-libs/libpcre-8.39 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/libxml2-2.9.4-r1 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-libs/libyaml-0.1.7 | `-doc -examples -static-libs {-test}`
dev-ruby/did_you_mean-1.1.0 | `{-test}`
dev-ruby/json-2.0.2 | `-doc {-test}`
dev-ruby/minitest-5.10.1 | `-doc {-test}`
dev-ruby/net-telnet-0.1.1-r1 | `-doc {-test}`
dev-ruby/pkg-config-1.1.7 | `{-test}`
dev-ruby/power_assert-0.4.1 | `-doc {-test}`
dev-ruby/rake-12.0.0 | `-doc {-test}`
dev-ruby/rdoc-5.0.0-r2 | `-doc {-test}`
dev-ruby/rubygems-2.6.8 | `-server {-test}`
dev-ruby/test-unit-3.2.3 | `-doc {-test}`
dev-ruby/xmlrpc-0.2.1 | `-doc {-test}`
dev-util/pkgconfig-0.28-r2 | `hardened -internal-glib`
sys-libs/db-5.3.28-r2 | `cxx -doc -examples -java -tcl {-test}`
x11-misc/shared-mime-info-1.4 | `{-test}`
**FROM kubler/gcc** |
dev-libs/gmp-6.1.0 | `asm cxx -doc -pgo -static-libs`
dev-libs/mpc-1.0.2-r1 | `-static-libs`
dev-libs/mpfr-3.1.3_p4 | `-static-libs`
sys-devel/binutils-2.26.1 | `cxx nls -multitarget -static-libs {-test} -vanilla`
sys-devel/binutils-config-5-r3 | ``
sys-devel/gcc-4.9.4 | `cxx hardened nls nptl openmp vtv (-altivec) (-awt) -cilk -debug -doc (-fixed-point) -fortran -gcj -go -graphite (-libssp) (-multilib) -nopie -nossp -objc -objc`
sys-devel/gcc-config-1.7.3 | ``
sys-devel/make-4.2.1 | `nls -guile -static`
sys-kernel/linux-headers-4.4 | ``
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
- [ ] Headers
- [x] Static Libs

#### Included
- [x] Headers from kubler/glibc
- [x] Static Libs from kubler/glibc
