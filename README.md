# Querencia Anmeldung

Der grafische Anmeldebildschirm von **Querencia Desktop**: der Dienst
[greetd](https://git.sr.ht/~kennylevinsen/greetd) (Paket `greetd` der
Distribution) zeigt den GTK-4-Greeter [ReGreet](https://github.com/rharish101/ReGreet)
in einem [labwc](https://labwc.github.io/) ohne Menü und Tastenkürzel –
mit Grußtext „Querencia Desktop“, Thema Querencia-Klassisch, Symbolthema
Querencia und dem Hintergrund „Querencia Blau“.

Zur Wahl steht **Querencia Desktop**. Andere Wayland-Sitzungen (etwa
Ubuntu/GNOME) erscheinen erst, wenn sie in
`/etc/querencia/greetd/sitzungen.conf` freigegeben sind; jede Sitzung
startet über die Sitzungshülle `sitzung-starten`, die
`XDG_CURRENT_DESKTOP` und `DESKTOP_SESSION` wie GDM setzt. GNOME braucht
GDM für die Bildschirmsperre: Auf einem Ubuntu Desktop bleibt GDM der
Standard-Anmeldedienst und bietet GNOME und Querencia Desktop an.

## Was in diesem Repository liegt

Nur die Querencia-Teile; ReGreet selbst kommt unverändert aus dem
Upstream-Release 0.5.0 und wird erst beim Paketbau dazugelegt
(`docs/regreet-herkunft.md`).

| Ordner | Inhalt | installiert nach |
|---|---|---|
| `config/greetd/` | greetd- und ReGreet-Konfiguration, labwc-Konfiguration des Anmeldebildschirms | `/etc/querencia/greetd/` |
| `sbin/querencia-anmeldung` | startet greetd mit dieser Konfiguration | `/usr/sbin/` |
| `libexec/anmeldung-starten` | Befehl des Anmeldebildschirms: Sitzungsauswahl, Sprache und Tastatur des Systems, dann labwc + ReGreet | `/usr/libexec/querencia-anmeldung/` |
| `libexec/sitzungen-auswahl` | Sitzungsliste für ReGreet: Querencia und freigegebene Sitzungen, Vorwahl | `/usr/libexec/querencia-anmeldung/` |
| `libexec/sitzung-starten` | Sitzungshülle: Variablen wie GDM, dann `Exec` | `/usr/libexec/querencia-anmeldung/` |
| `systemd/querencia-anmeldung.service` | Dienst mit `Alias=display-manager.service` | `/usr/lib/systemd/system/` |
| `tmpfiles/` | Zustands- und Protokollordner von ReGreet | `/usr/lib/tmpfiles.d/` |
| `man/querencia-anmeldung.8` | Handbuchseite | `/usr/share/man/man8/` |
| `tests/konfig-pruefen.sh` | statische Prüfung (läuft auch beim Paketbau) | – |
| `werkzeuge/paket-bauen.sh` | baut das Debian-Paket nach `build/` | – |

Das Debian-Paket `querencia-anmeldung` (`debian/`, debconf-Umschaltung)
liegt wie bei allen Querencia-Paketen im Repository `querencia-packaging`
(Ordner `querencia-anmeldung/`).

## Verhältnis zu GDM

Die Querencia Anmeldung verdrängt keinen vorhandenen Display-Manager. Sie
wird nur Standard, wenn noch keiner eingerichtet ist, wenn man sie in der
debconf-Frage wählt oder mit `QUERENCIA_ANMELDUNG=ja`. Umschalten in beide
Richtungen:

```bash
sudo dpkg-reconfigure querencia-anmeldung
```

Entfernen trägt den vorherigen Display-Manager (z. B. GDM) wieder ein.
Einzelheiten: `docs/umschalten.md`.

## Bauen und Prüfen

```bash
sh tests/konfig-pruefen.sh
```

```bash
bash werkzeuge/paket-bauen.sh
```

Bauanleitung: `docs/building.md`; Prüfliste für Test-VMs:
`docs/pruefung-anmeldung.md`.

## Lizenz

GPL-3.0-or-later (`LICENSE`, Vermerk in `COPYRIGHT`). ReGreet steht
ebenfalls unter GPL-3.0-or-later (einzelne Dateien zusätzlich MIT bzw.
0BSD, siehe `docs/regreet-herkunft.md`).

