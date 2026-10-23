#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Gleicht die übersetzbaren Texte des gepatchten ReGreet mit dem Katalog ab
# (läuft auch beim Paketbau, nach dem Patch):
#   sh tests/uebersetzung-pruefen.sh <regreet-quellbaum> [<po-datei>]
# Jeder Text in tr("...") und in den Variablen, die an tr(...) gehen, muss
# in der po-Datei stehen und übersetzt sein; msgfmt -c muss sie annehmen.
# Exit 0 = alles PASS.
set -u
Q=${1:?Quellbaum von ReGreet fehlt}
PO=${2:-$(dirname "$0")/../po/de.po}
fehler=0
ok() { echo "PASS $*"; }
nein() { echo "FAIL $*"; fehler=1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if LC_ALL=C msgfmt -c --statistics -o "$TMP/de.mo" "$PO" 2>"$TMP/stat"; then
    ok "msgfmt -c $(cat "$TMP/stat")"
else
    nein "msgfmt -c: $(cat "$TMP/stat")"
fi
grep -q -E 'untranslated|fuzzy' "$TMP/stat" && nein "unübersetzte oder unscharfe Einträge"

# Texte aus dem Quellbaum: tr("...") und error_msg = "..." vor tr(error_msg)
grep -rhoE '(^|[^A-Za-z0-9_])tr\("[^"]*"\)' "$Q/src" | sed -e 's/^.*tr("//' -e 's/")$//' >"$TMP/texte"
grep -q 'tr(error_msg)' "$Q/src/gui/model.rs" &&
    grep -hoE 'let error_msg = "[^"]*"' "$Q/src/gui/model.rs" | sed -e 's/^let error_msg = "//' -e 's/"$//' >>"$TMP/texte"
sort -u "$TMP/texte" -o "$TMP/texte"
[ -s "$TMP/texte" ] && ok "$(wc -l <"$TMP/texte") Texte im Quellbaum" || nein "keine tr(...)-Aufrufe in $Q/src (Patch fehlt?)"

python3 -I - "$PO" "$TMP/texte" <<'EOF' || fehler=1
import re, sys
po = open(sys.argv[1], encoding="utf-8").read()
paare = dict(re.findall(r'^msgid "(.*)"\nmsgstr "(.*)"$', po, re.M))
for text in open(sys.argv[2], encoding="utf-8").read().splitlines():
    if paare.get(text):
        print(f"PASS übersetzt: {text} -> {paare[text]}")
    else:
        print(f"FAIL fehlt in der po-Datei: {text}")
        sys.exit(1)
EOF

[ $fehler = 0 ] && echo "ERGEBNIS: PASS" || echo "ERGEBNIS: FAIL"
exit $fehler
