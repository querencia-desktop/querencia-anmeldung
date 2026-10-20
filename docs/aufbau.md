# Aufbau

```text
systemd
 └─ querencia-anmeldung.service      (Alias display-manager.service, Konsole 7)
     └─ /usr/sbin/querencia-anmeldung
         └─ greetd --config /etc/querencia/greetd/config.toml
             └─ als _greetd: /usr/libexec/querencia-anmeldung/anmeldung-starten
                 ├─ sitzungen-auswahl → /run/querencia-anmeldung/wayland-sessions
                 └─ dbus-run-session -- labwc -C /etc/querencia/greetd/labwc -S regreet
                     └─ /usr/libexec/querencia-anmeldung/regreet (ohne XDG_DATA_DIRS)
                         liest /etc/querencia/greetd/regreet.toml
                         Sitzungen: nur /run/querencia-anmeldung/wayland-sessions
```

Nach der Anmeldung startet greetd die gewählte Sitzung als der
angemeldete Benutzer: `Exec=` der erzeugten Sitzungsdatei, also immer
`/usr/libexec/querencia-anmeldung/sitzung-starten <originaldatei>`.
ReGreet setzt `XDG_SESSION_TYPE=wayland`. labwc und ReGreet des
Anmeldebildschirms enden dabei.

## Sitzungen

ReGreet 0.5.0 kennt keinen Befehlsvorsatz für Wayland-Sitzungen (nur
`x11_prefix` für `xsessions`, `src/sysutil.rs`) und übernimmt `Exec`
unverändert; `DesktopNames` liest es nicht. Es sucht Sitzungen in
`$XDG_DATA_DIRS/{xsessions,wayland-sessions}`, wenn die Variable gesetzt
ist, sonst im eingebauten `SESSION_DIRS`. Die Querencia Anmeldung baut
ReGreet deshalb mit `SESSION_DIRS=/run/querencia-anmeldung/wayland-sessions`
und startet es ohne `XDG_DATA_DIRS`; ReGreet selbst bleibt unverändert.

`sitzungen-auswahl` füllt diesen Ordner bei jedem Erscheinen des
Anmeldebildschirms aus `/usr/local/share/wayland-sessions` und
`/usr/share/wayland-sessions` (die erste Datei eines Namens gewinnt) und
schreibt die Begründung je Datei nach `/run/querencia-anmeldung/auswahl.txt`:

| Sitzung | angeboten? |
|---|---|
| `DesktopNames` enthält `X-Querencia` | ja |
| in `sitzungen.conf` unter `freigeben` | ja |
| andere (GNOME, KDE …) | nein (`nicht-freigegeben`) |
| `labwc.desktop` oder `DesktopNames=labwc` ohne `X-Querencia` | nie (`labwc-nie`), auch nicht freigegeben |
| `Hidden=true`, `NoDisplay=true` | nie (`versteckt`) |
| von `sitzung-starten --pruefen` abgelehnt (keine Gruppe, kein `Exec`, `TryExec` fehlt) | nie (`kaputt`) |
| Pfad mit Leerzeichen oder Sonderzeichen | nie (`pfad-zeichen`; greetd fügt den Befehl unmaskiert zusammen) |
| `xsessions` (X11) | nie (nicht durchsucht) |
| Sitzungshülle fehlt | keine Sitzung (`keine-huelle`) |

Danach bekommt in `/var/lib/querencia-anmeldung/state.toml` jeder Benutzer
(UID `UID_MIN`…`UID_MAX`, mit Anmelde-Shell) ohne Eintrag oder mit einer
Sitzung, die nicht mehr angeboten wird, „Querencia Desktop“ vorgewählt
(KB3). ReGreet ordnet die Sitzungen zufällig an und würde sonst die erste
nehmen.

`sitzung-starten <sitzungsdatei>` macht, was GDM vor dem Start einer
Sitzung macht: `XDG_CURRENT_DESKTOP` aus `DesktopNames` (`;` → `:`, ohne
`DesktopNames` ungesetzt), `XDG_SESSION_DESKTOP` und `DESKTOP_SESSION`
aus dem Dateinamen, `XDG_SESSION_TYPE=wayland`; danach liest eine Shell
`/etc/profile` und `~/.profile` (wie die Anmelde-Shell unter GDM, daher
`source_profile = false` in `config.toml`) und führt `Exec` aus. Ubuntus
`/etc/profile.d` ergänzt dann die Ordner der Sitzung (z. B.
`/etc/xdg/xdg-ubuntu`). `GDMSESSION` setzt die Hülle nicht.

**GNOME und die Bildschirmsperre:** gnome-shell legt die Bildschirmsperre
nur an, wenn GDM auf dem Systembus antwortet (`LoginManager.canLock()`
fragt `org.gnome.DisplayManager` ab, `js/ui/main.js`). Unter der
Querencia Anmeldung läuft GDM nicht; GNOME startet dann zwar mit
Ubuntu-Vorgaben, aber **ohne Bildschirmsperre** – die Variablen ändern
daran nichts. Deshalb ist GNOME nicht freigegeben, und bei installiertem
GNOME bleibt GDM Standard-Anmeldedienst.

`huelle = nein` in `sitzungen.conf` startet dieselben Sitzungen über
`sitzung-starten --ohne-variablen` (Profile und `Exec` wie 0.1.0, ohne
die vier Variablen) – Rückfall, falls eine Sitzung mit den Variablen nicht
zurechtkommt. In ReGreet bleibt die Eingabe eines eigenen Befehls möglich
(Stift-Knopf neben der Sitzung); dieser Weg umgeht Auswahl und Hülle.

## Pfade

| Pfad | Inhalt | Herkunft |
|---|---|---|
| `/etc/querencia/greetd/config.toml` | greetd: Konsole 7, Befehl `anmeldung-starten`, Benutzer `_greetd` | Conffile |
| `/etc/querencia/greetd/regreet.toml` | Grußtext, Hintergrund, GTK-Thema, Symbolthema, Zeiger, Schrift, Uhr, Befehle für Neustart/Ausschalten | Conffile |
| `/etc/querencia/greetd/sitzungen.conf` | freigegebene Sitzungen neben Querencia, Hülle ein/aus | Conffile |
| `/etc/querencia/greetd/regreet.css` | optional, eigenes CSS für ReGreet | vom Verwalter |
| `/etc/querencia/greetd/labwc/{rc.xml,menu.xml,environment}` | labwc ohne Bindungen und mit leeren Menüs, Zeiger DMZ | Conffiles |
| `/usr/libexec/querencia-anmeldung/regreet` | ReGreet 0.5.0, gebaut mit den Pfaden dieser Tabelle | Paket |
| `/usr/libexec/querencia-anmeldung/{sitzungen-auswahl,sitzung-starten}` | Sitzungsliste und Sitzungshülle | Paket |
| `/run/querencia-anmeldung/wayland-sessions/`, `auswahl.txt` | Sitzungsliste für ReGreet, Begründung je Datei | `sitzungen-auswahl` (`_greetd`) |
| `/var/lib/querencia-anmeldung/state.toml` | zuletzt gewählter Benutzer und Sitzung | ReGreet (`_greetd`) |
| `/var/log/querencia-anmeldung/log` | Protokoll von ReGreet | ReGreet (`_greetd`) |
| `/etc/X11/default-display-manager`, `/etc/systemd/system/display-manager.service` | Standard-Anmeldedienst | Wartungsskripte (`docs/umschalten.md`) |

Die greetd-Konfiguration der Distribution (`/etc/greetd/config.toml`) und
`greetd.service` bleiben unberührt; die Querencia Anmeldung startet greetd
über einen eigenen Dienst mit eigener Konfiguration. Deshalb kann greetd
mit anderem Greeter daneben eingerichtet bleiben.

## Anmeldebildschirm-Compositor

labwc dient nur als Wayland-Compositor für ReGreet:

- `rc.xml`: Fensterrahmen zeichnet ReGreet (`decoration client`); eine
  einzige Bindung mit Aktion `None` sorgt dafür, dass labwc keine
  Standardbelegung lädt und danach gar keine Bindung hat – kein
  Tastenkürzel, keine Maustaste auf dem Hintergrund.
- `menu.xml`: leeres Wurzel- und Fenstermenü, damit labwc keine
  Ersatzmenüs anlegt (dessen Wurzelmenü hätte „Terminal“ und „Exit“).
- `environment`: `LABWC_UPDATE_ACTIVATION_ENV=0` (nichts in die
  Aktivierungsumgebung von `_greetd`), Zeiger `DMZ-White` 24 px.

`anmeldung-starten` liest `/etc/default/locale` (`LANG`, `LANGUAGE`,
`LC_*`) und `/etc/default/keyboard` (`XKBLAYOUT` usw. als
`XKB_DEFAULT_*`) zeilenweise, damit Uhr und Tastaturbelegung des
Anmeldebildschirms zum System passen; ein Tippfehler in diesen Dateien
verhindert die Anmeldung nicht.

## Abhängigkeiten

| Paket | warum |
|---|---|
| `greetd` (≥ 0.10) | Display-Manager-Dienst, PAM-Dateien, Benutzer `_greetd` |
| `labwc` (≥ 0.9.8) | Compositor des Anmeldebildschirms (Querencia-Backport 0.9.8) |
| `dbus-daemon` | `dbus-run-session` |
| `glycin-loaders` | ReGreet lädt das Hintergrundbild über glycin |
| `debconf` | Frage `shared/default-x-display-manager` |
| empfohlen: `querencia-shell`, `querencia-symbole`, `dmz-cursor-theme`, `fonts-dejavu-core` | Hintergrund und GTK-Thema, Symbolthema, Zeiger, Schrift; fehlen sie, nimmt GTK seine Vorgaben |

Das Metapaket `querencia-desktop` schlägt die Querencia Anmeldung nur vor
(`Suggests`): Wer Querencia neben Ubuntu Desktop installiert, behält GDM,
bis er selbst umschaltet.
