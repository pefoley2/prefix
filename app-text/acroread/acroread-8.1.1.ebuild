# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/acroread/acroread-8.1.1.ebuild,v 1.3 2007/09/28 18:05:43 kevquinn Exp $

EAPI="prefix"

inherit eutils nsplugins

DESCRIPTION="Adobe's PDF reader"
HOMEPAGE="http://www.adobe.com/products/acrobat/"
IUSE="cups ldap nsplugin"

SRC_HEAD="http://ardownload.adobe.com/pub/adobe/reader/unix/8.x/${PV}"
SRC_FOOT="-${PV}-1.i486.tar.bz2"

#LINGUA_LIST="en:enu de:deu fr:fra sv:sve es:esp pt:ptb nb:nor it:ita fi:suo nl:nld da:dan ja:jpn ko:kor zh_CN:chs zh_TW:cht"
LINGUA_LIST="en:enu"
SRC_URI=
DEFAULT_URI="${SRC_HEAD}/enu/AdobeReader_enu${SRC_FOOT}"
for ll in ${LINGUA_LIST}; do
	iuse_l="linguas_${ll/:*}"
	src_l=${ll/*:}
	IUSE="${IUSE} ${iuse_l}"
	DEFAULT_URI="!${iuse_l}? ( ${DEFAULT_URI} )"
	SRC_URI="${SRC_URI}
		${iuse_l}? ( ${SRC_HEAD}/${src_l}/AdobeReader_${src_l}${SRC_FOOT} )"
done
SRC_URI="${SRC_URI}
	${DEFAULT_URI}
	x86? ( !cups? ( mirror://gentoo/libcups.so-i386.bz2 ) )"

LICENSE="Adobe"
SLOT="0"
# NOTE - Do not go stable until all language variants are released for this version
KEYWORDS="~amd64 ~x86"
RESTRICT="strip mirror"

# Needs libgtkembedmoz.so, which can come from xulrunner or mozilla-firefox.
# In the case of mozilla-firefox, need to create /etc/gre.d/gre.conf with
# GRE_PATH set to the /usr/lib/mozilla-firefox
# TODO: sort out libgtkembedmoz.so for amd64.
RDEPEND="x86? ( >=x11-libs/gtk+-2.0
			cups? ( net-print/cups )
			ldap? ( net-nds/openldap )
			|| ( net-libs/xulrunner
				www-client/mozilla-firefox ) )
	amd64? ( >=app-emulation/emul-linux-x86-baselibs-2.4.2
			>=app-emulation/emul-linux-x86-gtklibs-2.0 )"
QA_TEXTRELS="opt/Acrobat8/Reader/intellinux/plug_ins/PPKLite.api
	opt/Adobe/Adobe/Reader8/Browser/intellinux/nppdf.so
	opt/netscape/plugins/nppdf.so"
QA_EXECSTACK="opt/Adobe/Adobe/Reader8/Reader/intellinux/plug_ins/Annots.api
	opt/Adobe/Adobe/Reader8/Reader/intellinux/plug_ins/PPKLite.api
	opt/Adobe/Adobe/Reader8/Reader/intellinux/bin/acroread
	opt/Adobe/Adobe/Reader8/Reader/intellinux/bin/SynchronizerApp-binary
	opt/Adobe/Adobe/Reader8/Reader/intellinux/lib/libsccore.so
	opt/Adobe/Adobe/Reader8/Reader/intellinux/lib/libcrypto.so.0.9.7"

INSTALLDIR=/opt/Adobe

S=${WORKDIR}/AdobeReader

# Actually, ahv segfaults when run standalone so presumably
# it isn't intended for direct use - so the only launcher is
# acroread after all.
LAUNCHERS="Adobe/Reader8/bin/acroread"
#	Adobe/HelpViewer/1.0/intellinux/bin/ahv"

pkg_setup() {
	# x86 binary package, ABI=x86
	# Danny van Dyk <kugelfang@gentoo.org> 2005/03/25
	has_multilib_profile && ABI="x86"
}

# Determine lingua from filename
acroread_get_ll() {
	local f_src_l ll lingua src_l
	f_src_l=${1/${SRC_FOOT}}
	f_src_l=${f_src_l/*_}
	for ll in ${LINGUA_LIST}; do
		lingua=${ll/:*}
		src_l=${ll/*:}
		if [[ ${src_l} == ${f_src_l} ]]; then
			echo ${lingua}
			return
		fi
	done
	die "Failed to match file $1 to a LINGUA; please report"
}

src_unpack() {
	local ll linguas fl launcher
	# Unpack all into the same place; overwrite common files.
	fl=""
	for pkg in ${A}; do
		cd ${WORKDIR}
		unpack ${pkg}
		cd ${S}
		if [[ ${pkg} =~ ^AdobeReader_ ]]; then
			tar xf ILINXR.TAR ||
				die "Failed to unpack ILINXR.TAR; is distfile corrupt?"
			tar xf COMMON.TAR ||
				die "Failed to unpack COMMON.TAR; is distfile corrupt?"
			# Don't know if this is still necessary or not...
			#epatch ${FILESDIR}/acroread-scim.patch
			# Don't know if this is still necessary or not...
			#epatch ${FILESDIR}/acroread-low-startup-fontissue.patch
			# Old under-quoted expr functions no longer appear
			#epatch ${FILESDIR}/acroread-expr.patch
			ll=$(acroread_get_ll ${pkg})
			for launcher in ${LAUNCHERS}; do
				mv ${launcher} ${launcher}.${ll}
			done
			if [[ -z ${fl} ]]; then
				fl=${ll}
				linguas="${ll}"
			else
				linguas="${linguas} ${ll}"
			fi
		fi
	done
	if [[ ${linguas} == ${fl} ]]; then
		# Only one lingua selected - skip building the wrappers
		for launcher in ${LAUNCHERS}; do
			mv ${launcher}.${fl} ${launcher} ||
				die "Failed to put ${launcher}.${fl} back to ${launcher}; please report"
		done
	else
		# Build wrappers.  Launch the acroread for the environment variable
		# LANG (matched with a trailing * so that for example 'de_DE' matches
		# 'de', 'en_GB' matches 'en' etc).
		#
		# This is a bit premature at the moment on 8.1.1, for two reasons:
		# 1) The only language issued so far by Adobe is English, and the
		#    provided launcher doesn't bring out its strings separately
		#    (indicating internationalisation hasn't yet begin for 8.1.1)
		# 2) HelpViewer is new - I don't know if Adobe are likely to
		#    internationalise it or not.
		for launcher in ${LAUNCHERS}; do
			cat > ${launcher} <<-EOF
				#!/bin/bash
				# Copyright 1999-2007 Gentoo Foundation
				# Distributed under the terms of the GNU General Public License v2
				#
				# Automatically generated by ${CATEGORY}/${PF}

				# Exec the acroread script for the language chosen in
				# LC_ALL/LC_MESSAGES/LANG (first found takes precedence, as in glibc)
				L=\${LC_ALL}
				L=\${L:-\${LC_MESSAGES}}
				L=\${L:-\${LANG}}
				case \${L} in
			EOF
			for ll in ${linguas}; do
				echo "${ll}*) exec ${INSTALLDIR}/${launcher}.${ll} \"\$@\";;" >> ${launcher}
			done
			# default to English (in particualr for LANG=C)
			cat >> ${launcher} <<-EOF
				*) exec ${INSTALLDIR}/${launcher}.${fl} "\$@";;
				esac
			EOF
			chmod 755 ${launcher}
		done
	fi
}

src_install() {
	local dir

	# Install desktop files
	domenu Adobe/Reader8/Resource/Support
	# Install Icons - choose 48x48 since that's what the previous versions
	# supplied.
	doicon Adobe/Reader8/Resource/Icons/48x48

	dodir /opt
	chown -R --dereference -L root:0 Adobe
	cp -dpR Adobe ${ED}opt/

	# The Browser_Plugin_HowTo.txt is now in a subdirectory, which
	# is named according to the language the user is using.
	# Ie. for German, it is in a DEU directory.	See bug #118015
	#dodoc Browser/${LANG_TAG}/Browser_Plugin_HowTo.txt
	dodoc Adobe/Reader8/Browser/HowTo/*/Browser_Plugin_HowTo.txt

	if use nsplugin ; then
		exeinto /opt/netscape/plugins
		doexe Adobe/Reader8/Browser/intellinux/nppdf.so
		inst_plugin /opt/netscape/plugins/nppdf.so
	fi

	if ! use ldap ; then
		rm ${ED}${INSTALLDIR}/Reader8/Reader/intellinux/plug_ins/PPKLite.api
	fi

	# libcups is needed for printing support (bug 118417)
	if use x86 && ! use cups ; then
		mv ${WORKDIR}/libcups.so-i386 ${WORKDIR}/libcups.so.2
		exeinto ${INSTALLDIR}/Reader8/Reader/intellinux/lib
		doexe ${WORKDIR}/libcups.so.2
		dosym libcups.so.2 ${INSTALLDIR}/Reader8/Reader/intellinux/lib/libcups.so
	fi

	dodir /opt/bin
	for launcher in ${LAUNCHERS}; do
		dosym /opt/${launcher} /opt/bin/${launcher/*bin\/}
	done

#	# fix wrong directory permissions (bug #25931)
#	find ${ED}${INSTALLDIR}/. -type d | xargs chmod 755 || die
}

pkg_postinst () {
	local ll lc
	grep -q GRE_PATH= /etc/gre.d/* 2> /dev/null
	if [[ $? != "0" ]]; then
		for lib in /usr/lib/mozilla-firefox; do
			if [[ -f ${lib}/libgtkembedmoz.so ]]; then
				mkdir -p /etc/gre.d
				cat > /etc/gre.d/gre.conf <<-EOF
					GRE_PATH=${lib}
				EOF
				einfo "Acrobat Reader depends on libgtkembedmoz.so, which I've found"
				einfo "on your system in ${lib}, and configured in /etc/gre.d/gre.conf"
				break # don't search any more libraries
			fi
		done
	fi
	use ldap ||
		elog "The Acrobat(TM) Security Plugin can be enabled with USE=ldap"
	use nsplugin ||
		elog "The Acrobat(TM) Browser Plugin can be enabled with USE=nsplugin"
	lc=0
	for ll in ${LINGUA_LIST}; do
		use linguas_${ll/:*} && (( lc = ${lc} + 1 ))
	done
	if [[ ${lc} > 1 ]]; then
		elog "Multiple languages have been installed, selected via a wrapper script."
		elog "The language is selected according to the LANG environment variable"
		elog "(defaulting to English if LANG is not set, or no matching language"
		elog "version is installed).  Users may need to remove their preferences in"
		elog "~/.adobe to switch languages."
	fi
	grep -q GRE_PATH= /etc/gre.d/* 2> /dev/null
	if [[ $? != "0" ]]; then
		ewarn "Acrobat Reader depends dynamically on libgtkembedmoz.so, which should"
		ewarn "come with Mozilla Firefox or XULRunner, however it couldn't be found."
		ewarn "The first time you start acroread, it will complain about this, telling"
		ewarn "you to add the path to it to your preferences.  Clear the error dialog,"
		ewarn "close the Beyond Acrobat Reader dialog, go to Edit -> Preferences -> Internet"
		ewarn "and set the libgtkembedmoz directory to the place where it exists,"
		ewarn "then close and restart acroread."
	fi
}
