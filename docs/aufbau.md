# Aufbau

```text
systemd
 └─ querencia-anmeldung.service      (Alias display-manager.service, Konsole 7)
     └─ /usr/sbin/querencia-anmeldung
         └─ greetd --config /etc/querencia/greetd/config.toml
             └─ als _greetd: /usr/libexec/querencia-anmeldung/anmeldung-starten
                 └─ dbus-run-session -- labwc -C /etc/querencia/greetd/labwc -S regreet
                     └─ /usr/libexec/querencia-anmeldung/regreet
                         liest /etc/querencia/greetd/regreet.toml
                         Sitzungen: /usr/share/wayland-sessions, /usr/share/xsessions
```

Nach der Anmeldung startet greetd die gewählte Sitzung (`Exec=` der
Sitzungsdatei) als der angemeldete Benutzer; ReGreet setzt
`XDG_SESSION_TYPE` (wayland bzw. x11). labwc und ReGreet des
Anmeldebildschirms enden dabei.

## Pfade

| Pfad | Inhalt | Herkunft |
|---|---|---|
| `/etc/querencia/greetd/config.toml` | greetd: Konsole 7, Befehl `anmeldung-starten`, Benutzer `_greetd` | Conffile |
| `/etc/querencia/greetd/regreet.toml` | Grußtext, Hintergrund, GTK-Thema, Symbolthema, Zeiger, Schrift, Uhr, Befehle für Neustart/Ausschalten | Conffile |
| `/etc/querencia/greetd/regreet.css` | optional, eigenes CSS für ReGreet | vom Verwalter |
| `/etc/querencia/greetd/labwc/{rc.xml,menu.xml,environment}` | labwc ohne Bindungen und mit leeren Menüs, Zeiger DMZ | Conffiles |
| `/usr/libexec/querencia-anmeldung/regreet` | ReGreet 0.5.0, gebaut mit den Pfaden dieser Tabelle | Paket |
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
