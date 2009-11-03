# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-extra/zenity/zenity-2.28.0.ebuild,v 1.1 2009/10/29 22:00:30 eva Exp $

inherit gnome2

DESCRIPTION="Tool to display dialogs from the commandline and shell scripts"
HOMEPAGE="http://www.gnome.org/"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="libnotify"

RDEPEND=">=x11-libs/gtk+-2.15.2
	>=dev-libs/glib-2.8
	>=dev-lang/perl-5
	libnotify? ( >=x11-libs/libnotify-0.4.1 )"

DEPEND="${RDEPEND}
	app-text/scrollkeeper
	>=dev-util/intltool-0.40
	>=sys-devel/gettext-0.14
	>=dev-util/pkgconfig-0.9
	>=app-text/gnome-doc-utils-0.10.1
	>=gnome-base/gnome-common-2.12.0"

DOCS="AUTHORS ChangeLog HACKING NEWS README THANKS TODO"

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-scrollkeeper
		$(use_enable libnotify)"
}
