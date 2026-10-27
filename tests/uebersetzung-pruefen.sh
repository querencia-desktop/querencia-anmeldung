#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Gleicht die übersetzbaren Texte des gepatchten ReGreet mit dem Katalog ab
# (läuft auch beim Paketbau, nach dem Patch):
#   sh tests/uebersetzung-pruefen.sh <regreet-quellbaum> [<po-datei>]
# Jeder Text in tr("...") und in den Variablen, die an tr(...) gehen, muss
# in der po-Datei stehen und übersetzt sein; msgfmt -c muss sie annehmen.
# Dazu: keine sichtbaren Texte ohne tr(...) (keine englischen Reste bei
# Deutsch), Texte von PAM über tr_pam(...), und die erwarteten Texte aus
# tests/sprache-texte.txt (eigener Katalog Pflicht, Linux-PAM und GTK nur,
# wenn deren Kataloge auf dem Prüfrechner liegen).
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

# Keine englischen Reste bei Deutsch: sichtbare Texte nur über tr(...),
# Texte von PAM nur über tr_pam(...) (eigener Katalog, dann Linux-PAM).
T=$Q/src/gui/templates.rs
M=$Q/src/gui/model.rs
if grep -nE '(set_label|set_text|set_title|set_placeholder_text|set_tooltip_text)[: (]+(Some\()?"' "$T" >"$TMP/reste"; then
    nein "Text ohne tr(...) in templates.rs: $(tr '\n' ' ' <"$TMP/reste")"
else
    ok "templates.rs: alle Beschriftungen über tr(...)"
fi
# Anzeigetext von display_error/display_info (zweites Argument) nie ein
# englisches Literal; Ausnahme "Auto-selecting session" (einzeiliger Aufruf)
# gibt es nur mit skip_selection = true (Querencia: false, konfig-pruefen).
awk '/self\.display_(error|info)\($/ { n = NR + 2 } NR == n && /^[[:space:]]*(&?format!\(|")/ { print NR ": " $0 }' "$M" >"$TMP/reste"
if [ -s "$TMP/reste" ]; then
    nein "Anzeigetext ohne tr in model.rs: $(tr '\n' ' ' <"$TMP/reste")"
else
    ok "model.rs: Anzeigetexte über tr(...)"
fi
if grep -q 'fn tr_pam' "$Q/src/gui/mod.rs"; then
    n=$(grep -c 'tr_pam(&auth_message)' "$M")
    if [ "$n" -eq 4 ]; then ok "model.rs: Texte von PAM über tr_pam (4 Stellen)"; else nein "model.rs: tr_pam(&auth_message) an $n statt 4 Stellen"; fi
    if grep -q 'capitalize(&auth_message)' "$M"; then nein "model.rs: PAM-Meldung ohne Übersetzung"; fi
    if grep -q 'dgettext(Some("Linux-PAM")' "$Q/src/gui/mod.rs"; then
        ok "mod.rs: Rückfall auf den Katalog Linux-PAM"
    else
        nein "mod.rs: kein Rückfall auf Linux-PAM"
    fi
else
    nein "mod.rs: tr_pam fehlt (Patch vor 0.1.3?)"
fi

# Erwartete Texte (tests/sprache-texte.txt)
python3 -I "$(dirname "$0")/sprache-texte-pruefen.py" "$PO" "$(dirname "$0")/sprache-texte.txt" || fehler=1

[ $fehler = 0 ] && echo "ERGEBNIS: PASS" || echo "ERGEBNIS: FAIL"
exit $fehler
