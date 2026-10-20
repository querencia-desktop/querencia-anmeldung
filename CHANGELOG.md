# Änderungen

## 0.1.1 – 20.10.2026

- Sitzungshülle `sitzung-starten <sitzungsdatei>` (KB1): setzt wie GDM
  `XDG_CURRENT_DESKTOP` aus `DesktopNames` (`;` → `:`),
  `XDG_SESSION_DESKTOP` und `DESKTOP_SESSION` aus dem Dateinamen und
  `XDG_SESSION_TYPE=wayland`, liest danach `/etc/profile` und
  `~/.profile` und führt `Exec` aus. greetd liest die Profile nicht mehr
  vorher (`source_profile = false`). Für Querencia Desktop dasselbe
  Ergebnis wie bisher (`X-Querencia`).
- Sitzungsauswahl `sitzungen-auswahl` bei jedem Erscheinen des
  Anmeldebildschirms: ReGreet (gebaut mit `SESSION_DIRS` auf
  `/run/querencia-anmeldung/wayland-sessions`, ohne `XDG_DATA_DIRS`
  gestartet) sieht nur noch Querencia-Sitzungen und in
  `/etc/querencia/greetd/sitzungen.conf` freigegebene; nie die nackte
  labwc-Sitzung (K6/KB3), nie versteckte oder kaputte Dateien, keine
  X11-Sitzungen. GNOME braucht GDM für die Bildschirmsperre und ist
  deshalb nicht freigegeben.
- Vorwahl „Querencia Desktop“ (KB3) für Benutzer ohne gültige letzte
  Sitzung in `state.toml` von ReGreet.
- Rückfall `huelle = nein` in `sitzungen.conf`: Sitzungen ohne die
  Variablen starten (Verhalten 0.1.0).

## 0.1.0 – 20.10.2026

- Erste Fassung: greetd-Konfiguration (Konsole 7, Benutzer `_greetd`),
  ReGreet-Konfiguration (Grußtext „Querencia Desktop“, Querencia-Klassisch,
  Symbolthema Querencia, Hintergrund Querencia Blau, Uhr in der
  Systemsprache), labwc ohne Menü, Tasten- und Mausbelegung.
- `anmeldung-starten` übernimmt Sprache (`/etc/default/locale`) und
  Tastaturbelegung (`/etc/default/keyboard`) des Systems.
- Eigener Dienst `querencia-anmeldung.service` (Alias
  `display-manager.service`) und Programm `querencia-anmeldung` (greetd mit
  `/etc/querencia/greetd/config.toml`); die greetd-Konfiguration der
  Distribution bleibt unberührt.
- Löst den von Hand eingerichteten Anmeldebildschirm der Entwicklungs-VM
  ab (Grußtext „Classic2“, ReGreet und labwc unter `/usr/local/bin`).
