# Querencia Anmeldung

Der grafische Anmeldebildschirm von **Querencia Desktop**: der Dienst
[greetd](https://git.sr.ht/~kennylevinsen/greetd) (Paket `greetd` der
Distribution) zeigt den GTK-4-Greeter [ReGreet](https://github.com/rharish101/ReGreet)
in einem [labwc](https://labwc.github.io/) ohne Menü und Tastenkürzel –
mit Grußtext „Querencia Desktop“, Thema Querencia-Klassisch, Symbolthema
Querencia und dem Hintergrund „Querencia Blau“.
Installiert wird es zusammen mit Querencia Desktop aus der APT-Quelle;
Anleitung auf <https://querencialinux.org>.

Zur Wahl steht **Querencia Desktop**. Andere Wayland-Sitzungen (etwa
Ubuntu/GNOME) erscheinen erst, wenn sie in
`/etc/querencia/greetd/sitzungen.conf` freigegeben sind; jede Sitzung
startet über die Sitzungshülle `sitzung-starten`, die
`XDG_CURRENT_DESKTOP` und `DESKTOP_SESSION` wie GDM setzt. GNOME braucht
GDM für die Bildschirmsperre: Auf einem Ubuntu Desktop bleibt GDM der
Standard-Anmeldedienst und bietet GNOME und Querencia Desktop an.

*English summary:* The graphical login screen of Querencia Desktop: greetd
with the ReGreet greeter in a locked-down labwc. Part of Querencia Desktop, a
classic GNOME-2-style desktop for Wayland. Alpha software; documentation is in
German.

> **Alpha.** Geprüft auf Wegwerf-VMs, noch nicht auf fremden Rechnern; GNOME
> wird nur angeboten, wenn freigegeben (Bildschirmsperre braucht GDM). Keine
> Sicherheits- oder Datenverlustgarantie.

## Stand

| | |
|---|---|
| Version | 0.1.5 (Anmeldebildschirm auch auf Italienisch, Spanisch, Französisch); seit 0.1.4 klare Meldung bei abgelaufenem Passwort mit Hinweis auf die Textkonsole); seit 0.1.3 Anmeldebildschirm durchgehend in der Systemsprache Deutsch oder Englisch, auch Sitzungsnamen und Meldungen von PAM); seit 0.1.2 Übersetzung über gettext, Uhr in der Zeitsprache, Info-Zeile; seit 0.1.1 Sitzungshülle, Sitzungsfilter, Vorwahl |
| Letzte Prüfung | 27.10.2026 (0.1.5): `tests/uebersetzung-pruefen.sh` (alle Kataloge), `tests/konfig-pruefen.sh`, isolierte Sprach- und Passwortprobe in it, es, fr, de und en (echtes greetd und PAM), danach keine Prozesse der Proben übrig. 27.10.2026 (0.1.4): `tests/uebersetzung-pruefen.sh`, `tests/konfig-pruefen.sh`, isolierte Passwortprobe `tests/passwort-probe.sh` mit echtem greetd und PAM (de und en). 26.10.2026 (0.1.3): `tests/konfig-pruefen.sh`, `tests/uebersetzung-pruefen.sh`, isolierte Sprachprobe `tests/sprache-probe.sh` (de und en). 22.10.2026 (0.1.2): `tests/uebersetzung-pruefen.sh`, `tests/konfig-pruefen.sh` mit Info-Zeile, Prüfliste Abschnitt Ü auf einer Test-VM. 20.10.2026 (0.1.1): `konfig-pruefen` 75/0, Umschaltung 30/0, Paketprüfung 236/0, Lintian ohne Fehler und Warnungen, Weg G der Prüfliste auf einer Test-VM bestanden (bekannte Grenze: GNOME-Sperre) |
| Getestet auf | Ubuntu 26.04, greetd aus dem Archiv, labwc 0.9.8, ReGreet 0.5.0 |
| Nicht getestet | andere Distributionen, Mehrmonitor, fremde Rechner |

Änderungen: [CHANGELOG.md](CHANGELOG.md).

## Was in diesem Repository liegt

Nur die Querencia-Teile; ReGreet selbst kommt aus dem Upstream-Release
0.5.0 und wird erst beim Paketbau dazugelegt (`docs/regreet-herkunft.md`).
Ein einziger, kleiner Patch im Packaging übersetzt seine sichtbaren Texte
und die Meldungen von PAM, erklärt ein abgelaufenes Passwort und stellt
die Uhr auf die Zeitsprache des Systems (`docs/uebersetzung.md`).

**Sprache:** Der Anmeldebildschirm folgt der Systemsprache
(`/etc/default/locale`, unter Ubuntu `localectl set-locale`): bei Deutsch
ist alles deutsch, bei Englisch alles englisch – Beschriftungen, Uhr,
Sitzungsnamen, Meldungen. Seit 0.1.5 ebenso Italienisch, Spanisch und
Französisch; andere Sprachen zeigen englische Beschriftungen.
GTK-Dialoge folgen dem Sprachpaket des Systems:
`language-pack-gnome-<xx>` (deutsch `language-pack-gnome-de`); fehlt es,
bleiben GTK-eigene Texte wie der Tooltip am Auge im Passwortfeld englisch.

| Ordner | Inhalt | installiert nach |
|---|---|---|
| `po/*.po` | Übersetzungen der Texte von ReGreet: de, it, es, fr | `/usr/share/locale/<sprache>/LC_MESSAGES/querencia-anmeldung.mo` |
| `config/greetd/` | greetd- und ReGreet-Konfiguration, labwc-Konfiguration des Anmeldebildschirms | `/etc/querencia/greetd/` |
| `sbin/querencia-anmeldung` | startet greetd mit dieser Konfiguration | `/usr/sbin/` |
| `libexec/anmeldung-starten` | Befehl des Anmeldebildschirms: Sitzungsauswahl, Sprache und Tastatur des Systems, dann labwc + ReGreet | `/usr/libexec/querencia-anmeldung/` |
| `libexec/sitzungen-auswahl` | Sitzungsliste für ReGreet: Querencia und freigegebene Sitzungen, Vorwahl | `/usr/libexec/querencia-anmeldung/` |
| `libexec/sitzung-starten` | Sitzungshülle: Variablen wie GDM, dann `Exec` | `/usr/libexec/querencia-anmeldung/` |
| `systemd/querencia-anmeldung.service` | Dienst mit `Alias=display-manager.service` | `/usr/lib/systemd/system/` |
| `tmpfiles/` | Zustands- und Protokollordner von ReGreet | `/usr/lib/tmpfiles.d/` |
| `man/querencia-anmeldung.8` | Handbuchseite | `/usr/share/man/man8/` |
| `tests/konfig-pruefen.sh` | statische Prüfung (läuft auch beim Paketbau) | – |
| `tests/uebersetzung-pruefen.sh` | Texte des gepatchten ReGreet gegen alle Kataloge in `po/`, keine englischen Reste, erwartete Texte aus `tests/sprache-texte.txt` (läuft beim Paketbau) | – |
| `tests/sprache-probe.sh` | isolierte Sprachprobe: Fotos des gebauten Anmeldebildschirms in einer Sprache, ohne Systemänderung | – |
| `tests/passwort-probe.sh` | isolierte Passwortprobe: echtes greetd und PAM mit Wegwerf-Benutzer (falsches, abgelaufenes, gültiges Passwort), Fotos und Protokollmitschnitt, ohne Systemänderung | – |
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

## GNOME und die Bildschirmsperre

GNOME sperrt den Bildschirm nur, wenn GDM läuft. gnome-shell legt die
Bildschirmsperre beim Start nur an, wenn der Dienst
`org.gnome.DisplayManager` auf dem Systembus antwortet, also GDM:
`js/ui/main.js` (`if (LoginManager.canLock()) screenShield = new
ScreenShield.ScreenShield();`) und `js/misc/loginManager.js`
(`canLock()` fragt `org.gnome.DisplayManager.Manager` nach `Version`),
nachgelesen in gnome-shell 50.1 (Ubuntu 26.04). Ohne GDM meldet GNOME
„Bildschirmsperre deaktiviert – Die Sperrung des Bildschirms erfordert den
GNOME Display-Manager“.

Das gilt für **jeden** anderen Anmeldebildschirm (greetd, LightDM, SDDM …),
nicht nur für die Querencia Anmeldung, und ist kein Fehler von Querencia
Desktop. Querencia Desktop sperrt mit eigenem Werkzeug (`querencia-sitzung`,
Strg+Alt+L, Wayland-Protokoll `ext-session-lock`) und braucht dafür keinen
GDM.

Deshalb bietet die Querencia Anmeldung GNOME nicht an, solange es nicht in
`/etc/querencia/greetd/sitzungen.conf` freigegeben ist, und auf einem
Ubuntu Desktop bleibt GDM der Standard-Anmeldedienst. Die Querencia
Anmeldung bildet `org.gnome.DisplayManager` bewusst nicht nach.

## Bauen und Prüfen

```bash
sh tests/konfig-pruefen.sh
```

```bash
bash werkzeuge/paket-bauen.sh
```

Bauanleitung: [docs/building.md](docs/building.md); Prüfliste für Test-VMs:
[docs/pruefung-anmeldung.md](docs/pruefung-anmeldung.md). Der Paketbau braucht
zusätzlich das Repository `querencia-packaging` (Ordner
`querencia-anmeldung/`). Arbeitsweise: [CONTRIBUTING.md](CONTRIBUTING.md).

## Lizenz

GPL-3.0-or-later, siehe [LICENSE](LICENSE) (reiner Lizenztext). Copyright 2026
Querencia Desktop contributors; Urheber- und Fremdhinweise in
[COPYRIGHT](COPYRIGHT).

ReGreet 0.5.0 liegt nicht in diesem Repository; das Paket baut es aus der
Upstream-Quelle mit dem einen Übersetzungs-Patch. ReGreet steht unter GPL-3.0-or-later (einzelne
Dateien zusätzlich MIT bzw. 0BSD, siehe
[docs/regreet-herkunft.md](docs/regreet-herkunft.md)); wegen der Crate
`greetd_ipc` (GPL-3.0-only) ist das gebaute ReGreet-Programm als Ganzes
GPL-3.0. Die Lizenzen aller mitgebauten Crates stehen in `debian/copyright`
des Pakets. greetd und labwc kommen aus den Distributionspaketen.

Name und Logo „Querencia“ sind keine freien Inhalte: [MARKE.md](MARKE.md).

## Fehler melden

Fehler, Wünsche und Fragen zu Querencia gehen an die gemeinsame Meldestelle:
<https://github.com/querencia-desktop/querencia/issues/new/choose>.
Sicherheitslücken bitte nicht öffentlich melden, siehe [SECURITY.md](SECURITY.md).
