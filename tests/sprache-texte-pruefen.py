# SPDX-License-Identifier: GPL-3.0-or-later
# Prüft die erwarteten Texte aus tests/sprache-texte.txt (aufgerufen von
# tests/uebersetzung-pruefen.sh):
#   python3 -I tests/sprache-texte-pruefen.py <liste> <po-datei>...
# Die Sprache einer po-Datei ist ihr Name (de.po, it.po, es.po, fr.po).
# "katalog": Übersetzung in der po-Datei muss genau stimmen.
# "linux-pam", "gtk": der Katalog des Systems muss den Text übersetzen
# (Wortlaut je nach Version); fehlt der Katalog oder die Locale, SKIP.
import os
import re
import subprocess
import sys

DOMAENE = {"linux-pam": "Linux-PAM", "gtk": "gtk40"}
ORDNER = ("/usr/share/locale-langpack", "/usr/share/locale")
SPALTE = {"de": 2, "it": 3, "es": 4, "fr": 5}
LAND = {"de": "de_de", "it": "it_it", "es": "es_es", "fr": "fr_fr"}


def locale_von(sprache):
    aus = subprocess.run(["locale", "-a"], capture_output=True, text=True).stdout.split()
    gesucht = LAND[sprache] + ".utf8"
    return next((name for name in aus if name.lower().replace("-", "") == gesucht), None)


def system_text(domaene, sprache, text):
    locale = locale_von(sprache)
    if not locale:
        return None
    for wurzel in ORDNER:
        if not os.path.exists(f"{wurzel}/{sprache}/LC_MESSAGES/{domaene}.mo"):
            continue
        env = dict(os.environ, LANGUAGE=sprache, LC_ALL=locale, TEXTDOMAINDIR=wurzel)
        # Linux-PAM führt Eingabeaufforderungen mit Leerzeichen am Ende
        for kandidat in (text, text + " "):
            aus = subprocess.run(["gettext", "-d", domaene, "--", kandidat], env=env,
                                 capture_output=True, text=True).stdout
            if aus.strip() and aus.strip() != text:
                return aus.strip()
        return ""
    return None


def main():
    zeilen = [z.rstrip("\n").split("|") for z in open(sys.argv[1], encoding="utf-8")
              if z.strip() and not z.startswith("#")]
    fehler = 0
    for pfad in sys.argv[2:]:
        sprache = os.path.basename(pfad).removesuffix(".po")
        if sprache not in SPALTE:
            print(f"FAIL {pfad}: keine Spalte für {sprache} in {sys.argv[1]}")
            fehler = 1
            continue
        paare = dict(re.findall(r'^msgid "(.*)"\nmsgstr "(.*)"$',
                                open(pfad, encoding="utf-8").read(), re.M))
        for zeile in zeilen:
            quelle, en, erwartet = zeile[0], zeile[1], zeile[SPALTE[sprache]]
            if quelle == "katalog":
                if paare.get(en) == erwartet:
                    print(f"PASS erwartet {sprache}: {en} -> {erwartet}")
                else:
                    print(f"FAIL erwartet {sprache}: {en} -> {erwartet}, im Katalog {paare.get(en)!r}")
                    fehler = 1
                continue
            uebersetzt = system_text(DOMAENE[quelle], sprache, en)
            if uebersetzt is None:
                print(f"SKIP {quelle} {sprache}: {DOMAENE[quelle]}.mo oder Locale fehlt hier ({en})")
            elif uebersetzt:
                print(f"PASS {quelle} {sprache}: {en} -> {uebersetzt}")
            else:
                print(f"FAIL {quelle} {sprache}: {en} nicht übersetzt")
                fehler = 1
    sys.exit(fehler)


main()
