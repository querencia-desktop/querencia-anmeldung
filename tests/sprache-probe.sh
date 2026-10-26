#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Isolierte Sprachprobe des Anmeldebildschirms: startet das gebaute ReGreet
# im Demo-Modus (ohne greetd, ohne PAM) in einem kopflosen labwc und
# fotografiert ihn in einer Sprache. Nichts am System wird geändert: alles
# läuft in einem eigenen Benutzer- und Mount-Namensraum; Katalog,
# Sitzungsordner und Benutzerliste (ein Schein-AccountsService auf einem
# eigenen Bus, Benutzer "Querencia Probe") sind nur dort sichtbar.
#
#   sh tests/sprache-probe.sh <paketwurzel> <themawurzel> <ausgabe> <locale> [ohne-gtk-katalog]
#
# <paketwurzel>  entpacktes querencia-anmeldung_*.deb (dpkg-deb -x)
# <themawurzel>  entpackte querencia-shell und querencia-symbole (Thema,
#                Hintergrund); leer lassen ("") geht, dann ohne Thema
# <ausgabe>      Ordner für die Fotos <sprache>-NN-*.png und log.txt
# <locale>       z. B. de_DE.UTF-8 oder en_US.UTF-8 (muss erzeugt sein)
# ohne-gtk-katalog  blendet gtk40.mo aus (wie ein System ohne
#                language-pack-gnome-<sprache>)
#
# Braucht labwc, grim, wlrctl, wtype, dbus-daemon, python3-gi und
# unprivilegierte Benutzer-Namensräume. Exit 0 = Fotos erzeugt; den Inhalt
# prüft man auf den Fotos (Liste der erwarteten Texte: tests/sprache-texte.txt).
set -eu
PAKET=$(realpath "${1:?Paketwurzel fehlt}")
THEMA=${2-}
[ -z "$THEMA" ] || THEMA=$(realpath "$THEMA")
mkdir -p "${3:?Ausgabeordner fehlt}"
AUS=$(realpath "$3")
SPRACHE=${4:?Locale fehlt}
OHNE_GTK=${5:-}
HIER=$(dirname "$(realpath "$0")")

if [ "${QUERENCIA_PROBE_INNEN:-}" != ja ]; then
    QUERENCIA_PROBE_INNEN=ja exec unshare -r -m --propagation private sh "$0" "$@"
fi

W=$(mktemp -d "${TMPDIR:-/tmp}/sprache-probe.XXXXXX")
trap 'kill $(jobs -p) 2>/dev/null || true; rm -rf "$W"' EXIT
LOG=$AUS/log-$SPRACHE.txt
: >"$LOG"
kurz=${SPRACHE%%_*}

# Arbeitsordner nur im Namensraum (tmpfs auf /mnt): kurze Pfade für die
# Sockets (höchstens 108 Zeichen) und die Originale der überblendeten
# Systemordner. Sie liegen bewusst nicht in $W, das am Ende gelöscht wird.
mount -t tmpfs -o mode=700 none /mnt
mkdir -m 700 /mnt/run /mnt/orig
[ -d /tmp/.X11-unix ] && mount -t tmpfs none /tmp/.X11-unix
export XDG_RUNTIME_DIR=/mnt/run

# Katalog des Pakets dort einblenden, wo gettext ihn sucht
# (/usr/share/locale/<sprache>/LC_MESSAGES), Originaldateien bleiben sichtbar.
einblenden() { # <zielordner> <ohne-muster|-> <zusatzdatei|->
    [ -d "$1" ] || return 0
    o=/mnt/orig/$(printf '%s' "$1" | tr / _)
    mkdir -p "$o"
    mount --bind "$1" "$o"
    mount -t tmpfs none "$1"
    for f in "$o"/*; do
        b=${f##*/}
        case $b in $2) continue ;; esac
        ln -s "$f" "$1/$b"
    done
    [ "$3" = - ] || cp "$3" "$1/"
}
MO=$PAKET/usr/share/locale/$kurz/LC_MESSAGES/querencia-anmeldung.mo
if [ -f "$MO" ]; then
    einblenden "/usr/share/locale/$kurz/LC_MESSAGES" - "$MO"
fi
if [ "$OHNE_GTK" = ohne-gtk-katalog ]; then
    einblenden "/usr/share/locale-langpack/$kurz/LC_MESSAGES" 'gtk40*.mo' -
    [ -f "$MO" ] || einblenden "/usr/share/locale/$kurz/LC_MESSAGES" 'gtk40*.mo' -
fi

# Sitzungen: mit sitzungen-auswahl des Pakets aus Probedateien erzeugt
# (Querencia Desktop, dazu eine freigegebene Sitzung mit Name[de]).
Q=$W/quellen
mkdir -p "$Q" "$W/konfig" "$W/lauf" "$W/share"
cat >"$Q/querencia.desktop" <<'EOF'
[Desktop Entry]
Name=Querencia Desktop
Comment=Querencia Desktop session
Exec=/bin/true
Type=Application
DesktopNames=X-Querencia
EOF
cat >"$Q/probe-sitzung.desktop" <<'EOF'
[Desktop Entry]
Name=Test session
Name[de]=Testsitzung
Exec=/bin/true
Type=Application
DesktopNames=Probe
EOF
printf 'freigeben = probe-sitzung\n' >"$W/konfig/sitzungen.conf"
printf 'probe:x:1000:1000::/home/probe:/bin/bash\n' >"$W/passwd"
LIBEXEC=$PAKET/usr/libexec/querencia-anmeldung
env LANG="$SPRACHE" LC_ALL= LANGUAGE= \
    QUERENCIA_ANMELDUNG_KONFIG="$W/konfig" QUERENCIA_ANMELDUNG_HUELLE="$LIBEXEC/sitzung-starten" \
    QUERENCIA_ANMELDUNG_QUELLEN="$Q" QUERENCIA_ANMELDUNG_LAUFZEIT="$W/lauf" \
    QUERENCIA_ANMELDUNG_ZUSTAND="$W/state.toml" QUERENCIA_ANMELDUNG_PASSWD="$W/passwd" \
    sh "$LIBEXEC/sitzungen-auswahl" >>"$LOG" 2>&1 || true
mv "$W/lauf/wayland-sessions" "$W/share/wayland-sessions"
for d in /usr/share/wayland-sessions /usr/share/xsessions /usr/local/share/wayland-sessions; do
    [ -d "$d" ] && mount -t tmpfs none "$d"
done

# Zustand eines installierten ReGreet (zuletzt gewählter Benutzer) nicht lesen
for d in /var/lib/querencia-anmeldung /var/lib/regreet; do
    [ -d "$d" ] && mount -t tmpfs none "$d"
done

# ReGreet-Konfiguration des Pakets, Hintergrund aus der Themawurzel
sed -e "s#^path = \"/usr/share/querencia/#path = \"$THEMA/usr/share/querencia/#" \
    "$PAKET/etc/querencia/greetd/regreet.toml" >"$W/regreet.toml"

# eigener "Systembus" mit Schein-AccountsService (ein Benutzer)
cat >"$W/bus.conf" <<EOF
<busconfig><type>system</type><listen>unix:path=/mnt/run/systembus</listen>
<auth>EXTERNAL</auth><policy context="default"><allow user="*"/>
<allow own="*"/><allow send_destination="*"/><allow receive_sender="*"/></policy></busconfig>
EOF
dbus-daemon --config-file="$W/bus.conf" --nofork --nopidfile >>"$LOG" 2>&1 &
sleep 0.5
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/mnt/run/systembus
python3 -I "$HIER/sprache-probe-konten.py" >>"$LOG" 2>&1 &
sleep 1

export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
export WLR_HEADLESS_OUTPUTS=1
export XDG_DATA_DIRS="$W/share${THEMA:+:$THEMA/usr/share}:/usr/local/share:/usr/share"
export LANG="$SPRACHE"
unset LC_ALL LANGUAGE LC_MESSAGES LC_TIME WAYLAND_DISPLAY DISPLAY
for v in $(env | sed -n 's/^\(LC_[A-Z]*\)=.*/\1/p'); do unset "$v"; done

# labwc -s (nicht -S): bleibt nach dem Ende von ReGreet für das Aufräumen
dbus-run-session -- labwc -C "$PAKET/etc/querencia/greetd/labwc" \
    -s "$LIBEXEC/regreet --demo -l $W/regreet.log -c $W/regreet.toml" >>"$LOG" 2>&1 &
i=0
while [ ! -S "$XDG_RUNTIME_DIR/wayland-0" ] && [ $i -lt 50 ]; do sleep 0.2; i=$((i + 1)); done
export WAYLAND_DISPLAY=wayland-0
sleep 4

foto() { grim "$AUS/$kurz-$1.png"; echo "Foto $kurz-$1.png" >>"$LOG"; }
# Zeiger an eine Bildschirmstelle (kopfloser Ausgang 1280x720, oben links 0 0)
zeiger() { wlrctl pointer move -5000 -5000; wlrctl pointer move "$1" "$2"; sleep 1.5; }
klick() { zeiger "$1" "$2"; wlrctl pointer click left; sleep 1.5; }

foto 01-start
zeiger 874 331; foto 02-tooltip-benutzer
zeiger 874 391; foto 03-tooltip-sitzung
klick 839 444; foto 04-abfrage
zeiger 829 391; foto 05-tooltip-auge
wtype 1111; sleep 0.5; wtype -k Return; sleep 2; foto 06-falsch
sleep 3; klick 839 444; wtype 0248; sleep 0.5; wtype -k Return; sleep 2; foto 07-passwort
klick 720 444; klick 674 391; foto 08-sitzungsliste
cp "$W/regreet.log" "$AUS/regreet-$kurz.log" 2>/dev/null || true
echo "fertig $SPRACHE" >>"$LOG"
