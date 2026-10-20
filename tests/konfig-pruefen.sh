#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Statische Prüfung der Querencia-Teile (läuft auch beim Paketbau):
#   sh tests/konfig-pruefen.sh [<ordner des repositorys>]
# Prüft TOML/XML-Syntax, die Werte, auf die sich Paket und Prüfliste
# verlassen, die Shell-Syntax der Skripte und das Einlesen von Sprache und
# Tastatur in anmeldung-starten (mit Testdateien statt /etc/default).
# Exit 0 = alles PASS.
set -u
D=${1:-$(dirname "$0")/..}
fehler=0
ok() { echo "PASS $*"; }
nein() { echo "FAIL $*"; fehler=1; }
pruefe() { if eval "$2"; then ok "$1"; else nein "$1"; fi; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

py() { python3 -I -c "$@"; }

pruefe "config.toml ist TOML" \
    "py 'import sys,tomllib; tomllib.load(open(sys.argv[1],\"rb\"))' '$D/config/greetd/config.toml'"
pruefe "regreet.toml ist TOML" \
    "py 'import sys,tomllib; tomllib.load(open(sys.argv[1],\"rb\"))' '$D/config/greetd/regreet.toml'"
for x in rc.xml menu.xml; do
    pruefe "labwc/$x ist XML" \
        "py 'import sys,xml.etree.ElementTree as E; E.parse(sys.argv[1])' '$D/config/greetd/labwc/$x'"
done

# Werte, auf die sich Paket und Prüfliste verlassen
wert() {
    py 'import sys,tomllib
d=tomllib.load(open(sys.argv[1],"rb"))
for k in sys.argv[2].split("."): d=d[k]
print(d if not isinstance(d,list) else " ".join(d))' "$1" "$2"
}
C=$D/config/greetd/config.toml
G=$D/config/greetd/regreet.toml
pruefe "greetd: Befehl anmeldung-starten" \
    "[ \"\$(wert $C default_session.command)\" = /usr/libexec/querencia-anmeldung/anmeldung-starten ]"
pruefe "greetd: Benutzer _greetd" "[ \"\$(wert $C default_session.user)\" = _greetd ]"
pruefe "greetd: Konsole 7" "[ \"\$(wert $C terminal.vt)\" = 7 ]"
pruefe "ReGreet: Grußtext Querencia Desktop" "[ \"\$(wert $G appearance.greeting_msg)\" = 'Querencia Desktop' ]"
pruefe "ReGreet: Thema Querencia-Klassisch" "[ \"\$(wert $G GTK.theme_name)\" = Querencia-Klassisch ]"
pruefe "ReGreet: Symbolthema Querencia" "[ \"\$(wert $G GTK.icon_theme_name)\" = Querencia ]"
pruefe "ReGreet: Hintergrund Querencia Blau" \
    "[ \"\$(wert $G background.path)\" = /usr/share/querencia/hintergruende/querencia-blau.png ]"
pruefe "ReGreet: Neustart über systemctl" "[ \"\$(wert $G commands.reboot)\" = 'systemctl reboot' ]"
pruefe "kein Classic2 mehr" "! grep -rqi classic2 '$D/config' '$D/libexec' '$D/sbin' '$D/systemd'"

# labwc: nur None-Aktionen, keine Menüeinträge
R=$D/config/greetd/labwc/rc.xml
pruefe "labwc: nur Aktion None" \
    "[ \"\$(grep -o 'action name=\"[A-Za-z]*\"' '$R' | sort -u)\" = 'action name=\"None\"' ]"
pruefe "labwc: Menüs leer" "! grep -q '<item' '$D/config/greetd/labwc/menu.xml'"
pruefe "labwc: Aktivierungsumgebung aus" "grep -qx 'LABWC_UPDATE_ACTIVATION_ENV=0' '$D/config/greetd/labwc/environment'"

# Dienst
S=$D/systemd/querencia-anmeldung.service
pruefe "Dienst: ExecStart" "grep -qx 'ExecStart=/usr/sbin/querencia-anmeldung' '$S'"
pruefe "Dienst: Alias display-manager" "grep -qx 'Alias=display-manager.service' '$S'"
pruefe "Dienst: Konsole 7 frei von getty" "grep -qx 'Conflicts=getty@tty7.service' '$S'"
pruefe "querencia-anmeldung: greetd mit eigener Konfiguration" \
    "grep -q 'greetd --config /etc/querencia/greetd/config.toml' '$D/sbin/querencia-anmeldung'"

for s in libexec/anmeldung-starten sbin/querencia-anmeldung tests/konfig-pruefen.sh; do
    pruefe "sh -n $s" "sh -n '$D/$s'"
done

# anmeldung-starten mit Testdateien: Werte übernehmen, kaputte Zeilen überleben
cat >"$TMP/locale" <<'EOT'
LANG="de_DE.UTF-8"
LANGUAGE=de:en
LC_TIME='de_DE.UTF-8'
das ist kein gültiger eintrag
FOO=bar
EOT
cat >"$TMP/keyboard" <<'EOT'
# KEYBOARD CONFIGURATION FILE
XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT="nodeadkeys"
XKBOPTIONS=""
BACKSPACE="guess"
EOT
sed -e "s|/etc/default/locale|$TMP/locale|g" -e "s|/etc/default/keyboard|$TMP/keyboard|g" \
    -e 's|^exec .*|env; echo "ARGS $KONFIG $REGREET"|' "$D/libexec/anmeldung-starten" >"$TMP/starten"
env -i PATH=/usr/bin:/bin sh "$TMP/starten" >"$TMP/env" 2>&1
pruefe "starten: LANG" "grep -qx 'LANG=de_DE.UTF-8' '$TMP/env'"
pruefe "starten: LANGUAGE" "grep -qx 'LANGUAGE=de:en' '$TMP/env'"
pruefe "starten: LC_TIME" "grep -qx 'LC_TIME=de_DE.UTF-8' '$TMP/env'"
pruefe "starten: fremde Variable nicht übernommen" "! grep -q '^FOO=' '$TMP/env'"
pruefe "starten: XKB-Belegung" "grep -qx 'XKB_DEFAULT_LAYOUT=de' '$TMP/env' && grep -qx 'XKB_DEFAULT_VARIANT=nodeadkeys' '$TMP/env'"
pruefe "starten: leere XKB-Werte nicht gesetzt" "! grep -q '^XKB_DEFAULT_OPTIONS=' '$TMP/env'"
pruefe "starten: Pfade" "grep -qx 'ARGS /etc/querencia/greetd /usr/libexec/querencia-anmeldung/regreet' '$TMP/env'"
pruefe "starten: exec labwc -S regreet" \
    "grep -q '^exec /usr/bin/dbus-run-session -- /usr/bin/labwc -C \"\$KONFIG/labwc\" -S \"\$REGREET\"\$' '$D/libexec/anmeldung-starten'"

[ $fehler -eq 0 ] && echo "ERGEBNIS: PASS" || echo "ERGEBNIS: FAIL"
exit $fehler
