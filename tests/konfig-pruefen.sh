#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Statische Prüfung der Querencia-Teile (läuft auch beim Paketbau):
#   sh tests/konfig-pruefen.sh [<ordner des repositorys>]
# Prüft TOML/XML-Syntax, die Werte, auf die sich Paket und Prüfliste
# verlassen, die Shell-Syntax der Skripte, das Einlesen von Sprache und
# Tastatur in anmeldung-starten (mit Testdateien statt /etc/default), die
# Sitzungshülle sitzung-starten und die Sitzungsauswahl mit Vorwahl
# (Testdateien Querencia, GNOME, labwc, kaputt).
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
pruefe "greetd: liest die Profile selbst (source_profile nicht abgeschaltet)" "! grep -q source_profile '$C'"
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

for s in libexec/anmeldung-starten libexec/sitzung-starten libexec/sitzungen-auswahl \
    sbin/querencia-anmeldung tests/konfig-pruefen.sh; do
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
printf '#!/bin/sh\necho AUSWAHL-LIEF\n' >"$TMP/auswahl-attrappe"
chmod 755 "$TMP/auswahl-attrappe"
env -i PATH=/usr/bin:/bin XDG_DATA_DIRS=/x QUERENCIA_ANMELDUNG_AUSWAHL="$TMP/auswahl-attrappe" \
    sh "$TMP/starten" >"$TMP/env" 2>&1
pruefe "starten: LANG" "grep -qx 'LANG=de_DE.UTF-8' '$TMP/env'"
pruefe "starten: LANGUAGE" "grep -qx 'LANGUAGE=de:en' '$TMP/env'"
pruefe "starten: LC_TIME" "grep -qx 'LC_TIME=de_DE.UTF-8' '$TMP/env'"
pruefe "starten: fremde Variable nicht übernommen" "! grep -q '^FOO=' '$TMP/env'"
pruefe "starten: XKB-Belegung" "grep -qx 'XKB_DEFAULT_LAYOUT=de' '$TMP/env' && grep -qx 'XKB_DEFAULT_VARIANT=nodeadkeys' '$TMP/env'"
pruefe "starten: leere XKB-Werte nicht gesetzt" "! grep -q '^XKB_DEFAULT_OPTIONS=' '$TMP/env'"
pruefe "starten: Pfade" "grep -qx 'ARGS /etc/querencia/greetd /usr/libexec/querencia-anmeldung/regreet' '$TMP/env'"
pruefe "starten: exec labwc -S regreet ohne XDG_DATA_DIRS" \
    "grep -q '^exec /usr/bin/dbus-run-session -- /usr/bin/labwc -C \"\$KONFIG/labwc\" -S \"/usr/bin/env -u XDG_DATA_DIRS \$REGREET\"\$' '$D/libexec/anmeldung-starten'"
pruefe "starten: XDG_DATA_DIRS entfernt" "! grep -q '^XDG_DATA_DIRS=' '$TMP/env'"
pruefe "starten: Sitzungsauswahl läuft vorher" "grep -qx AUSWAHL-LIEF '$TMP/env'"
pruefe "starten: Standardpfad der Auswahl" \
    "grep -q 'AUSWAHL:-/usr/libexec/querencia-anmeldung/sitzungen-auswahl}' '$D/libexec/anmeldung-starten'"
pruefe "labwc: setzt kein XDG_DATA_DIRS" "! grep -q XDG_DATA_DIRS '$D/config/greetd/labwc/environment'"

# --- Sitzungshülle mit Testdateien ---------------------------------------
H=$D/libexec/sitzung-starten
Q=$TMP/quellen
mkdir -p "$Q/usr" "$Q/lokal" "$TMP/home"
cat >"$Q/usr/querencia.desktop" <<'EOT'
[Desktop Entry]
Name=Querencia Desktop
Comment=Querencia Desktop session (labwc 0.9.8)
Exec=/usr/libexec/querencia-session/querencia-session
Type=Application
DesktopNames=X-Querencia
EOT
cat >"$Q/usr/ubuntu.desktop" <<'EOT'
[Desktop Entry]
Name=Ubuntu
Comment=This session logs you into Ubuntu
Exec=env GNOME_SHELL_SESSION_MODE=ubuntu /usr/bin/gnome-session --session=ubuntu
TryExec=/bin/sh
Type=Application
DesktopNames=ubuntu;GNOME;
X-GDM-SessionRegisters=true

[Desktop Action Andere]
Exec=falsch
EOT
cat >"$Q/usr/labwc.desktop" <<'EOT'
[Desktop Entry]
Name=labwc
Exec=labwc
Type=Application
DesktopNames=labwc;wlroots
EOT
printf 'Name=kaputt\nExec=/bin/true\n' >"$Q/usr/kaputt.desktop"
printf '[Desktop Entry]\nName=Ohne Exec\nDesktopNames=X-Querencia\n' >"$Q/usr/ohne-exec.desktop"
printf '[Desktop Entry]\nName=Fehlt\nExec=x\nTryExec=/gibt/es/nicht\n' >"$Q/usr/tryexec.desktop"
printf '[Desktop Entry]\nName=Plasma\nExec=startplasma-wayland\nDesktopNames=KDE\n' >"$Q/usr/plasma.desktop"
printf '[Desktop Entry]\nName=Versteckt\nExec=x\nDesktopNames=X-Querencia\nHidden=true\n' >"$Q/usr/versteckt.desktop"
# Testsitzung: gibt die Umgebung und die Argumente aus
cat >"$Q/usr/test.desktop" <<'EOT'
[Desktop Entry]
Name = Test
Exec = sh -c "env | grep -E '^(XDG_|DESKTOP_SESSION=|PROFIL)' | sort; echo ARG \$0 \$1" eins "zwei drei"
DesktopNames=ubuntu;GNOME;
EOT
# ~/.profile darf die Hülle nicht noch einmal lesen (greetd hat es gelesen)
echo 'PROFIL_SAH="$DESKTOP_SESSION"; export PROFIL_SAH' >"$TMP/home/.profile"

pp() { sh "$H" --pruefen "$1" 2>&1; }
pruefe "Hülle: Querencia -> X-Querencia" "pp '$Q/usr/querencia.desktop' | grep -qx XDG_CURRENT_DESKTOP=X-Querencia"
pruefe "Hülle: Querencia -> XDG_SESSION_DESKTOP/DESKTOP_SESSION querencia" \
    "pp '$Q/usr/querencia.desktop' | grep -qx XDG_SESSION_DESKTOP=querencia && pp '$Q/usr/querencia.desktop' | grep -qx DESKTOP_SESSION=querencia"
pruefe "Hülle: GNOME -> ubuntu:GNOME" "pp '$Q/usr/ubuntu.desktop' | grep -qx XDG_CURRENT_DESKTOP=ubuntu:GNOME"
pruefe "Hülle: GNOME -> DESKTOP_SESSION ubuntu" "pp '$Q/usr/ubuntu.desktop' | grep -qx DESKTOP_SESSION=ubuntu"
pruefe "Hülle: GNOME -> Exec der Gruppe [Desktop Entry]" \
    "pp '$Q/usr/ubuntu.desktop' | grep -qx 'EXEC=env GNOME_SHELL_SESSION_MODE=ubuntu /usr/bin/gnome-session --session=ubuntu'"
pruefe "Hülle: XDG_SESSION_TYPE wayland" "pp '$Q/usr/ubuntu.desktop' | grep -qx XDG_SESSION_TYPE=wayland"
pruefe "Hülle: labwc -> labwc:wlroots" "pp '$Q/usr/labwc.desktop' | grep -qx XDG_CURRENT_DESKTOP=labwc:wlroots"
pruefe "Hülle: kaputt (ohne Gruppe) abgelehnt" "! pp '$Q/usr/kaputt.desktop' >/dev/null"
pruefe "Hülle: ohne Exec abgelehnt" "! pp '$Q/usr/ohne-exec.desktop' >/dev/null"
pruefe "Hülle: fehlendes TryExec abgelehnt" "! pp '$Q/usr/tryexec.desktop' >/dev/null"
pruefe "Hülle: fehlende Datei abgelehnt" "! pp '$Q/usr/gibt-es-nicht.desktop' >/dev/null"
pruefe "Hülle: Versteckt erkannt" "pp '$Q/usr/versteckt.desktop' | grep -qx VERSTECKT=ja"
env -i PATH=/usr/bin:/bin HOME="$TMP/home" XDG_CURRENT_DESKTOP=alt sh "$H" "$Q/usr/test.desktop" >"$TMP/huelle.out" 2>&1
pruefe "Hülle startet: XDG_CURRENT_DESKTOP" "grep -qx XDG_CURRENT_DESKTOP=ubuntu:GNOME '$TMP/huelle.out'"
pruefe "Hülle startet: XDG_SESSION_DESKTOP, DESKTOP_SESSION" \
    "grep -qx XDG_SESSION_DESKTOP=test '$TMP/huelle.out' && grep -qx DESKTOP_SESSION=test '$TMP/huelle.out'"
pruefe "Hülle startet: XDG_SESSION_TYPE" "grep -qx XDG_SESSION_TYPE=wayland '$TMP/huelle.out'"
pruefe "Hülle startet: liest ~/.profile nicht noch einmal" "! grep -q '^PROFIL_SAH=' '$TMP/huelle.out'"
pruefe "Hülle startet: Argumente mit Anführungszeichen" "grep -qx 'ARG eins zwei drei' '$TMP/huelle.out'"
env -i PATH=/usr/bin:/bin HOME="$TMP/home" sh "$H" --ohne-variablen "$Q/usr/test.desktop" >"$TMP/huelle2.out" 2>&1
pruefe "Hülle --ohne-variablen: keine Variablen, nur Exec" \
    "! grep -q '^XDG_CURRENT_DESKTOP=' '$TMP/huelle2.out' && ! grep -q '^DESKTOP_SESSION=' '$TMP/huelle2.out' && grep -qx 'ARG eins zwei drei' '$TMP/huelle2.out'"

# --- Sitzungsauswahl -----------------------------------------------------
A=$D/libexec/sitzungen-auswahl
mkdir -p "$TMP/konfig" "$TMP/lauf" "$TMP/zustand"
cp "$D/config/greetd/sitzungen.conf" "$TMP/konfig/sitzungen.conf"
printf 'root:x:0:0::/root:/bin/bash\nuser:x:1000:1000::~:/bin/bash\nprobe:x:1001:1001::/home/probe:/bin/bash\ndienst:x:1002:1002::/:/usr/sbin/nologin\n' >"$TMP/passwd"
auswahl() {
    env QUERENCIA_ANMELDUNG_KONFIG="$TMP/konfig" QUERENCIA_ANMELDUNG_HUELLE="${HUELLE_TEST:-$H}" \
        QUERENCIA_ANMELDUNG_QUELLEN="$Q/lokal $Q/usr" QUERENCIA_ANMELDUNG_LAUFZEIT="$TMP/lauf" \
        QUERENCIA_ANMELDUNG_ZUSTAND="$TMP/zustand/state.toml" QUERENCIA_ANMELDUNG_PASSWD="$TMP/passwd" \
        QUERENCIA_ANMELDUNG_LOGINDEFS=/dev/null sh "$A" >"$TMP/auswahl.out" 2>&1
}
W=$TMP/lauf/wayland-sessions
HUELLE_TEST=$TMP/sitzung-starten
cp "$H" "$HUELLE_TEST"; chmod 755 "$HUELLE_TEST"
auswahl
pruefe "Auswahl Vorgabe: Querencia angeboten" "[ -f '$W/querencia.desktop' ]"
pruefe "Auswahl Vorgabe: nur Querencia" "[ \"\$(ls '$W')\" = querencia.desktop ]"
pruefe "Auswahl Vorgabe: GNOME ausgeblendet" "grep -q 'ausgeblendet .*/ubuntu.desktop nicht-freigegeben' '$TMP/lauf/auswahl.txt'"
pruefe "Auswahl Vorgabe: labwc nie" "grep -q 'ausgeblendet .*/labwc.desktop labwc-nie' '$TMP/lauf/auswahl.txt'"
pruefe "Auswahl: kaputte Datei ausgeblendet" "grep -q 'ausgeblendet .*/kaputt.desktop kaputt' '$TMP/lauf/auswahl.txt'"
pruefe "Auswahl: versteckte ausgeblendet" "grep -q 'ausgeblendet .*/versteckt.desktop versteckt' '$TMP/lauf/auswahl.txt'"
pruefe "Auswahl: Querencia startet über die Hülle" \
    "grep -qx 'Exec=$HUELLE_TEST $Q/usr/querencia.desktop' '$W/querencia.desktop'"
pruefe "Auswahl: Name übernommen" "grep -qx 'Name=Querencia Desktop' '$W/querencia.desktop'"
pruefe "Auswahl: Vorwahl für neue Benutzer" \
    "grep -qx 'user = \"Querencia Desktop\"' '$TMP/zustand/state.toml' && grep -qx 'probe = \"Querencia Desktop\"' '$TMP/zustand/state.toml'"
pruefe "Auswahl: keine Vorwahl für Systembenutzer" "! grep -q '^root\\|^dienst' '$TMP/zustand/state.toml'"
pruefe "Auswahl: state.toml ist TOML" \
    "py 'import sys,tomllib; tomllib.load(open(sys.argv[1],\"rb\"))' '$TMP/zustand/state.toml'"
printf 'freigeben = ubuntu labwc\nhuelle = ja\n' >"$TMP/konfig/sitzungen.conf"
printf 'last_user = "user"\n\n[user_to_last_sess]\nuser = "labwc"\nprobe = "Ubuntu"\n' >"$TMP/zustand/state.toml"
auswahl
pruefe "Auswahl Freigabe: Ubuntu angeboten" "[ -f '$W/ubuntu.desktop' ] && grep -qx 'Exec=$HUELLE_TEST $Q/usr/ubuntu.desktop' '$W/ubuntu.desktop'"
pruefe "Auswahl Freigabe: labwc trotzdem nie" "[ ! -e '$W/labwc.desktop' ]"
pruefe "Auswahl Freigabe: andere bleiben aus" "[ ! -e '$W/plasma.desktop' ]"
pruefe "Auswahl: alte Sitzung labwc -> Querencia, gültige bleibt" \
    "grep -qx 'user = \"Querencia Desktop\"' '$TMP/zustand/state.toml' && grep -qx 'probe = \"Ubuntu\"' '$TMP/zustand/state.toml' && grep -qx 'last_user = \"user\"' '$TMP/zustand/state.toml'"
printf 'freigeben =\nhuelle = nein\n' >"$TMP/konfig/sitzungen.conf"
auswahl
pruefe "Auswahl huelle=nein: Querencia ohne Variablen" \
    "grep -qx 'Exec=$HUELLE_TEST --ohne-variablen $Q/usr/querencia.desktop' '$W/querencia.desktop'"
pruefe "Auswahl: nicht mehr angebotene Sitzung -> Querencia" "grep -qx 'probe = \"Querencia Desktop\"' '$TMP/zustand/state.toml'"
cp "$Q/usr/querencia.desktop" "$Q/lokal/querencia.desktop"
sed -i 's/^Name=.*/Name=Querencia lokal/' "$Q/lokal/querencia.desktop"
auswahl
pruefe "Auswahl: /usr/local/share vor /usr/share" \
    "grep -qx 'Name=Querencia lokal' '$W/querencia.desktop' && grep -q 'ausgeblendet $Q/usr/querencia.desktop verdeckt' '$TMP/lauf/auswahl.txt'"
rm -f "$Q/lokal/querencia.desktop"
HUELLE_TEST=$TMP/gibt-es-nicht
auswahl
pruefe "Auswahl ohne Hülle: keine Sitzung" "[ -z \"\$(ls '$W')\" ] && grep -q 'keine-huelle' '$TMP/lauf/auswahl.txt'"

[ $fehler -eq 0 ] && echo "ERGEBNIS: PASS" || echo "ERGEBNIS: FAIL"
exit $fehler
