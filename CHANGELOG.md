# Änderungen

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
