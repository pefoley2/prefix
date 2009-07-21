# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/convert-ascii-armour/convert-ascii-armour-1.4.ebuild,v 1.23 2009/07/19 17:46:44 tove Exp $

inherit perl-module

MY_P=Convert-ASCII-Armour-${PV}
S=${WORKDIR}/${MY_P}
DESCRIPTION="Convert binary octets into ASCII armoured messages."
HOMEPAGE="http://search.cpan.org/~vipul/"
SRC_URI="mirror://cpan/authors/id/V/VI/VIPUL/${MY_P}.tar.gz"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~x86-macos"
IUSE=""

DEPEND="virtual/perl-IO-Compress
	virtual/perl-Digest-MD5
	virtual/perl-MIME-Base64
	dev-lang/perl"
