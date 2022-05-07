# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit octaveforge

DESCRIPTION="Additional spline functions"
HOMEPAGE="https://octave.sourceforge.io/ga/index.html"

LICENSE="GPL-3+ public-domain"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=sci-mathematics/octave-3.6.0"
RDEPEND="${DEPEND}"
