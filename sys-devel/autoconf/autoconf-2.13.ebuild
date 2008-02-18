# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/autoconf/autoconf-2.13.ebuild,v 1.17 2007/09/08 06:25:56 vapier Exp $

EAPI="prefix"

inherit eutils

DESCRIPTION="Used to create autoconfiguration files"
HOMEPAGE="http://www.gnu.org/software/autoconf/autoconf.html"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="${PV:0:3}"
KEYWORDS="~ppc-aix ~x86-freebsd ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE=""

DEPEND=">=sys-apps/texinfo-4.3
	sys-devel/autoconf-wrapper
	=sys-devel/m4-1.4*
	dev-lang/perl"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-gentoo.patch
	epatch "${FILESDIR}"/${P}-destdir.patch
	epatch "${FILESDIR}"/${P}-test-fixes.patch #146592
	touch configure # make sure configure is newer than configure.in

	rm -f standards.{texi,info} # binutils installs this infopage

	sed -i \
		-e 's|\* Autoconf:|\* Autoconf v2.1:|' \
		-e '/START-INFO-DIR-ENTRY/ i INFO-DIR-SECTION GNU programming tools' \
		autoconf.texi \
		|| die "sed failed"
}

src_compile() {
	# need to include --exec-prefix and --bindir or our
	# DESTDIR patch will trigger sandbox hate :(
	econf \
		--exec-prefix="${EPREFIX}"/usr \
		--bindir="${EPREFIX}"/usr/bin \
		--program-suffix="-${PV}" \
		|| die
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die

	dodoc AUTHORS NEWS README TODO \
		ChangeLog ChangeLog.0 ChangeLog.1

	mv "${ED}"/usr/share/info/autoconf{,-${PV}}.info
}
