# SPDX-License-Identifier: GPL-3.0-or-later
# Prüft die erwarteten Texte aus tests/sprache-texte.txt (aufgerufen von
# tests/uebersetzung-pruefen.sh):
#   python3 -I tests/sprache-texte-pruefen.py <po-datei> <liste>
# "katalog": Übersetzung in der po-Datei muss genau stimmen.
# "linux-pam", "gtk": der Katalog des Systems muss den Text übersetzen
# (Wortlaut je nach Version); fehlt der Katalog oder die Locale de_DE, SKIP.
import os
import re
import subprocess
import sys

DOMAENE = {"linux-pam": "Linux-PAM", "gtk": "gtk40"}
ORDNER = ("/usr/share/locale-langpack", "/usr/share/locale")


def de_locale():
    aus = subprocess.run(["locale", "-a"], capture_output=True, text=True).stdout.split()
    return next((name for name in aus if name.lower().replace("-", "") in ("de_de.utf8",)), None)


def system_text(domaene, text):
    locale = de_locale()
    if not locale:
        return None
    for wurzel in ORDNER:
        if not os.path.exists(f"{wurzel}/de/LC_MESSAGES/{domaene}.mo"):
            continue
        env = dict(os.environ, LANGUAGE="de", LC_ALL=locale, TEXTDOMAINDIR=wurzel)
        # Linux-PAM führt Eingabeaufforderungen mit Leerzeichen am Ende
        for kandidat in (text, text + " "):
            aus = subprocess.run(["gettext", "-d", domaene, "--", kandidat], env=env,
                                 capture_output=True, text=True).stdout
            if aus.strip() and aus.strip() != text:
                return aus.strip()
        return ""
    return None


def main():
    po = open(sys.argv[1], encoding="utf-8").read()
    paare = dict(re.findall(r'^msgid "(.*)"\nmsgstr "(.*)"$', po, re.M))
    fehler = 0
    for zeile in open(sys.argv[2], encoding="utf-8"):
        zeile = zeile.rstrip("\n")
        if not zeile or zeile.startswith("#"):
            continue
        quelle, en, de = zeile.split("|")
        if quelle == "katalog":
            if paare.get(en) == de:
                print(f"PASS erwartet: {en} -> {de}")
            else:
                print(f"FAIL erwartet: {en} -> {de}, im Katalog {paare.get(en)!r}")
                fehler = 1
            continue
        uebersetzt = system_text(DOMAENE[quelle], en)
        if uebersetzt is None:
            print(f"SKIP {quelle}: {DOMAENE[quelle]}.mo oder Locale de_DE fehlt hier ({en})")
        elif uebersetzt:
            print(f"PASS {quelle}: {en} -> {uebersetzt}")
        else:
            print(f"FAIL {quelle}: {en} nicht übersetzt")
            fehler = 1
    sys.exit(fehler)


main()
