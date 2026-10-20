#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Baut das Debian-Paket querencia-anmeldung mit den Werkzeugen des
# Repositorys querencia-packaging (Quellarchive, Cargo-Vendoring,
# dpkg-buildpackage auf einem Bau-Platz) und legt es mit SHA256SUMS nach
# build/debs/ dieses Repositorys.
#
#   bash werkzeuge/paket-bauen.sh
#
# Umgebung:
#   QUERENCIA_PACKAGING   Checkout von querencia-packaging mit dem Ordner
#                         querencia-anmeldung/ (Standard: Worktree anm-1)
#   QUERENCIA_JOBS        Cargo-Jobs (Standard 4)
#   QUERENCIA_ANMELDUNG_AUSGABE  Ausgabeordner (Standard build/); eine neue
#                         Fassung in einen eigenen Ordner bauen, damit die
#                         vorige .deb (Rückfallpfad) liegen bleibt
# Voraussetzung: Spiegel upstream/regreet.git (docs/building.md) und ein
# Commit dieses Repositorys in querencia-packaging/querencia-anmeldung/
# komponenten.conf.
set -euo pipefail
REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
PACKAGING=${QUERENCIA_PACKAGING:-$(dirname "$REPO")/querencia-packaging-wt-anm1}
AUSGABE=${QUERENCIA_ANMELDUNG_AUSGABE:-$REPO/build}
[ -x "$PACKAGING/werkzeuge/paket-bauen.sh" ] || { echo "querencia-packaging fehlt: $PACKAGING" >&2; exit 1; }
git -C "$REPO/upstream/regreet.git" rev-parse --verify -q '0.5.0^{commit}' >/dev/null ||
    { echo "Spiegel upstream/regreet.git fehlt (docs/building.md)" >&2; exit 1; }

export QUERENCIA_AUSGABE=$AUSGABE QUERENCIA_JOBS=${QUERENCIA_JOBS:-4}
mkdir -p "$AUSGABE/debs" "$AUSGABE/nachweis/logs"
bash "$PACKAGING/werkzeuge/orig-erzeugen.sh" querencia-anmeldung >"$AUSGABE/nachweis/logs/orig.log" 2>&1 ||
    { tail -20 "$AUSGABE/nachweis/logs/orig.log" >&2; exit 1; }
bash "$PACKAGING/werkzeuge/paket-bauen.sh" querencia-anmeldung
rm -f "$AUSGABE"/debs/querencia-anmeldung_*.deb
cp "$AUSGABE"/bau/querencia-anmeldung/*.deb "$AUSGABE/debs/"
(cd "$AUSGABE/debs" && sha256sum -- *.deb >SHA256SUMS && cat SHA256SUMS)
