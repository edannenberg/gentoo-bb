> [Wikipedia](https://en.wikipedia.org/wiki/Cooper_%28profession%29#.22Cooper.22_as_a_name) said:
In much the same way as the trade or vocation of smithing produced the common English surname Smith
and the German name Schmidt, the cooper trade is also the origin of German names like Kübler.
>
> There is still demand for high-quality ~~wooden barrels~~ containers, and it is thought that the
highest-quality ~~barrels~~ containers are those hand-made by professional ~~coopers~~ kublers.

Kubler
======

A generic, extendable build orchestrator, in Bash. The default batteries focus on creating and maintaining
Docker base images.

#### Table Of Contents

- [Why Should You Care?](#why-should-you-care)
- [Requirements](#requirements)
  - [Kubler](#kubler)
  - [Docker](#docker)
- [Installation](#installation)
  - [On Gentoo](#on-gentoo)
  - [On macOS](#on-macos)
  - [Manual Installation](#manual-installation)
  - [Initial Configuration](#initial-configuration)
  - [Uninstall](#uninstall)
- [Tour de Kubler](#tour-de-kubler)
  - [The Basics](#the-basics)
  - [Every Image needs a Home - Working Dirs and Namespaces](#every-image-needs-a-home---working-dirs-and-namespaces)
  - [Hello Image](#hello-image)
  - [Anatomy of an Image](#anatomy-of-an-image)
  - [Understanding the Build Process](#understanding-the-build-process)
  - [But Does it Work? - Image Tests](#but-does-it-work---image-tests)
  - [Common Build Pitfalls](#common-build-pitfalls)
  - [Custom Build Containers](#custom-build-containers)
    - [Extend Existing Builder](#extend-existing-builder)
    - [New Builder from Scratch](#new-builder-from-scratch)
  - [Updating Build Containers](#updating-build-containers)
  - [Pushing Images to a Docker Repository](#pushing-images-to-a-docker-repository)
  - [Handling Software that doesn't have an Ebuild (yet ;)](#handling-software-that-doesnt-have-an-ebuild-yet-)
- [Other Resources](#other-resources)
- [Discord](#discord)

## Why Should You Care?

Perhaps:

1. You love Docker but are annoyed by some of the restrictions of it's `build` command that keep
   getting into your way. Wouldn't it be nice if you could `docker build` your images with all
   `docker run` args, like `-v`, at your disposal? Or if your `Dockerfile` was fully parameterizable?
2. You are a SysAdmin or DevOps engineer who seeks complete governance over the contents of their
   container images, with full control of the update cycle and the ability to track *all* software
   version changes from a centralized vcs repository.
3. You need to manage a **lot** of Docker base/service images in a sane way and want peace of mind
   with automated post-build tests.
4. You are a Gentoo user and want to build slim Docker images with a toolset you are familiar with. Not having
   to wrestle with CrossDev would also be a plus.
5. You are looking for an interactive OS host agnostic Gentoo playground or portable ebuild
   development environment.
6. You want to create custom root file systems, possibly for different cpu architectures
   and/or libc implementations (i.e. musl, uclibc, etc) in an isolated and repeatable manner.

## Requirements

#### Kubler

* Bash version 4.2+, using 4.4+ is highly recommended due to bugs in previous versions.

Optional:

* GPG for download verification
* rlwrap for command history

#### Docker or Podman

* Working Docker or Podman setup
* Git
* jq to parse Docker/Podman json output

## Installation

#### On Gentoo

An ebuild can be found at https://github.com/edannenberg/kubler-overlay/

Add the overlay (see link for instructions) and install as usual:

    emerge -av kubler

#### On macOS

The standard version of Bash in macOS is too old. Easiest way to upgrade to a later version is to use
[Homebrew](https://brew.sh/). Once Homebrew is installed, update Bash:

```
    $ brew install bash
```

This will install an updated version of Bash in `/usr/local/bin/`. To make it your default shell, you need to edit
`Advanced Options...` in _System Preferences_. Just right-click your user icon to find the option.

Also, macOS does not load `~/.bashrc` by default, but uses `~/.bash_profile`, so when following the instructions
below, make sure to edit the correct file.

#### Manual Installation

Kubler has been tested on Gentoo, CoreOS and macOS. It should run on all Linux distributions.
Feel free to open an issue or ask on Discord if you run into problems.

1. Clone the repo or download/extract the release archive to a location of your choice, i.e.

```
    $ cd ~/tools/
    $ curl -L https://github.com/edannenberg/kubler/archive/master.tar.gz | tar xz
```

2. Optional, add `kubler.sh` to your path

The recommended way is to add the following at the end of your `~/.bashrc` file, don't forget to adjust the
Kubler path for each line accordingly:

    export PATH="${PATH}:/path/to/kubler/bin"
    # optional but highly recommended, adds bash completion support for all kubler commands
    source /path/to/kubler/lib/kubler-completion.bash

Note: You will need to open a new shell for this to take effect, if this fails on a Linux SystemD
host re-logging might be required instead.

#### Initial Configuration

Kubler doesn't require any further configuration but you may want to review the main config file
located at `/etc/kubler.conf`. If the file doesn't exist the `kubler.conf` file in Kubler's root folder is
used as a fallback.

All of Kubler's runtime data, like user config overrides, downloads or custom scripts, is kept at a path defined
via `KUBLER_DATA_DIR`. This defaults to `~/.kubler/`, which is suitable if user accounts have Docker/Podman access on the host.
If you plan to use Docker/Podman/Kubler only with `sudo`, like on a server, you may want to use `/var/lib/kubler`, or some other location, as data dir instead.

Managing your `KUBLER_DATA_DIR` with a VCS tool like Git is supported, a proper `.gitignore` is added on initialization.

#### Uninstall

1. Remove any build artifacts and container images created by Kubler:

```
    $ kubler clean -N
```

2. Remove Kubler itself:

    * On Gentoo and ebuild install: `emerge -C kubler` then remove the kubler overlay
    * Manual install: reverse the steps you did during manual installation

3. Delete any namespace dirs and configured `KUBLER_DATA_DIR` (default is `~/.kubler/`) you had in
   use, this may require su permissions.

## Tour de Kubler

### The Basics

To get a quick overview of available commands/options:

    $ kubler --help

Or to view details for a specific command:

    $ kubler build -h

Per default almost all of Kubler's commands will need to be run from a `--working-dir`, if the option is
omitted the current working dir of the executing shell is used. It behaves much like Git in that
regard, executing any Kubler command from a sub directory of a valid working dir will also work as
expected.

A `--working-dir` is considered valid if it has a `kubler.conf` file and either an `images/` dir, or
one ore more namespace dirs, which are just a collection of images.

Kubler currently ships with Docker and Podman build engines.
The rest of this tour will focus on building Docker images,
it's worth noting that the build process may be completely different, i.e. it may not involve Gentoo or Docker at all,
for other build engines.

If you are not familiar with Gentoo some of it's terms you will encounter may be confusing, a short 101 glossary:

| | |
|-|-|
| stage3          | A tar ball provided by Gentoo which on extraction provides an almost-complete root file system for a Gentoo installation |
| Portage         | Gentoo's default package manager, this is where all the magic happens |
| emerge          | Portage's main executable |
| ebuild          | text file which identifies a specific software package and how Portage should handle it |
| Portage Tree    | Categorized collection of ebuilds, Gentoo ships with ~20k ebuilds |
| Portage Overlay | Additional ebuild repository maintained by the community/yourself |

### Every Image needs a Home - Working Dirs and Namespaces

To accommodate different use cases there are three types of working dirs:

| | |
|-|-|
| multi  | The working dir is a collection of one or more namespace dirs |
| single | The working dir doubles as namespace dir, you can't create a new namespace in it, but you save a directory level |
| local  | Same as multi but `--working-dir` is equal to `KUBLER_DATA_DIR` |

First switch to a directory where you would like to store your Kubler managed images or namespaces:

    $ cd ~/projects

Then use the `new` command to take care of the boiler plate, choose 'single' when asked for the namespace type:

```
    $ kubler new namespace mytest
    $ cd mytest/
```

Although not strictly required it's recommended to install Kubler's example images by running:

    $ kubler update

### Hello Image

Let's start with a simple task and dockerize [Figlet][], a nifty tool that produces ascii fonts. First create a new
image stub:

    $ kubler new image mytest/figlet

When asked for the image parent, enter `kubler/bash` and `bt` when asked for tests:

```
»»» Extend an existing Kubler managed image? Fully qualified image id (i.e. kubler/busybox) or scratch
»[?]» Parent Image (scratch): kubler/bash
»»»
»»» Add test template(s)? Possible choices:
»»»   hc  - Add a stub for Docker's HEALTH-CHECK, recommended for images that run daemons
»»»   bt  - Add a stub for a custom build-test.sh script, a good choice if HEALTH-CHECK is not suitable
»»»   yes - Add stubs for both test types
»»»   no  - Fck it, we'll do it live!
»[?]» Tests (hc): bt
»»»
»[✔]» Successfully created new image at projects/mytest/images/figlet
```

A handy feature when working on a Kubler managed image is the `--interactive` build arg. As the name suggests it
allows us to poke around in a running build container and plan/debug the image build. Let's give it a try:

    $ kubler build mytest/figlet -i

This will also build any missing parent images/builders, so the first run may take quite a bit of time. Don't
worry, once the local binary package cache and build containers are seeded future runs will be much faster.
When everything is ready you are dropped into a new shell:

```
»[✔]»[kubler/bash]» done.
»»»»»[mytest/figlet]» using: docker / builder: kubler/bob-bash
kubler-bob-bash / #
```

To search Portage's package db you may use `eix`, or whatever your preferred method is:

```
kubler-bob-bash / # eix figlet
* app-misc/figlet
     Available versions:  2.2.5 ~2.2.5-r1
     Homepage:            http://www.figlet.org/
     Description:         program for making large letters out of ordinary text

* dev-php/PEAR-Text_Figlet
```

As with most package managers, software in Portage is grouped by categories. The category and package name combined
form a unique package atom, in our case we want to install `app-misc/figlet`.

Now manifest the new found knowledge by editing the image's build script:

```
    kubler-bob-bash / # nano /config/build.sh
```

Note: The `/config` folder in the build container is the host mounted image directory at `mytest/images/figlet/`.
Feel free to use your local IDE/editor to edit `build.sh` instead.

Add the `app-misc/figlet` package atom to the `_packages` variable in `build.sh`:

```
_packages="app-misc/figlet"
```

Then start a test run of the first build phase (more on that later), if you are in a hurry you may skip this step:

```
kubler-bob-bash / # kubler-build-root
```

Once this finishes exit the interactive builder by hitting `crtl+d` or typing `exit`. All that is left to do is
building the actual image:

    $ kubler build mytest/figlet -nF

The args are short hand for `--no-deps` and `--force-full-image-build`, omitting `-n` would also rebuild all
parent images, which can be handy but is just a waste of time in this case.

```
    »[✘]»[mytest/figlet]» fatal: build-test.sh for image mytest/figlet:20190228 failed with exit signal: 1
```

Oops, looks like we forgot the image test. Let's fix that by editing the mentioned `build-test.sh` file:

```
    #!/usr/bin/env sh
    set -eo pipefail

    # check figlet version string
    figlet -v | grep -A 2 'FIGlet Copyright' || exit 1
```

Not exactly exhausting but it will do for now. Rebuild the image again but this time only pass `-f` instead of `-F`,
this too forces an image rebuild but skips the first build phase:

```
$ kubler build mytest/figlet -nf
»[✔]»[mytest/figlet]» done.
$ docker run -it --rm mytest/figlet figlet foooo
```

### Anatomy of an Image

```
$ tree images/figlet
images/figlet/
├── Dockerfile            <- generated, never edit this manually
├── Dockerfile.template   <- standard Dockerfile, except it's fully parameterizable
├── PACKAGES.md           <- generated, lists all installed packages with version and use flags
├── README.md             <- optional, image specific documentation written by you
├── build-test.sh         <- optional, if the file exists it activates a post-build test
├── build.conf            <- general image/builder config, sourced on the host
├── build.sh              <- configures the first build phase, only sourced in build containers
```

The stub files generated with the `new` command are heavily commented with further details.

### Understanding the Build Process

After executing a build command an image dependency graph is generated for the passed target ids by parsing
the `IMAGE_PARENT` and `BUILDER` vars in the respective `build.conf` files. You can visualize the graph for any
given target ids with the `dep-graph` command:

    $ kubler dep-graph -b kubler/nginx mytest

Once all required data is gathered, each missing, as in not already built, image will go through a two phase
build process:

1. The configured builder image is passed to `docker run` to produce a `rootfs.tar` file in the image folder

    * mounts current image dir into a fresh build container as `/config`
    * executes `build-root.sh` (a generic script provided by Kubler) inside build container
    * `build-root.sh` reads `build.sh` from the mounted `/config` directory
    * if `configure_builder()` hook is defined in `build.sh`, execute it
    * `package.installed` file is generated which is used by depending images as [package.provided][]
    * `ROOT` env is set to custom path
    * if `configure_rootfs_build()` hook is defined in `build.sh`, execute it
    * `_packages` defined in `build.sh` are installed via Portage at custom empty root directory
    * if `finish_rootfs_build()` hook is defined in `build.sh`, execute it
    * `ROOT` dir is packaged as `rootfs.tar` and placed in image dir on the host
    * preserve exact builder state for child images by committing the used build container as a new builder image

The `build-root.sh` file effectively just uses a feature of Gentoo's package manager that allows us to install any given `_packages`,
with all it's dependencies, at a custom path by setting the `ROOT` env in the build container. The other piece to the
puzzle is Portage's [package.provided][] file which is constantly updated and preserved by committing the build
container as a new builder image after each build. Thanks to Docker's shared layers the overhead of this is fairly minimal.

Kubler's default build container names generally start with `bob`, when a new build container state is committed the
current image name gets appended. For example `kubler/bob-openssl` refers to the container used to build the `kubler/openssl` image.
Any image that has `kubler/openssl` as `IMAGE_PARENT` will use `kubler/bob-openssl` as it's build container.

There are no further assumptions or magic, the hooks in `build.sh` are just Bash functions so there are virtually no limits
on how you may produce the resulting `rootfs.tar`. You have a full Gentoo installation at your disposal, orchestrate away.

2. Image dir is passed to `docker build` as build context, the Dockerfile has a `ADD rootfs.tar /` entry

    * Dockerfile is generated from Dockerfile.template on each run
    * vars starting with `BOB_` in your `build.conf` can be used for parameterization, i.e. `BOB_FOO=bar`
    * produces the final image

This approach is basically an alternative to Docker's [multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/)
builds that also allows host mounts and `--privileged` builds in the first phase where all the heavy lifting is done.

### But Does it Work? - Image Tests

A successful image build doesn't always equal a functional image. Kubler supports two types of image tests that can be
run as part of the post-build process:

1. Docker's `HEALTH-CHECK`

    * set `POST_BUILD_HC=true` in `build.conf` to activate
    * configure the health-check as usual in `Dockerfile.template`
    * built image is run in detached mode and container health status is queried until it's `healthy` or timeout is
      reached

2. `build-test.sh`

    * if the file exists it is executed in the built image and the container exit signal is checked to determine success/error
    * file should be executable as it is only mounted for the test
    * good alternative when a Docker health-check doesn't make sense

### Common Build Pitfalls

First of all if you run into errors don't panic and look for a towel.. erm read the output carefully for hints. The log file
is located at `$KUBLER_DATA_DIR/log/build.log`. Some of the more common errors:

* Build fails due to missing files

Not all ebuilds support a custom `ROOT` properly, in almost all of those cases the problem boils down to the ebuild
trying to execute files at the actual build container root, when in reality the files it expects just got installed at the
custom root defined via `ROOT`.

The easiest solution is to install the failing package manually in the `configure_builder()` hook first:

```
_packages="dev-lang/foo"

configure_builder()
{
    # move any use flag/keywords config from configure_rootfs_build() hook to
    # reuse the resulting binary package, keeps overhead to a minimum
    emerge dev-lang/foo
}
```

While the above should always work, you may want to get a bit creative instead if the problem is obvious to resolve.
Example from `kubler/graph-easy`:

```
configure_rootfs_build()
{
    # graphviz ebuild calls 'dot -c || die' as part of post-install. Fake dot and run the setup via Dockerfile instead.
    ln -s /bin/true /usr/bin/dot
}

finish_rootfs_build()
{
    # remove the fake symlink, the actual dot binary is in ${_EMERGE_ROOT}/usr/bin/dot
    rm /usr/bin/dot
}
```

* Image was successfully built but can't find it's libraries on image run

This usually happens when the libs in question got installed at a new location which is not yet known to the system:

```
ImportError: libpq.so.5: cannot open shared object file: No such file or directory
```

The issue here is that the ebuild ran `ldconfig` during install but the change was done in the builder context and not
the custom root. Adding `RUN ldconfig` to your `Dockerfile.template` resolves the issue.

* Image build fails with Operation not permitted

```
strace: test_ptrace_setoptions_for_all: PTRACE_TRACEME doesn't work: Operation not permitted
```

Some packages like `glibc` require `SYS_PTRACE` permissions for the build container during installation, this can be configured
via `build.conf`:

```
    BUILDER_CAPS_SYS_PTRACE='true'
```

### Custom Build Containers

The default builders provided by Kubler should do just fine for most tasks, however you can customize the default builders
to your liking or create a new one from scratch.

#### Extend Existing Builder

Note that extending a builder is often overkill as you can also customize a builder in the `configure_builder()` hook of
any image's `build.sh`. The changes will persist to all depending image builds.

1. Create the new builder and set a parent:

```
    $ kubler new builder mytest/alice
    »»» Extend existing Kubler builder image? Fully qualified image id (i.e. kubler/bob) or stage3
    »[?]» Parent Image (stage3): kubler/bob
    »[✔]» Successfully created new builder at projects/mytest/builder/alice
```

2. Edit `build.sh` and customize away:

```
configure_builder()
{
    emerge app-editors/vim
    emerge -C app-editors/nano
    echo "nano is for plebs!" > ~/foo.txt
}
```

3. Set your builder as `DEFAULT_BUILDER` in your namespace or user `kubler.conf`

```
    DEFAULT_BUILDER="mytest/alice"
```

If you set this via user config your custom builder is also used for all images in the `kubler` namespace.

Note: You will need to rebuild with the `-c` arg for this to take effect:

    $ kubler build -c mytest

#### New Builder from Scratch

Pretty much the same process as above except:

1. Create the new builder but don't set a parent:

```
    $ kubler new builder mytest/s3b
    »»» Extend existing Kubler builder image? Fully qualified image id (i.e. kubler/bob) or stage3
    »[?]» Parent Image (stage3):
    »[✔]» Successfully created new builder at projects/mytest/builder/s3b
```

2. Additionally configure the used Gentoo stage3 file in `build.conf`:

```
    STAGE3_BASE='stage3-amd64-musl-hardened'
    ARCH='amd64'
    ARCH_URL="${MIRROR}experimental/${ARCH}/musl/"
```

The `ARCH_URL` should match the base path on Gentoo's distribution mirrors. Then run `kubler update` to fetch the latest stage3 date.

### Updating Build Containers

Gentoo is a rolling distribution, Portage updates happen daily. The provided stage3 files are updated frequently and only kept for a limited
time on Gentoo's servers and mirrors. To check for new releases:

    $ kubler update

This will also check for updates to the example images provided by Kubler, usually updated at the end of each month. If updates were found
found simply rebuild the stack by running:

    $ kubler clean
    $ kubler build -C mynamespace

### Pushing Images to a Docker Repository

To push images to Docker Hub:

    $ kubler push mytest somenamespace/someimage

The default assumes that the given namespace equals the respective Docker Hub account names, i.e. `mytest` and `somenamespace`.
To override this you may place a `push.conf` file in each namespace dir with the following format:

```
DOCKER_LOGIN=myacc
DOCKER_PW=mypassword
#DOCKER_EMAIL=foo@bar.net
```

### Handling Software that doesn't have an Ebuild (yet ;)

While Gentoo's package tree is fairly massive it's doesn't have everything or maybe not as bleeding edge as you would like.
In such cases you may try your luck on http://gpo.zugaina.org/ and search the community overlays that will cover an even
wider range of ebuilds. Just keep the security implications of downloading random strangers' ebuilds in mind. ;)

If you are still out of luck after trying the above you can do a manual install in the `finish_rootfs_hook()`,
as you usually would with a shell. However the recommended way is to maintain your own Portage overlay by writing an
ebuild file. Some study materials, sorted by complexity:

* [Quickstart Ebuild Guide](https://devmanual.gentoo.org/quickstart/index.html)
* [Basic guide to Gentoo Ebuilds](https://wiki.gentoo.org/wiki/Basic_guide_to_write_Gentoo_Ebuilds)
* [Gentoo Ebuild Writing](https://devmanual.gentoo.org/ebuild-writing/index.html)
* [Gentoo Ebuild Dev Guide](https://devmanual.gentoo.org/eclass-reference/ebuild/index.html)

It's a fairly straight forward affair, once you wrapped your head around it, that provides benefits over the manual approach.
For example you won't have to remember to strip the binaries after a manual installation.

The ebuild system is heavily modularized, a good approach is to study/copy existing ebuilds for similar software in the
Portage tree. You can browse Portage's ebuilds at `/var/db/repos/gentoo/` in any interactive build container. Often you
just need to find a good ebuild source and change a few trivial things to be done with it.

The [kubler-overlay](https://github.com/edannenberg/kubler-overlay) repo has some pointers on how to setup a ebuild dev
environment with Kubler.

## Other Resources

* [Building Hardened Docker Images from Scratch with Kubler](https://www.elttam.com.au/blog/kubler/) by [@berney][]
* [Gentoo as a Docker Build System?](https://youtu.be/bbC6HXUUjjg) by [@janoszen](https://github.com/janoszen)

* [Portage's Emerge Manual](https://wiki.gentoo.org/wiki/Portage#emerge)

## Discord

For questions or chatting with other users you may join our Discord server at:

https://discord.gg/rH9R7bc

Although you'll need to create an account on Discord email verification with Discord is disabled for now.

[LXC]: https://en.wikipedia.org/wiki/LXC
[bob-core]: https://github.com/edannenberg/kubler/tree/master/engine/docker/bob-core
[Figlet]: http://www.figlet.org/
[Docker]: https://www.docker.com/
[kubler-docker]: https://hub.docker.com/u/kubler/
[Gentoo]: https://www.gentoo.org/
[binary package]: https://wiki.gentoo.org/wiki/Binary_package_guide
[package.provided]: https://wiki.gentoo.org/wiki//etc/portage/profile/package.provided
[CoreOS]: https://coreos.com/
[@berney]: https://github.com/berney
[Argbash]: https://github.com/matejak/argbash
