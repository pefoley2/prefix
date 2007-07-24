# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/ncurses/ncurses-5.6-r1.ebuild,v 1.10 2007/07/23 01:40:58 kumba Exp $

EAPI="prefix"

inherit eutils flag-o-matic toolchain-funcs multilib

MY_PV=${PV:0:3}
PV_SNAP=${PV:4}
MY_P=${PN}-${MY_PV}
DESCRIPTION="console display library"
HOMEPAGE="http://www.gnu.org/software/ncurses/ http://dickey.his.com/ncurses/"
SRC_URI="mirror://gnu/ncurses/${MY_P}.tar.gz
	ftp://invisible-island.net/ncurses/${PV}/${P}-coverity.patch.gz"

LICENSE="MIT"
SLOT="5"
KEYWORDS="~amd64 ~ppc-aix ~ppc-macos ~sparc-solaris ~x86 ~x86-macos ~x86-solaris"
IUSE="bootstrap build debug doc gpm minimal nocxx trace unicode"

DEPEND="gpm? ( sys-libs/gpm )"

S=${WORKDIR}/${MY_P}

src_unpack() {
	unpack ${A}
	cd "${S}"
	[[ -n ${PV_SNAP} ]] && epatch "${WORKDIR}"/${MY_P}-${PV_SNAP}-patch.sh
	epatch "${WORKDIR}"/${P}-coverity.patch
	epatch "${FILESDIR}"/${PN}-5.6-gfbsd.patch
}

src_compile() {
	tc-export BUILD_CC

	# Protect the user from themselves #115036
	unset TERMINFO

	# From version 5.3, ncurses also build c++ bindings, and as
	# we do not have a c++ compiler during bootstrap, disable
	# building it.  We will rebuild ncurses after gcc's second
	# build in bootstrap.sh.
	local myconf=""
	( use build || use bootstrap || use nocxx ) \
		&& myconf="${myconf} --without-cxx --without-cxx-binding --without-ada"

	# First we build the regular ncurses ...
	mkdir "${WORKDIR}"/narrowc
	cd "${WORKDIR}"/narrowc
	do_compile ${myconf}

	# Then we build the UTF-8 version
	if use unicode ; then
		mkdir "${WORKDIR}"/widec
		cd "${WORKDIR}"/widec
		do_compile ${myconf} --enable-widec --includedir="${EPREFIX}"/usr/include/ncursesw
	fi
}
do_compile() {
	ECONF_SOURCE=${S}

	# We need the basic terminfo files in /etc, bug #37026.  We will
	# add '--with-terminfo-dirs' and then populate /etc/terminfo in
	# src_install() ...
	# The chtype/mmask-t settings below are to retain ABI compat
	# with ncurses-5.4 so dont change em !
	econf \
		--libdir="${EPREFIX}/usr/$(get_libdir)" \
		--with-terminfo-dirs="${EPREFIX}/etc/terminfo:${EPREFIX}/usr/share/terminfo" \
		--disable-termcap \
		--with-shared \
		--with-rcs-ids \
		--enable-symlinks \
		--enable-const \
		--with-chtype='long' \
		--with-mmask-t='long' \
		--with-manpage-format=normal \
		--enable-overwrite \
		$(use_with debug) \
		$(use_with gpm) \
		$(use_with trace) \
		"$@" \
		|| die "configure failed"

	# Fix for install location of the lib{,n}curses{,w} libs as in Gentoo we
	# want those in lib not usr/lib.  We cannot move them lateron after
	# installing, because that will result in broken install_names for
	# platforms that store pointers to the libs instead of directories.
	sed -i -e '/^libdir/s|usr/||' ncurses/Makefile || die "nlibdir"

	# A little hack to fix parallel builds ... they break when
	# generating sources so if we generate the sources first (in
	# non-parallel), we can then build the rest of the package
	# in parallel.  This is not really a perf hit since the source
	# generation is quite small.  -vapier
	emake -j1 sources || die "make sources failed"
	emake || die "make failed"
}

src_install() {
	# install unicode version second so that the binaries in /usr/bin
	# support both wide and narrow
	cd "${WORKDIR}"/narrowc
	emake DESTDIR="${D}" install || die "make narrowc install failed"
	if use unicode ; then
		cd "${WORKDIR}"/widec
		emake DESTDIR="${D}" install || die "make widec install failed"
	fi

	# Move static and extraneous ncurses static libraries out of /lib
	cd "${ED}"/$(get_libdir)
	mv *.a "${ED}"/usr/$(get_libdir)/
	gen_usr_ldscript lib{,n}curses$(get_libname)
	use unicode && gen_usr_ldscript lib{,n}cursesw$(get_libname)

	# We need the basic terminfo files in /etc, bug #37026
	einfo "Installing basic terminfo files in /etc..."
	for x in ansi console dumb linux rxvt screen sun vt{52,100,102,200,220} \
	         xterm xterm-color xterm-xfree86
	do
		local termfile=$(find "${ED}"/usr/share/terminfo/ -name "${x}" 2>/dev/null)
		local basedir=$(basename $(dirname "${termfile}"))

		if [[ -n ${termfile} ]] ; then
			dodir /etc/terminfo/${basedir}
			mv ${termfile} "${ED}"/etc/terminfo/${basedir}/
			dosym ../../../../etc/terminfo/${basedir}/${x} \
				/usr/share/terminfo/${basedir}/${x}
		fi
	done

	# Build fails to create this ...
	dosym ../share/terminfo /usr/$(get_libdir)/terminfo

	echo "CONFIG_PROTECT_MASK=\"/etc/terminfo\"" > "${T}"/50ncurses
	doenvd "${T}"/50ncurses

	use minimal && rm -r "${ED}"/usr/share/terminfo
	cd "${S}"
	dodoc ANNOUNCE MANIFEST NEWS README* TO-DO doc/*.doc
	use doc && dohtml -r doc/html/
}

pkg_preinst() {
	use unicode || preserve_old_lib /$(get_libdir)/libncursesw$(get_libname 5)
}

pkg_postinst() {
	use unicode || preserve_old_lib_notify /$(get_libdir)/libncursesw$(get_libname 5)
}
