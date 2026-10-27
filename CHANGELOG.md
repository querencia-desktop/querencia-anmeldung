# Änderungen

## 0.1.4 – 27.10.2026

- Abgelaufenes Passwort (z. B. nach `chage -d 0` oder `passwd -e`): Der
  Anmeldebildschirm sagt jetzt „Ihr Passwort ist abgelaufen. Bitte wählen
  Sie ein neues.“ und darunter, wie es geht: an der Textkonsole anmelden
  (Strg+Alt+F1), dort das neue Passwort festlegen, mit Strg+Alt+F7 zurück.
  Englisch: „Your password has expired. Please choose a new one.“ Die
  Meldung bleibt eine Minute stehen statt fünf Sekunden. Vorher stand dort
  nur „Anmeldung fehlgeschlagen: Pam_acct_mgmt: NEW_AUTHTOK_REQD“ (Befund
  Weg B Alpha 3.3, P-1).
- Ursache, gemessen: greetd 0.10.3 kann kein Passwort ändern (ruft
  `pam_chauthtok` nicht auf). Nach dem richtigen Passwort kommt die
  Meldung von PAM („Passwort sofort ändern“), gleich danach beendet greetd
  die Anmeldung mit `NEW_AUTHTOK_REQD`; diese Zeile überschrieb die
  übersetzte Meldung aus 0.1.3 sofort. Den Wechsel im Anmeldebildschirm
  selbst gibt es deshalb nicht.
- Neue isolierte Passwortprobe `tests/passwort-probe.sh`: echtes greetd
  und echtes PAM mit einem Wegwerf-Benutzer in einem Namensraum
  (falsches, abgelaufenes, gültiges Passwort; Fotos und Mitschnitt des
  greetd-Protokolls). `tests/uebersetzung-pruefen.sh` prüft die neue
  Meldung. Prüfliste Ü8 an das neue Verhalten angepasst.

## 0.1.3 – 26.10.2026

- Durchgehend zweisprachig: bei Deutsch alles deutsch, bei Englisch alles
  englisch, keine Mischung (QD-179).
- Sitzungsnamen in der Systemsprache: `sitzung-starten --pruefen` nimmt
  `Name[de]` usw. wie GLib (`LANGUAGE`, `LC_ALL`, `LC_MESSAGES`, `LANG`),
  `anmeldung-starten` setzt die Systemsprache vor `sitzungen-auswahl`.
  Vorher blieben übersetzte Sitzungen englisch („Test session“ statt
  „Testsitzung“).
- Meldungen von PAM übersetzt (Patch erweitert, `tr_pam`): erst
  `po/de.po`, dann der Katalog `Linux-PAM` des Systems, z. B. „Sie müssen
  Ihr Passwort sofort ändern (von root erzwungen).“ statt der englischen
  Zeile. greetd setzt keine Sprache, deshalb kamen sie bisher englisch.
- `po/de.po`: „One-Time Password:“ (Demo-Modus, Sprachprobe).
- Prüfungen: `tests/uebersetzung-pruefen.sh` meldet sichtbare Texte ohne
  Übersetzung (keine englischen Reste bei Deutsch) und prüft die Liste der
  erwarteten Texte `tests/sprache-texte.txt`; neue isolierte Sprachprobe
  `tests/sprache-probe.sh` (Fotos de und en, ohne Systemänderung);
  `tests/konfig-pruefen.sh` um Sitzungsnamen, Reihenfolge Sprache vor
  Auswahl, `skip_selection` und Uhrformat erweitert. Prüfliste Ü7–Ü9.
- Grenze, dokumentiert: GTK-eigene Texte (Tooltip am Auge, Hinweis
  Feststelltaste, Kontextmenü) brauchen `language-pack-gnome-de-base`;
  ohne bleiben sie englisch.

## 0.1.2 – 22.10.2026

- Anmeldebildschirm in der Systemsprache: Beschriftungen,
  Knöpfe, Tooltips, Passwortabfrage und Fehlermeldungen über gettext,
  deutsche Übersetzung `po/de.po` (Domäne `querencia-anmeldung`).
  Falsches Passwort: „Falsches Passwort. Bitte erneut versuchen.“ statt
  „Login failed: Pam_authenticate: AUTH_ERR“. Dafür ein DEP-3-Patch an
  ReGreet im Packaging (Entscheidung vom 22.10.2026),
  ohne neue Crates.
- Uhr in der Zeitsprache (`LC_TIME`): Format `%x %H:%M`, deutsch
  „22.10.2026 02:54“ wie im Panel. Vorher blieb die Uhr englisch, weil
  ReGreet die Sprache `de-DE` nicht erkannte.
- Info-Zeile: Grußtext mit der Ausgabe aus `/usr/share/querencia/release`
  bzw. `version` („Querencia Desktop Alpha 2.1“); ohne Versionsdatei wie
  bisher „Querencia Desktop“.
- Prüfung `tests/uebersetzung-pruefen.sh` (Texte des Patches gegen den
  Katalog), `tests/konfig-pruefen.sh` um die Info-Zeile erweitert;
  Prüfliste um Abschnitt Ü (Sprache und Info-Zeile).

## 0.1.1 – 20.10.2026

- Sitzungshülle `sitzung-starten <sitzungsdatei>` (KB1): setzt wie GDM
  `XDG_CURRENT_DESKTOP` aus `DesktopNames` (`;` → `:`),
  `XDG_SESSION_DESKTOP` und `DESKTOP_SESSION` aus dem Dateinamen und
  `XDG_SESSION_TYPE=wayland` und führt danach `Exec` aus. Für Querencia
  Desktop dasselbe Ergebnis wie unter GDM (`X-Querencia`, `querencia`).
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
- README: GNOME sperrt nur unter GDM (gnome-shell koppelt die Sperre an
  `org.gnome.DisplayManager`); gilt für jeden anderen Anmeldebildschirm.
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
- Löst den von Hand eingerichteten Anmeldebildschirm der Entwicklungsumgebung
  ab (Grußtext „Classic2“, ReGreet und labwc unter `/usr/local/bin`).
