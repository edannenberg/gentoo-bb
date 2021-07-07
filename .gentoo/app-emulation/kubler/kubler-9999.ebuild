# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A generic, extendable build orchestrator."
HOMEPAGE="https://github.com/edannenberg/kubler.git"
LICENSE="GPL-2"

inherit bash-completion-r1

if [[ ${PV} = *9999* ]]; then
    inherit git-r3
    EGIT_REPO_URI="https://github.com/GITHUB_REPOSITORY"
    EGIT_BRANCH="GITHUB_REF"
else
    SRC_URI="https://github.com/GITHUB_REPOSITORY/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

KEYWORDS=""
IUSE="+docker podman +rlwrap test"
SLOT="0"

RDEPEND="dev-vcs/git
    docker? ( app-emulation/docker app-misc/jq )
    podman? ( app-emulation/libpod )
    rlwrap? ( app-misc/rlwrap )"
DEPEND="test? (
    ${RDEPEND}
    dev-tcltk/expect
    dev-util/bats-assert
    dev-util/bats-file )"

src_test() {
    bats --recursive --tap tests || die "Tests failed"
}

src_install() {
    insinto /usr/share/${PN}
    doins -r bin/ cmd/ engine/ lib/ template/ kubler.conf kubler.sh README.md COPYING

    fperms 0755 /usr/share/${PN}/kubler.sh
    fperms 0755 /usr/share/${PN}/engine/docker/bob-core/build-root.sh
    fperms 0755 /usr/share/${PN}/engine/docker/bob-core/portage-git-sync.sh
    fperms 0755 /usr/share/${PN}/engine/docker/bob-core/sed-or-die.sh
    fperms 0755 /usr/share/${PN}/engine/docker/bob-core/etc/portage/postsync.d/eix
    fperms 0755 /usr/share/${PN}/lib/ask.sh

    dosym /usr/share/${PN}/kubler.sh /usr/bin/kubler

    insinto /etc/
    doins kubler.conf

    newbashcomp lib/kubler-completion.bash ${PN}
}

pkg_postinst() {
    elog
    elog "Kubler's documentation can be found at /usr/share/kubler/README.md"
    elog
    elog "Installing app-shells/bash-completion is highly recommended!"
    elog
}
