# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-gfx/sam2p/sam2p-0.46.ebuild,v 1.1 2009/06/24 18:48:05 aballier Exp $

inherit toolchain-funcs eutils autotools

DESCRIPTION="Utility to convert raster images to EPS, PDF and many others"
HOMEPAGE="http://www.inf.bme.hu/~pts/sam2p/"
SRC_URI="http://www.inf.bme.hu/~pts/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="examples gif"
DEPEND="dev-lang/perl"
RDEPEND="virtual/libc"

RESTRICT="test"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/${PN}-0.45-fbsd.patch"
	epatch "${FILESDIR}/${PN}-0.45-nostrip.patch"
	epatch "${FILESDIR}/${PN}-0.45-cflags.patch"
	# force an US locale, otherwise make Makedep will bail out
	epatch "${FILESDIR}"/${PN}-0.45-locales.patch
	eautoreconf
}

src_compile() {
	tc-export CXX
	econf --enable-lzw $(use_enable gif) || die "econf failed"
	emake || die "make failed"
}

src_install() {
	dobin sam2p || die "Failed to install sam2p"
	dodoc README
	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*
	fi
}
