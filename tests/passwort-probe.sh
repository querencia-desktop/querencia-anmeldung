#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Isolierte Passwortprobe des Anmeldebildschirms: echtes greetd und echtes
# PAM (Dienst greetd des Systems, pam_unix) mit einem Wegwerf-Benutzer,
# dazu das gebaute ReGreet über den echten Starter anmeldung-starten in
# einem kopflosen labwc. Fotografiert drei Fälle in einer Sprache:
# falsches Passwort, abgelaufenes Passwort (chage -d 0) und eine
# gelungene Anmeldung. Der Mitschnitt des greetd-Protokolls zeigt, welche
# Nachrichten laufen (Antworten des Greeters ohne Inhalt).
#
# Nichts am System wird geändert: alles läuft in einem eigenen Benutzer-
# und Mount-Namensraum mit untergeordneten IDs (/etc/subuid). /etc liegt
# dort unter einem Overlay; Benutzer "probe", sein Passwort (zufällig, nur
# im Speicher des Namensraums), /etc/querencia/greetd und
# /etc/default/locale gibt es nur dort. greetd bekommt statt einer echten
# Konsole ein pty und die Vorladebibliothek tests/vt-attrappe.c.
#
#   sh tests/passwort-probe.sh <paketwurzel> <themawurzel> <ausgabe> <locale>
#
# <paketwurzel>  entpacktes querencia-anmeldung_*.deb (dpkg-deb -x)
# <themawurzel>  entpackte querencia-shell und querencia-symbole; "" geht
# <ausgabe>      Ordner für <sprache>-NN-*.png, ipc-<sprache>.txt und Logs
# <locale>       z. B. de_DE.UTF-8 oder en_US.UTF-8 (muss erzeugt sein)
#
# Braucht greetd, labwc, grim, wlrctl, wtype, gcc, dbus-daemon, python3-gi,
# unshare mit --map-auto (newuidmap) und Einträge in /etc/subuid und
# /etc/subgid. Exit 0 = Probe durchgelaufen; den Inhalt zeigen die Fotos
# und ipc-<sprache>.txt.
set -eu
PAKET=$(realpath "${1:?Paketwurzel fehlt}")
THEMA=${2-}
[ -z "$THEMA" ] || THEMA=$(realpath "$THEMA")
mkdir -p "${3:?Ausgabeordner fehlt}"
AUS=$(realpath "$3")
SPRACHE=${4:?Locale fehlt}
HIER=$(dirname "$(realpath "$0")")

if [ "${QUERENCIA_PROBE_INNEN:-}" != ja ]; then
    QUERENCIA_PROBE_INNEN=ja exec unshare --map-root-user --map-auto -m --propagation private \
        sh "$0" "$@"
fi

# Am Ende alle Prozesse dieses Benutzer-Namensraums beenden (greetd,
# labwc, Schein-Bus, Mitschnitt, Syslog-Fänger): Der Namensraum gehört nur
# dieser Probe. $(jobs -p) wäre in sh leer, die Hintergrundprozesse
# blieben sonst stehen.
# Nur im eigenen Namensraum weitermachen (im ersten Namensraum bildet
# uid_map alle 4294967295 IDs ab).
if awk '$3 == 4294967295 { f = 1 } END { exit !f }' /proc/self/uid_map; then
    echo "passwort-probe: nicht im eigenen Namensraum, Abbruch" >&2
    exit 1
fi
EIGEN=$(readlink /proc/$$/ns/user)
aufraeumen() {
    for d in /proc/[0-9]*; do
        p=${d#/proc/}
        [ "$p" = $$ ] && continue
        if [ "$(readlink "$d/ns/user" 2>/dev/null)" = "$EIGEN" ]; then
            kill "$p" 2>/dev/null || true
        fi
    done
    return 0
}
trap aufraeumen EXIT

kurz=${SPRACHE%%_*}
LOG=$AUS/log-$kurz.txt
IPC=$AUS/ipc-$kurz.txt
: >"$LOG"
: >"$IPC"

# Arbeitsordner nur im Namensraum: tmpfs auf /mnt (Passwort, Overlay,
# Originale der überblendeten Ordner) und auf /run (greetd-Socket,
# Laufzeitordner, Schein-Systembus).
mount -t tmpfs -o mode=700 none /mnt
mkdir -m 700 /mnt/w /mnt/orig /mnt/oben /mnt/arbeit
W=/mnt/w
mount -t tmpfs -o mode=755 none /run
[ -d /tmp/.X11-unix ] && mount -t tmpfs none /tmp/.X11-unix

# /etc unter einem Overlay. Dateien, die das Overlay sonst aus dem
# unteren /etc lesen müsste (nur für root lesbar), liegen vorher oben:
# shadow und gshadow ohne Passwörter, die Sperrdatei, die Sicherungen;
# /etc/default/locale mit der Probesprache.
O=/mnt/oben
cp /etc/passwd /etc/group "$O/"
awk -F: '{ print $1 ":*:20000:0:99999:7:::" }' /etc/passwd >"$O/shadow"
awk -F: '{ print $1 ":*::" }' /etc/group >"$O/gshadow"
for f in passwd shadow group gshadow; do cp "$O/$f" "$O/$f-"; done
: >"$O/.pwd.lock"
mkdir "$O/default"
printf 'LANG=%s\n' "$SPRACHE" >"$O/default/locale"
mount -t overlay overlay -o lowerdir=/etc,upperdir=/mnt/oben,workdir=/mnt/arbeit /etc

# Wegwerf-Benutzer mit zufälligem Passwort; abgelaufen wie nach
# "chage -d 0" (Ü8 der Prüfliste)
useradd -M -s /bin/bash -c "Querencia Probe" -K SUB_UID_COUNT=0 -K SUB_GID_COUNT=0 probe
head -c 12 /dev/urandom | base64 | tr -d '/+=' >/mnt/passwort
printf 'probe:%s\n' "$(cat /mnt/passwort)" | chpasswd
chage -d 0 probe
echo "Benutzer probe: $(chage -l probe | head -1)" >>"$LOG"

# Konfiguration des Pakets nach /etc/querencia/greetd, Hintergrund aus der
# Themawurzel
mkdir -p /etc/querencia
cp -r "$PAKET/etc/querencia/greetd" /etc/querencia/
sed -i -e "s#^path = \"/usr/share/querencia/#path = \"$THEMA/usr/share/querencia/#" \
    /etc/querencia/greetd/regreet.toml

# Katalog des Pakets und Thema dort einblenden, wo gettext und GTK suchen;
# die Originaldateien bleiben sichtbar.
einblenden() { # <zielordner> <quellordner>
    [ -d "$1" ] && [ -d "$2" ] || return 0
    o=/mnt/orig/$(printf '%s' "$1" | tr / _)
    mkdir -p "$o"
    mount --bind "$1" "$o"
    mount -t tmpfs none "$1"
    for f in "$o"/* "$2"/*; do
        [ -e "$f" ] && [ ! -e "$1/${f##*/}" ] && ln -s "$f" "$1/${f##*/}"
    done
    return 0
}
einblenden "/usr/share/locale/$kurz/LC_MESSAGES" "$PAKET/usr/share/locale/$kurz/LC_MESSAGES"
if [ -n "$THEMA" ]; then
    einblenden /usr/share/themes "$THEMA/usr/share/themes"
    einblenden /usr/share/icons "$THEMA/usr/share/icons"
fi

# Sitzungen: Querencia Desktop als Probedatei, die Sitzung endet sofort
Q=$W/quellen
mkdir -p "$Q"
cat >"$Q/querencia.desktop" <<'EOF'
[Desktop Entry]
Name=Querencia Desktop
Comment=Querencia Desktop session
Exec=/bin/true
Type=Application
DesktopNames=X-Querencia
EOF
for d in /var/lib/querencia-anmeldung /var/lib/regreet /var/log/querencia-anmeldung; do
    [ -d "$d" ] && mount -t tmpfs none "$d"
done
mkdir -p /run/querencia-anmeldung

# Meldungen von PAM (syslog) in eine Datei statt ins Journal: /dev/log
# zeigt auf /run/systemd/journal/dev-log, das hier ein eigener Socket ist.
mkdir -p /run/systemd/journal
python3 -I -c '
import socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
s.bind("/run/systemd/journal/dev-log")
with open(sys.argv[1], "a", encoding="utf-8", errors="replace") as f:
    while True:
        f.write(s.recv(65536).decode("utf-8", "replace").rstrip("\n") + "\n")
        f.flush()
' "$AUS/syslog-$kurz.txt" &

# Schein-AccountsService auf einem eigenen Systembus (Benutzer probe)
mkdir -p /run/dbus
cat >"$W/bus.conf" <<'EOF'
<busconfig><type>system</type><listen>unix:path=/run/dbus/system_bus_socket</listen>
<auth>EXTERNAL</auth><policy context="default"><allow user="*"/>
<allow own="*"/><allow send_destination="*"/><allow receive_sender="*"/></policy></busconfig>
EOF
dbus-daemon --config-file="$W/bus.conf" --nofork --nopidfile >>"$LOG" 2>&1 &
sleep 0.5
python3 -I "$HIER/sprache-probe-konten.py" >>"$LOG" 2>&1 &

# Ersatz-Konsole: ein pty über /dev/tty0 und /dev/tty7, dazu die VT-Attrappe
gcc -shared -fPIC -O2 -o "$W/vt-attrappe.so" "$HIER/vt-attrappe.c" -ldl
python3 -I -c '
import os, pty, sys, time
m, s = pty.openpty()
print(os.ttyname(s), flush=True)
while True:
    try:
        os.read(m, 4096)
    except OSError:
        time.sleep(1)
' >"$W/pty" &
i=0
while [ ! -s "$W/pty" ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i + 1)); done
for t in /dev/tty0 /dev/tty7; do mount --bind "$(cat "$W/pty")" "$t"; done

# Befehl des Anmeldebildschirms: Mitschnitt zwischen ReGreet und greetd,
# dann der echte Starter mit den Programmen des Pakets, labwc kopflos
cat >"$W/greeter" <<EOF
#!/bin/sh
rm -f /run/mitschnitt.sock
python3 -I "$HIER/passwort-probe-ipc.py" /run/mitschnitt.sock "\$GREETD_SOCK" "$IPC" &
while [ ! -S /run/mitschnitt.sock ]; do sleep 0.1; done
export GREETD_SOCK=/run/mitschnitt.sock
mkdir -p -m 700 /run/greeter
export XDG_RUNTIME_DIR=/run/greeter
export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 WLR_HEADLESS_OUTPUTS=1
export QUERENCIA_ANMELDUNG_REGREET="$PAKET/usr/libexec/querencia-anmeldung/regreet -l $AUS/regreet-$kurz.log"
export QUERENCIA_ANMELDUNG_AUSWAHL="$PAKET/usr/libexec/querencia-anmeldung/sitzungen-auswahl"
export QUERENCIA_ANMELDUNG_HUELLE="$PAKET/usr/libexec/querencia-anmeldung/sitzung-starten"
export QUERENCIA_ANMELDUNG_QUELLEN="$Q"
exec sh "$PAKET/usr/libexec/querencia-anmeldung/anmeldung-starten"
EOF
chmod 755 "$W/greeter"
cat >"$W/greetd.toml" <<EOF
[terminal]
vt = 7
[general]
source_profile = false
[default_session]
command = "$W/greeter"
user = "root"
EOF

LD_PRELOAD=$W/vt-attrappe.so greetd --config "$W/greetd.toml" >>"$AUS/greetd-$kurz.log" 2>&1 &
GREETD=$!
i=0
while [ ! -S /run/greeter/wayland-0 ] && [ $i -lt 100 ]; do sleep 0.2; i=$((i + 1)); done
export XDG_RUNTIME_DIR=/run/greeter WAYLAND_DISPLAY=wayland-0
sleep 4

foto() { grim "$AUS/$kurz-$1.png"; echo "Foto $kurz-$1.png" >>"$LOG"; }
# Zeiger an eine Bildschirmstelle (kopfloser Ausgang 1280x720)
zeiger() { wlrctl pointer move -5000 -5000; wlrctl pointer move "$1" "$2"; sleep 1.5; }
klick() { zeiger "$1" "$2"; wlrctl pointer click left; sleep 1.5; }
# Die erste Taste eines neuen virtuellen Tastenfelds geht verloren
# (Tastaturbelegung wird gewechselt); deshalb erst Umschalt, dann langsam.
eingabe() { wtype -k Shift_L; sleep 0.5; wtype -d 40 "$1"; sleep 0.5; wtype -k Return; }
abschnitt() { echo "== $1" >>"$IPC"; echo "== $1" >>"$LOG"; }

foto 01-start
abschnitt "falsches Passwort"
klick 839 444; foto 02-abfrage
eingabe 1111; sleep 4.5; foto 03-falsch
abschnitt "abgelaufenes Passwort"
klick 839 444
eingabe "$(cat /mnt/passwort)"; sleep 3; foto 04-abgelaufen
sleep 5; foto 05-abgelaufen-nach-8s
abschnitt "Passwort gültig (chage -d heute)"
chage -d "$(date +%F)" probe
klick 839 444
eingabe "$(cat /mnt/passwort)"; sleep 6; foto 06-nach-anmeldung
echo "fertig $SPRACHE" >>"$LOG"
kill "$GREETD" 2>/dev/null || true
sleep 1
