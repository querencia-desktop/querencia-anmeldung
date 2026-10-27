# SPDX-License-Identifier: GPL-3.0-or-later
# Gemeinsame Teile der isolierten Proben (tests/sprache-probe.sh,
# tests/passwort-probe.sh); wird im eigenen Benutzer- und Mount-Namensraum
# der Probe mit "." eingelesen.

# Am Ende alle Prozesse dieses Benutzer-Namensraums beenden (labwc, Busse,
# greetd, Helfer): Der Namensraum gehört nur der Probe. $(jobs -p) wäre in
# sh leer, die Hintergrundprozesse blieben sonst stehen.
probe_aufraeumen_vorbereiten() {
    # Nur im eigenen Namensraum (im ersten bildet uid_map alle IDs ab)
    if awk '$3 == 4294967295 { f = 1 } END { exit !f }' /proc/self/uid_map; then
        echo "Probe: nicht im eigenen Namensraum, Abbruch" >&2
        exit 1
    fi
    PROBE_NS=$(readlink /proc/$$/ns/user)
    trap probe_aufraeumen EXIT
}
probe_aufraeumen() {
    for d in /proc/[0-9]*; do
        p=${d#/proc/}
        [ "$p" = $$ ] && continue
        if [ "$(readlink "$d/ns/user" 2>/dev/null)" = "$PROBE_NS" ]; then
            kill "$p" 2>/dev/null || true
        fi
    done
    return 0
}

# Locale nur im Namensraum: Ist sie auf dem Rechner nicht erzeugt (etwa
# it_IT auf einem deutschen System), übersetzt localedef sie in den
# Arbeitsordner, und /usr/lib/locale bekommt sie dazu (die Originale
# bleiben über Verweise sichtbar). Am System ändert sich nichts.
#   probe_locale <locale> <arbeitsordner im namensraum>
probe_locale() {
    name=${1%%.*}.utf8
    locale -a | grep -qix "$name" && return 0
    localedef -i "${1%%.*}" -f UTF-8 "$2/$name" 2>/dev/null || [ -f "$2/$name/LC_CTYPE" ] ||
        { echo "Probe: localedef ${1%%.*} gescheitert" >&2; return 1; }
    mkdir -p "$2/orig-locale"
    mount --bind /usr/lib/locale "$2/orig-locale"
    mount -t tmpfs none /usr/lib/locale
    for f in "$2/orig-locale"/*; do ln -s "$f" /usr/lib/locale/; done
    cp -r "$2/$name" /usr/lib/locale/
}
