# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit elisp-common toolchain-funcs wrapper

DESCRIPTION="Dialect of Scheme designed for Systems Programming"
HOMEPAGE="
	https://cons.io/
	https://github.com/vyzo/gerbil
"

if [[ "${PV}" == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/vyzo/${PN}.git"
else
	SRC_URI="https://github.com/vyzo/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="Apache-2.0 LGPL-2.1"
SLOT="0"
IUSE="emacs leveldb lmdb mysql +sqlite +xml yaml +zlib"

BDEPEND="
	emacs? ( >=app-editors/emacs-23.1:* )
"
DEPEND="
	dev-scheme/gambit
	leveldb? ( dev-libs/leveldb )
	lmdb? ( dev-db/lmdb )
	mysql? ( dev-db/mariadb:* )
	sqlite? ( dev-db/sqlite )
	xml? ( dev-libs/libxml2 )
	yaml? ( dev-libs/libyaml )
	zlib? ( sys-libs/zlib )
"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${P}/src"

src_prepare() {
	default

	sed -i "s|gcc|$(tc-getCC)|g" ./build.sh || die "Failed to fix CC setting"
	sed -i "s|-O2|${CFLAGS}|g" ./build.sh || die "Failed to fix CFLAGS setting"
}

src_configure() {
	# Just to be safe, because './configure --help' says:
	# "Set default GERBIL_HOME (environment variable still overrides)"
	unset GERBIL_HOME

	local myconf=(
		$(use_enable leveldb)
		$(use_enable lmdb)
		$(use_enable mysql)
		$(use_enable xml libxml)
		$(use_enable yaml libyaml)
		$(usex sqlite '' '--disable-sqlite')
		$(usex zlib '' '--disable-zlib')
		--prefix="${D}/usr/share/${PN}"
	)
	# This is not a standard 'configure' script!
	gsi ./configure "${myconf[@]}" \
		|| die "Failed to configure using the 'configure' script"
}

src_compile() {
	# The 'build.sh' script uses environment variables that are exported
	# by portage, ie.: CFLAGS, LDFLAGS, ...
	sh ./build.sh \
		|| die "Failed to compile using the 'build.sh' script"
}

src_install() {
	mkdir -p "${D}/usr/share/${PN}" \
		|| die "Failed to make ${D}/usr/share/${PN} directory"
	gsi ./install \
		|| die "Failed to install using the 'install' script"

	sed -i "s|${D}|${EPREFIX}|g" "${D}/usr/share/${PN}/bin/gxc" \
		|| die "Failed to fix the 'gxc' executable script"

	mv "${D}/usr/share/${PN}/share/emacs" "${D}/usr/share/emacs" \
		|| die "Failed to fix '/usr/share/emacs' install path"
	mv "${D}/usr/share/${PN}/share/${PN}/TAGS" "${D}/usr/share/${PN}/TAGS" \
		|| die "Failed to fix '/usr/share/gerbil/TAGS' install path"

	# Compile the 'gerbil-mode.el'
	# FIXME: Doesn't autoload
	if use emacs; then
		pushd "${D}/usr/share/emacs/site-lisp/gerbil" || die
		elisp-compile *.el || die
		popd || die
	fi

	# Create wrappers for gerbil executables in GERBIL_HOME (/usr/share/gerbil)
	pushd "${D}/usr/share/${PN}/bin" || die
	local gx_bin
	for gx_bin in *; do
		make_wrapper "${gx_bin}" "env GERBIL_HOME=\"${EPREFIX}/usr/share/${PN}\" ${EPREFIX}/usr/share/${PN}/bin/${gx_bin}"
	done
	popd || die

	# Without this the programs compiled with gxc will break!
	# FIXME: Patch gerbil to compile with te correct 'GERBIL_HOME'?
	insinto "/etc/profile.d"
	doins "${FILESDIR}/gerbil_home.sh"
}

pkg_postinst() {
	use emacs && elisp-site-regen
}

pkg_postrm() {
	use emacs && elisp-site-regen
}
